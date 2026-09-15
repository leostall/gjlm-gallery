import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/obra.dart';
import '../servicos/servico_persistencia_local.dart';
import '../servicos/servico_sincronizacao_nuvem.dart';

class ProvedorColecao extends ChangeNotifier {
  ProvedorColecao(this._persistenciaLocal, this._sincronizacaoNuvem);

  final ServicoPersistenciaLocal _persistenciaLocal;
  final ServicoSincronizacaoNuvem _sincronizacaoNuvem;

  final Map<int, Obra> _favoritos = {};
  final Map<int, Obra> _vistos = {};
  String? _usuarioId;
  bool _carregando = false;
  String? _avisoSincronizacao;
  int _versaoCarregamento = 0;

  List<Obra> get favoritos => List.unmodifiable(_favoritos.values);
  List<Obra> get vistos => List.unmodifiable(_vistos.values);
  bool get carregando => _carregando;
  String? get avisoSincronizacao => _avisoSincronizacao;

  bool ehFavorito(int obraId) => _favoritos.containsKey(obraId);
  bool foiVisto(int obraId) => _vistos.containsKey(obraId);

  void atualizarUsuario(String? usuarioId) {
    if (_usuarioId == usuarioId) return;

    _usuarioId = usuarioId;
    _versaoCarregamento++;
    _favoritos.clear();
    _vistos.clear();
    _avisoSincronizacao = null;
    _carregando = usuarioId != null;

    if (usuarioId == null) {
      Future.microtask(notifyListeners);
      return;
    }

    final versao = _versaoCarregamento;
    unawaited(Future.microtask(() => _carregar(usuarioId, versao)));
  }

  Future<void> alternarFavorito(Obra obra) async {
    await _alternar(obra: obra, colecao: 'favoritos', destino: _favoritos);
  }

  Future<void> alternarVisto(Obra obra) async {
    await _alternar(obra: obra, colecao: 'vistos', destino: _vistos);
  }

  Future<void> _carregar(String usuarioId, int versao) async {
    try {
      final resultadosLocais = await Future.wait([
        _persistenciaLocal.carregarObras(
          usuarioId: usuarioId,
          colecao: 'favoritos',
        ),
        _persistenciaLocal.carregarObras(
          usuarioId: usuarioId,
          colecao: 'vistos',
        ),
      ]);
      if (!_carregamentoAindaValido(usuarioId, versao)) return;

      _substituir(_favoritos, resultadosLocais[0]);
      _substituir(_vistos, resultadosLocais[1]);
      notifyListeners();

      if (!_sincronizacaoNuvem.firebaseAtivo) return;

      final resultadosNuvem = await Future.wait([
        _sincronizarColecao(
          usuarioId: usuarioId,
          nome: 'favoritos',
          obrasLocais: resultadosLocais[0],
        ),
        _sincronizarColecao(
          usuarioId: usuarioId,
          nome: 'vistos',
          obrasLocais: resultadosLocais[1],
        ),
      ]);
      if (!_carregamentoAindaValido(usuarioId, versao)) return;

      _substituir(_favoritos, resultadosNuvem[0]);
      _substituir(_vistos, resultadosNuvem[1]);
      await _salvarLocal(usuarioId);
    } catch (_) {
      _avisoSincronizacao =
          'Os dados locais estão disponíveis, mas a nuvem não sincronizou.';
    } finally {
      if (_carregamentoAindaValido(usuarioId, versao)) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  Future<List<Obra>> _sincronizarColecao({
    required String usuarioId,
    required String nome,
    required List<Obra> obrasLocais,
  }) async {
    final obrasNuvem = await _sincronizacaoNuvem.buscarObras(
      usuarioId: usuarioId,
      colecao: nome,
    );

    if (obrasNuvem.isNotEmpty || obrasLocais.isEmpty) return obrasNuvem;

    await Future.wait(
      obrasLocais.map(
        (obra) => _sincronizacaoNuvem.salvarObra(
          usuarioId: usuarioId,
          colecao: nome,
          obra: obra,
        ),
      ),
    );
    return obrasLocais;
  }

  Future<void> _alternar({
    required Obra obra,
    required String colecao,
    required Map<int, Obra> destino,
  }) async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;

    final estavaSalva = destino.containsKey(obra.id);
    if (estavaSalva) {
      destino.remove(obra.id);
    } else {
      destino[obra.id] = obra;
    }
    _avisoSincronizacao = null;
    notifyListeners();

    await _persistenciaLocal.salvarObras(
      usuarioId: usuarioId,
      colecao: colecao,
      obras: destino.values,
    );

    try {
      if (estavaSalva) {
        await _sincronizacaoNuvem.removerObra(
          usuarioId: usuarioId,
          colecao: colecao,
          obraId: obra.id,
        );
      } else {
        await _sincronizacaoNuvem.salvarObra(
          usuarioId: usuarioId,
          colecao: colecao,
          obra: obra,
        );
      }
    } catch (_) {
      _avisoSincronizacao =
          'Alteração salva no aparelho, mas ainda não sincronizada na nuvem.';
      notifyListeners();
    }
  }

  Future<void> _salvarLocal(String usuarioId) async {
    await Future.wait([
      _persistenciaLocal.salvarObras(
        usuarioId: usuarioId,
        colecao: 'favoritos',
        obras: _favoritos.values,
      ),
      _persistenciaLocal.salvarObras(
        usuarioId: usuarioId,
        colecao: 'vistos',
        obras: _vistos.values,
      ),
    ]);
  }

  bool _carregamentoAindaValido(String usuarioId, int versao) =>
      _usuarioId == usuarioId && _versaoCarregamento == versao;

  void _substituir(Map<int, Obra> destino, Iterable<Obra> obras) {
    destino
      ..clear()
      ..addEntries(obras.map((obra) => MapEntry(obra.id, obra)));
  }
}
