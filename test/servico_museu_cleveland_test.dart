import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gjlm_gallery/servicos/servico_museu_cleveland.dart';

void main() {
  test('lista obras e interpreta a paginação por deslocamento', () async {
    final cliente = MockClient((requisicao) async {
      expect(requisicao.url.path, '/api/artworks/');
      expect(requisicao.url.queryParameters['skip'], '12');
      expect(requisicao.url.queryParameters['limit'], '12');
      expect(requisicao.url.queryParameters['has_image'], '1');

      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'info': {'total': 30},
            'data': [
              {
                'id': 10,
                'title': 'Obra de teste',
                'images': {
                  'web': {'url': 'https://exemplo.com/obra.jpg'},
                },
              },
            ],
          }),
        ),
        200,
      );
    });
    final servico = ServicoMuseuCleveland(cliente: cliente);

    final resultado = await servico.listarObras(pagina: 2);

    expect(resultado.obras.single.id, 10);
    expect(resultado.paginaAtual, 2);
    expect(resultado.totalPaginas, 3);
    expect(resultado.temProximaPagina, isTrue);
  });

  test(
    'busca por título e artista e consulta detalhe pelo ID escolhido',
    () async {
      final cliente = MockClient((requisicao) async {
        if (requisicao.url.path == '/api/artworks/') {
          expect(requisicao.url.queryParameters['title'], 'The Red Kerchief');
          expect(requisicao.url.queryParameters['artists'], 'Claude Monet');
          expect(requisicao.url.queryParameters.containsKey('q'), isFalse);
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 135382, 'title': 'The Red Kerchief'},
              ],
            }),
            200,
          );
        }

        expect(requisicao.url.path, '/api/artworks/135382');
        return http.Response(
          jsonEncode({
            'data': {'id': 135382, 'title': 'The Red Kerchief'},
          }),
          200,
        );
      });
      final servico = ServicoMuseuCleveland(cliente: cliente);

      final resultado = await servico.listarObras(
        pagina: 1,
        termo: 'The Red Kerchief — Claude Monet',
      );
      final obra = await servico.buscarDetalhes(resultado.obras.single.id);

      expect(obra.id, 135382);
      expect(obra.titulo, 'The Red Kerchief');
    },
  );

  test('transforma falha HTTP em mensagem compreensível', () async {
    final cliente = MockClient((_) async => http.Response('erro', 503));
    final servico = ServicoMuseuCleveland(cliente: cliente);

    await expectLater(
      servico.listarObras(pagina: 1),
      throwsA(isA<ExcecaoApi>()),
    );
  });
}
