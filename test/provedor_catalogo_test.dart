import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gjlm_gallery/provedores/provedor_catalogo.dart';
import 'package:gjlm_gallery/servicos/servico_museu_cleveland.dart';

void main() {
  test('limpar busca restaura a listagem sem termo', () async {
    final consultas = <Uri>[];
    final provedor = ProvedorCatalogo(
      ServicoMuseuCleveland(
        cliente: MockClient((requisicao) async {
          consultas.add(requisicao.url);
          final termo = requisicao.url.queryParameters['q'];
          return http.Response(
            jsonEncode({
              'info': {'total': 1},
              'data': [
                {
                  'id': termo == null ? 1 : 2,
                  'title': termo == null ? 'Acervo inicial' : 'Resultado',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    addTearDown(provedor.dispose);

    await provedor.carregarInicial();
    await provedor.limparBusca();
    expect(consultas, hasLength(1));

    await provedor.buscar('monet');
    expect(consultas.last.queryParameters['q'], 'monet');

    await provedor.limparBusca();
    expect(provedor.termo, isEmpty);
    expect(consultas.last.queryParameters.containsKey('q'), isFalse);
    expect(provedor.obras.single.titulo, 'Acervo inicial');
  });

  test('busca livre retorna a primeira obra da primeira página', () async {
    final consultas = <Uri>[];
    final provedor = ProvedorCatalogo(
      ServicoMuseuCleveland(
        cliente: MockClient((requisicao) async {
          consultas.add(requisicao.url);
          return http.Response(
            jsonEncode({
              'info': {'total': 24},
              'data': [
                {'id': 7, 'title': 'Primeiro resultado'},
                {'id': 8, 'title': 'Segundo resultado'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    addTearDown(provedor.dispose);

    final encontrada = await provedor.buscar('monet');

    expect(consultas, hasLength(1));
    expect(consultas.single.queryParameters['q'], 'monet');
    expect(consultas.single.queryParameters['skip'], '0');
    expect(encontrada?.id, 7);
    expect(encontrada?.titulo, 'Primeiro resultado');
    expect(provedor.avisoBusca, isNull);
    expect(provedor.buscando, isFalse);
  });

  test('busca por título e artista também retorna a primeira obra', () async {
    late Uri consulta;
    final provedor = ProvedorCatalogo(
      ServicoMuseuCleveland(
        cliente: MockClient((requisicao) async {
          consulta = requisicao.url;
          return http.Response(
            jsonEncode({
              'info': {'total': 2},
              'data': [
                {
                  'id': 10,
                  'title': 'Paisagem',
                  'creators': [
                    {'description': 'Claude Monet'},
                  ],
                },
                {'id': 11, 'title': 'Outra paisagem'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    addTearDown(provedor.dispose);

    final encontrada = await provedor.buscar('Paisagem — Claude Monet');

    expect(consulta.queryParameters['title'], 'Paisagem');
    expect(consulta.queryParameters['artists'], 'Claude Monet');
    expect(encontrada?.id, 10);
  });

  test('busca sem resultados apresenta mensagem amigável', () async {
    final provedor = ProvedorCatalogo(
      ServicoMuseuCleveland(
        cliente: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'info': {'total': 0},
              'data': <Object>[],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    );
    addTearDown(provedor.dispose);

    final encontrada = await provedor.buscar('obra inexistente');

    expect(encontrada, isNull);
    expect(provedor.erro, isNull);
    expect(provedor.avisoBusca, contains('Nenhuma obra'));
  });

  test('busca vazia e falhas apresentam mensagem amigável', () async {
    final provedor = ProvedorCatalogo(
      ServicoMuseuCleveland(
        cliente: MockClient((_) async => http.Response('erro', 503)),
      ),
    );
    addTearDown(provedor.dispose);
    await provedor.buscar(' ');
    expect(provedor.erro, isNull);
    expect(provedor.avisoBusca, contains('Digite'));
    await provedor.carregarInicial();
    expect(provedor.erro, contains('503'));
    expect(provedor.carregandoInicial, isFalse);
  });
}
