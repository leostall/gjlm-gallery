import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/obra.dart';

class ServicoPersistenciaLocal {
  ServicoPersistenciaLocal(this._preferencias);

  final SharedPreferences _preferencias;

  String? lerTexto(String chave) => _preferencias.getString(chave);

  bool lerBooleano(String chave, {bool padrao = false}) =>
      _preferencias.getBool(chave) ?? padrao;

  Future<void> salvarTexto(String chave, String valor) async {
    await _preferencias.setString(chave, valor);
  }

  Future<void> salvarBooleano(String chave, bool valor) async {
    await _preferencias.setBool(chave, valor);
  }

  Future<void> remover(String chave) async {
    await _preferencias.remove(chave);
  }

  Future<List<Obra>> carregarObras({
    required String usuarioId,
    required String colecao,
  }) async {
    final conteudo = _preferencias.getString(_chave(usuarioId, colecao));
    if (conteudo == null || conteudo.isEmpty) return [];

    try {
      final lista = jsonDecode(conteudo) as List<dynamic>;
      return lista
          .map((item) => Obra.deMapa(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> salvarObras({
    required String usuarioId,
    required String colecao,
    required Iterable<Obra> obras,
  }) async {
    final conteudo = jsonEncode(
      obras.map((obra) => obra.paraMapa()).toList(),
    );
    await _preferencias.setString(_chave(usuarioId, colecao), conteudo);
  }

  String _chave(String usuarioId, String colecao) =>
      'gjlm_${colecao}_$usuarioId';
}
