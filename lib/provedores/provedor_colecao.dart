import 'dart:async';
import 'dart:convert';

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
  int _versaoAlteracoes = 0;
  bool _descartado = false;
  Future<void> _leituraLocal = Future.value();
  Future<void> _fila = Future.value();

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
      Future.microtask(() {
        if (!_descartado) notifyListeners();
      });
      return;
    }

    final versao = _versaoCarregamento;
    final pronto = Completer<void>();
    _leituraLocal = pronto.future;
    unawaited(Future.microtask(() => _carregar(usuarioId, versao, pronto)));
  }

  Future<void> alternarFavorito(Obra obra) async {
    await _alternar(obra: obra, colecao: 'favoritos', destino: _favoritos);
  }

  Future<void> alternarVisto(Obra obra) async {
    await _alternar(obra: obra, colecao: 'vistos', destino: _vistos);
  }

  Future<void> _carregar(
    String usuarioId,
    int versao,
    Completer<void> pronto,
  ) async {
    final alteracoes = _versaoAlteracoes;
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
      pronto.complete();
      notifyListeners();

      if (!_sincronizacaoNuvem.firebaseAtivo) return;

      final resultadosNuvem = await Future.wait([
        _sincronizarColecao(usuarioId: usuarioId, nome: 'favoritos'),
        _sincronizarColecao(usuarioId: usuarioId, nome: 'vistos'),
      ]);
      if (!_carregamentoAindaValido(usuarioId, versao) ||
          alteracoes != _versaoAlteracoes) {
        return;
      }

      _substituir(_favoritos, resultadosNuvem[0]);
      _substituir(_vistos, resultadosNuvem[1]);
      await _salvarLocal(usuarioId);
    } catch (_) {
      if (_carregamentoAindaValido(usuarioId, versao)) {
        _avisoSincronizacao =
            'Os dados locais estão disponíveis, mas a nuvem não sincronizou.';
      }
    } finally {
      if (!pronto.isCompleted) pronto.complete();
      if (_carregamentoAindaValido(usuarioId, versao)) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  Future<List<Obra>> _sincronizarColecao({
    required String usuarioId,
    required String nome,
  }) async {
    // Reenvia inclusões e remoções pendentes antes de ler a coleção remota.
    await _enviarPendencias(usuarioId, nome);
    return _sincronizacaoNuvem.buscarObras(usuarioId: usuarioId, colecao: nome);
  }

  Future<void> _alternar({
    required Obra obra,
    required String colecao,
    required Map<int, Obra> destino,
  }) async {
    final usuarioId = _usuarioId;
    final versao = _versaoCarregamento;
    if (usuarioId == null) return;
    await _leituraLocal;
    if (!_carregamentoAindaValido(usuarioId, versao)) return;
    _versaoAlteracoes++;
    final estavaSalva = destino.containsKey(obra.id);
    if (estavaSalva) {
      destino.remove(obra.id);
    } else {
      destino[obra.id] = obra;
    }
    final obras = destino.values.toList();
    _avisoSincronizacao = null;
    notifyListeners();
    await _enfileirar(() async {
      try {
        await _persistenciaLocal.salvarObras(
          usuarioId: usuarioId,
          colecao: colecao,
          obras: obras,
        );
        if (_sincronizacaoNuvem.firebaseAtivo) {
          final pendentes = _lerPendencias(usuarioId, colecao);
          pendentes['${obra.id}'] = estavaSalva ? null : obra.paraMapa();
          await _persistenciaLocal.salvarTexto(
            _chavePendencias(usuarioId, colecao),
            jsonEncode(pendentes),
          );
        }
      } catch (_) {
        if (_carregamentoAindaValido(usuarioId, versao)) {
          _avisoSincronizacao =
              'Não foi possível salvar a alteração no aparelho. Tente novamente.';
          notifyListeners();
        }
      }
    });
    // A rede não bloqueia os próximos toques nem o salvamento local.
    unawaited(_sincronizarPendencias(usuarioId, colecao, versao));
  }

  Future<void> _sincronizarPendencias(
    String usuarioId,
    String colecao,
    int versao,
  ) async {
    if (!_sincronizacaoNuvem.firebaseAtivo) return;
    try {
      await _enviarPendencias(usuarioId, colecao);
    } catch (_) {
      if (_carregamentoAindaValido(usuarioId, versao)) {
        _avisoSincronizacao =
            'Alteração salva no aparelho. A sincronização será tentada novamente ao entrar na conta.';
        notifyListeners();
      }
    }
  }

  // Uma fila por coleção mantém a ordem de toques rápidos também na nuvem.
  final Map<String, Future<void>> _filasNuvem = {};
  Future<void> _enviarPendencias(String usuarioId, String colecao) {
    final chave = _chavePendencias(usuarioId, colecao);
    final anterior = _filasNuvem[chave] ?? Future.value();
    final envio = anterior.then((_) async {
      final pendentes = _lerPendencias(usuarioId, colecao);
      for (final item in pendentes.entries) {
        if (item.value == null) {
          await _sincronizacaoNuvem.removerObra(
            usuarioId: usuarioId,
            colecao: colecao,
            obraId: int.parse(item.key),
          );
        } else {
          await _sincronizacaoNuvem.salvarObra(
            usuarioId: usuarioId,
            colecao: colecao,
            obra: Obra.deMapa(Map<String, dynamic>.from(item.value as Map)),
          );
        }
        // Não apaga uma alteração mais recente feita durante a requisição.
        await _enfileirar(() async {
          final atuais = _lerPendencias(usuarioId, colecao);
          if (atuais.containsKey(item.key) &&
              jsonEncode(atuais[item.key]) == jsonEncode(item.value)) {
            atuais.remove(item.key);
            await _persistenciaLocal.salvarTexto(chave, jsonEncode(atuais));
          }
        });
      }
    });
    _filasNuvem[chave] = envio.catchError((Object _) {});
    return envio;
  }

  String _chavePendencias(String usuarioId, String colecao) =>
      'gjlm_pendentes_${usuarioId}_$colecao';
  Map<String, dynamic> _lerPendencias(String usuarioId, String colecao) {
    final texto = _persistenciaLocal.lerTexto(
      _chavePendencias(usuarioId, colecao),
    );
    return texto == null
        ? {}
        : Map<String, dynamic>.from(jsonDecode(texto) as Map);
  }

  Future<void> _enfileirar(Future<void> Function() acao) {
    final operacao = _fila.then((_) => acao());
    _fila = operacao.catchError((Object _) {});
    return operacao;
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
      !_descartado && _usuarioId == usuarioId && _versaoCarregamento == versao;

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  void _substituir(Map<int, Obra> destino, Iterable<Obra> obras) {
    destino
      ..clear()
      ..addEntries(obras.map((obra) => MapEntry(obra.id, obra)));
  }
}
