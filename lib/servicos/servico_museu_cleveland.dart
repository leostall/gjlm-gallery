import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/obra.dart';
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
  }) async {
    final paginaSegura = pagina < 1 ? 1 : pagina;
    final deslocamento = (paginaSegura - 1) * limite;
    final uri = Uri.https(_host, '$_caminhoBase/', {
      'has_image': '1',
      'skip': '$deslocamento',
      'limit': '$limite',
      'fields': _campos.join(','),
    });

    final resposta = await _cliente.get(uri);
    final json = _decodificarResposta(resposta);
    final dados = json['data'] as List<dynamic>? ?? [];
    final informacoes = Map<String, dynamic>.from(
      json['info'] as Map? ?? <String, dynamic>{},
    );
    final totalObras = (informacoes['total'] as num?)?.toInt() ?? dados.length;
    final totalPaginas = totalObras == 0
        ? 1
        : (totalObras + limite - 1) ~/ limite;

    return ResultadoPaginadoObras(
      obras: dados
          .map((item) => Obra.deJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      paginaAtual: paginaSegura,
      totalPaginas: totalPaginas,
    );
  }

  Future<Obra> buscarDetalhes(int id) async {
    final uri = Uri.https(_host, '$_caminhoBase/$id');
    final resposta = await _cliente.get(uri);
    final json = _decodificarResposta(resposta);
    final dados = json['data'];

    if (dados is! Map) {
      throw const ExcecaoApi('A obra solicitada não foi encontrada.');
    }

    return Obra.deJson(Map<String, dynamic>.from(dados));
  }

  Future<Obra> buscarPrimeiraObra(String termo) async {
    final busca = termo.trim();
    if (busca.isEmpty) {
      throw const ExcecaoApi('Digite o nome de uma obra ou artista.');
    }

    final uri = Uri.https(_host, '$_caminhoBase/', {
      'q': busca,
      'has_image': '1',
      'skip': '0',
      'limit': '1',
      'fields': 'id',
    });
    final resposta = await _cliente.get(uri);
    final json = _decodificarResposta(resposta);
    final dados = json['data'] as List<dynamic>? ?? [];

    if (dados.isEmpty) {
      throw ExcecaoApi('Nenhuma obra encontrada para “$busca”.');
    }

    final primeiro = Map<String, dynamic>.from(dados.first as Map);
    final id = (primeiro['id'] as num).toInt();
    return buscarDetalhes(id);
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
      return Map<String, dynamic>.from(jsonDecode(corpo) as Map);
    } on FormatException {
      throw const ExcecaoApi('A resposta do acervo veio em formato inválido.');
    }
  }

  void fechar() => _cliente.close();
}

class ExcecaoApi implements Exception {
  const ExcecaoApi(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}
