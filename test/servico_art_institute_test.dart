import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gjlm_gallery/servicos/servico_art_institute.dart';

void main() {
  test('lista obras e interpreta a paginação', () async {
    final cliente = MockClient((requisicao) async {
      expect(requisicao.url.path, '/api/v1/artworks');
      expect(requisicao.url.queryParameters['page'], '1');

      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'pagination': {'current_page': 1, 'total_pages': 3},
          'data': [
            {'id': 10, 'title': 'Obra de teste'},
          ],
        })),
        200,
      );
    });
    final servico = ServicoArtInstitute(cliente: cliente);

    final resultado = await servico.listarObras(pagina: 1);

    expect(resultado.obras.single.id, 10);
    expect(resultado.temProximaPagina, isTrue);
  });

  test('transforma falha HTTP em mensagem compreensível', () async {
    final cliente = MockClient((_) async => http.Response('erro', 503));
    final servico = ServicoArtInstitute(cliente: cliente);

    await expectLater(
      servico.listarObras(pagina: 1),
      throwsA(isA<ExcecaoApi>()),
    );
  });
}
