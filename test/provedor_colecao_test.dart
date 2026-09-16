import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gjlm_gallery/modelos/obra.dart';
import 'package:gjlm_gallery/provedores/provedor_colecao.dart';
import 'package:gjlm_gallery/servicos/servico_persistencia_local.dart';
import 'package:gjlm_gallery/servicos/servico_sincronizacao_nuvem.dart';

const obra = Obra(id: 7, titulo: 'Obra persistida');
Future<void> estabilizar() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

class NuvemTeste extends ServicoSincronizacaoNuvem {
  NuvemTeste() : super(firebaseAtivo: true);
  final dados = <String, Map<int, Obra>>{};
  bool offline = false;
  Completer<void>? leituraPendente;
  Map<int, Obra> colecao(String usuario, String nome) =>
      dados.putIfAbsent('$usuario/$nome', () => {});
  @override
  Future<List<Obra>> buscarObras({
    required String usuarioId,
    required String colecao,
  }) async {
    final resultado = this.colecao(usuarioId, colecao).values.toList();
    await leituraPendente?.future;
    return resultado;
  }

  @override
  Future<void> salvarObra({
    required String usuarioId,
    required String colecao,
    required Obra obra,
  }) async {
    if (offline) throw Exception('Sem rede');
    this.colecao(usuarioId, colecao)[obra.id] = obra;
  }

  @override
  Future<void> removerObra({
    required String usuarioId,
    required String colecao,
    required int obraId,
  }) async {
    if (offline) throw Exception('Sem rede');
    this.colecao(usuarioId, colecao).remove(obraId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ServicoPersistenciaLocal local;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = ServicoPersistenciaLocal(await SharedPreferences.getInstance());
  });

  test('favoritos e vistas persistem após recriar provedor e ficam isolados por usuário', () async {
    const nuvem = ServicoSincronizacaoNuvem(firebaseAtivo: false);
    final primeiro = ProvedorColecao(local, nuvem)
      ..atualizarUsuario('usuario-1');
    addTearDown(primeiro.dispose);
    await primeiro.alternarFavorito(obra);
    await primeiro.alternarVisto(obra);
    final segundo = ProvedorColecao(local, nuvem)
      ..atualizarUsuario('usuario-1');
    addTearDown(segundo.dispose);
    await estabilizar();
    expect(segundo.ehFavorito(7), isTrue);
    expect(segundo.foiVisto(7), isTrue);
    segundo.atualizarUsuario('usuario-2');
    await estabilizar();
    expect(segundo.favoritos, isEmpty);
    expect(segundo.vistos, isEmpty);
  });

  test('toques rápidos preservam último estado em disco e nuvem', () async {
    final nuvem = NuvemTeste();
    final provedor = ProvedorColecao(local, nuvem)..atualizarUsuario('usuario');
    addTearDown(provedor.dispose);
    await estabilizar();
    await Future.wait(List.generate(4, (_) => provedor.alternarFavorito(obra)));
    await estabilizar();
    expect(provedor.ehFavorito(7), isFalse);
    expect(
      await local.carregarObras(usuarioId: 'usuario', colecao: 'favoritos'),
      isEmpty,
    );
    expect(nuvem.colecao('usuario', 'favoritos'), isEmpty);
  });

  test('leitura atrasada da nuvem não desfaz um toque no favorito', () async {
    final nuvem = NuvemTeste()..leituraPendente = Completer<void>();
    final provedor = ProvedorColecao(local, nuvem)..atualizarUsuario('usuario');
    addTearDown(provedor.dispose);
    await estabilizar();
    await provedor.alternarFavorito(obra);
    nuvem.leituraPendente!.complete();
    await estabilizar();
    expect(provedor.ehFavorito(7), isTrue);
    expect(
      (await local.carregarObras(
        usuarioId: 'usuario',
        colecao: 'favoritos',
      )).single.id,
      7,
    );
  });

  test(
    'remoção offline é reenviada no reinício e não ressuscita favorito',
    () async {
      final nuvem = NuvemTeste();
      nuvem.colecao('usuario', 'favoritos')[7] = obra;
      final primeiro = ProvedorColecao(local, nuvem)
        ..atualizarUsuario('usuario');
      addTearDown(primeiro.dispose);
      await estabilizar();
      nuvem.offline = true;
      await primeiro.alternarFavorito(obra);
      await estabilizar();
      expect(primeiro.avisoSincronizacao, isNotNull);
      nuvem.offline = false;
      final segundo = ProvedorColecao(local, nuvem)
        ..atualizarUsuario('usuario');
      addTearDown(segundo.dispose);
      await estabilizar();
      expect(segundo.ehFavorito(7), isFalse);
      expect(nuvem.colecao('usuario', 'favoritos'), isEmpty);
    },
  );
}
