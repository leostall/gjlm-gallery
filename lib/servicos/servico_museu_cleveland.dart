import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/obra.dart';
import '../modelos/consulta_obras.dart';
import '../modelos/resultado_paginado_obras.dart';

class ServicoMuseuCleveland {
  ServicoMuseuCleveland({http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  static const _host = 'openaccess-api.clevelandart.org';
  static const _caminhoBase = '/api/artworks';
  static const _campos = [
    'id',
    'title',
    'creation_date',
    'creators',
    'culture',
    'technique',
    'type',
    'measurements',
    'description',
    'images',
  ];

  Future<ResultadoPaginadoObras> listarObras({
    required int pagina,
    int limite = 12,
    String termo = '',
  }) async {
    final paginaSegura = pagina < 1 ? 1 : pagina;
    final deslocamento = (paginaSegura - 1) * limite;
    final uri = Uri.https(_host, '$_caminhoBase/', {
      'has_image': '1',
      'skip': '$deslocamento',
      ...ConsultaObras(termo).parametros,
      'limit': '$limite',
      'fields': _campos.join(','),
    });

    final resposta = await _cliente
        .get(uri)
        .timeout(const Duration(seconds: 20));
    final json = _decodificarResposta(resposta);
    final dados = _listaDeMapas(json['data']);
    final informacoes = Map<String, dynamic>.from(
      json['info'] as Map? ?? <String, dynamic>{},
    );
    final totalObras = (informacoes['total'] as num?)?.toInt() ?? dados.length;
    final totalPaginas = totalObras == 0
        ? 1
        : (totalObras + limite - 1) ~/ limite;

    return ResultadoPaginadoObras(
      obras: dados.map(Obra.deJson).toList(),
      paginaAtual: paginaSegura,
      totalPaginas: totalPaginas,
    );
  }

  Future<Obra> buscarDetalhes(int id) async {
    final uri = Uri.https(_host, '$_caminhoBase/$id');
    final resposta = await _cliente
        .get(uri)
        .timeout(const Duration(seconds: 20));
    final json = _decodificarResposta(resposta);
    final dados = json['data'];

    if (dados is! Map) {
      throw const ExcecaoApi('A obra solicitada não foi encontrada.');
    }

    return Obra.deJson(Map<String, dynamic>.from(dados));
  }

  Map<String, dynamic> _decodificarResposta(http.Response resposta) {
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ExcecaoApi(
        'Não foi possível acessar o acervo agora '
        '(erro ${resposta.statusCode}).',
      );
    }

    try {
      final corpo = utf8.decode(resposta.bodyBytes);
      final decodificado = jsonDecode(corpo);
      if (decodificado is! Map) {
        throw const FormatException();
      }
      return Map<String, dynamic>.from(decodificado);
    } on FormatException {
      throw const ExcecaoApi('A resposta do acervo veio em formato inválido.');
    }
  }

  List<Map<String, dynamic>> _listaDeMapas(Object? valor) {
    if (valor is! List) {
      throw const ExcecaoApi(
        'A resposta do acervo não trouxe uma lista de obras.',
      );
    }
    return valor
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void fechar() => _cliente.close();
}

class ExcecaoApi implements Exception {
  const ExcecaoApi(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
