import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/obra.dart';

class ServicoSincronizacaoNuvem {
  const ServicoSincronizacaoNuvem({required this.firebaseAtivo});

  final bool firebaseAtivo;

  Future<List<Obra>> buscarObras({
    required String usuarioId,
    required String colecao,
  }) async {
    if (!firebaseAtivo) return [];

    final consulta = await _referencia(usuarioId, colecao)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 12));
    return consulta.docs
        .map((documento) => Obra.deMapa(documento.data()))
        .toList();
  }

  Future<void> salvarObra({
    required String usuarioId,
    required String colecao,
    required Obra obra,
  }) async {
    if (!firebaseAtivo) return;

    await _referencia(usuarioId, colecao)
        .doc('${obra.id}')
        .set({...obra.paraMapa(), 'atualizadoEm': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 12));
  }

  Future<void> removerObra({
    required String usuarioId,
    required String colecao,
    required int obraId,
  }) async {
    if (!firebaseAtivo) return;
    await _referencia(
      usuarioId,
      colecao,
    ).doc('$obraId').delete().timeout(const Duration(seconds: 12));
  }

  CollectionReference<Map<String, dynamic>> _referencia(
    String usuarioId,
    String colecao,
  ) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuarioId)
        .collection(colecao);
  }
}
