import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gjlm_gallery/provedores/provedor_catalogo.dart';
import 'package:gjlm_gallery/servicos/servico_museu_cleveland.dart';

http.Response resposta(int id, String titulo) => http.Response(
  jsonEncode({
    'info': {'total': 1},
    'data': [
      {'id': id, 'title': titulo},
    ],
  }),
  200,
);

void main() {
  test('resposta atrasada não substitui a busca mais recente', () async {
    final antiga = Completer<http.Response>();
    final nova = Completer<http.Response>();
    final provedor = ProvedorCatalogo(
      ServicoMuseuCleveland(
        cliente: MockClient((req) {
          return req.url.queryParameters['q'] == 'mon'
              ? antiga.future
              : nova.future;
        }),
      ),
    );
    addTearDown(provedor.dispose);
    provedor.filtrar('mon');
    await Future<void>.delayed(const Duration(milliseconds: 320));
    provedor.filtrar('monet');
    await Future<void>.delayed(const Duration(milliseconds: 320));
    nova.complete(resposta(2, 'Monet'));
    await Future<void>.delayed(Duration.zero);
    antiga.complete(resposta(1, 'Antiga'));
    await Future<void>.delayed(Duration.zero);
    expect(provedor.obras.single.id, 2);
    expect(provedor.carregandoInicial, isFalse);
  });

  for (final caso in [
    (
      termo: 'Nenúfares',
      titulos: ['Outra obra', 'Nenúfares'],
      total: 2,
      esperado: null,
    ),
    (termo: 'monet', titulos: ['Nenúfares'], total: 1, esperado: null),
    (
      termo: 'monet',
      titulos: ['Nenúfares', 'Paisagem'],
      total: 2,
      esperado: null,
    ),
    (
      termo: 'Nenúfares',
      titulos: ['Nenúfares', 'Nenúfares'],
      total: 2,
      esperado: null,
    ),
    (termo: 'Nenúfares', titulos: ['Nenúfares'], total: 24, esperado: null),
    (termo: 'inexistente', titulos: <String>[], total: 0, esperado: null),
  ]) {
    test(
      'busca identifica obra sem escolher resultado arbitrário: $caso',
      () async {
        final provedor = ProvedorCatalogo(
          ServicoMuseuCleveland(
            cliente: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'info': {'total': caso.total},
                  'data': [
                    for (var i = 0; i < caso.titulos.length; i++)
                      {'id': i + 1, 'title': caso.titulos[i]},
                  ],
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            ),
          ),
        );
        addTearDown(provedor.dispose);
        final encontrada = await provedor.buscar(caso.termo);
        expect(encontrada?.id, caso.esperado);
        expect(provedor.buscando, isFalse);
        if (caso.titulos.isEmpty) {
          expect(provedor.erro, isNull);
          expect(provedor.avisoBusca, contains('Nenhuma obra'));
        } else if (caso.esperado == null) {
          expect(provedor.avisoBusca, contains('Selecione'));
        }
      },
    );
  }

  for (final caso in [
    (
      termo: 'Paisagem — Claude Monet',
      titulos: ['Paisagem', 'Paisagem'],
      artistas: ['Outro Artista', 'Claude Monet'],
      esperado: 2,
    ),
    (
      termo: 'Paisagem — Claude Monet',
      titulos: ['Paisagem', 'Paisagem'],
      artistas: ['Claude Monet', 'Claude Monet'],
      esperado: null,
    ),
    (
      termo: 'Paisagem — Claude Monet',
      titulos: ['Paisagem com flores'],
      artistas: ['Claude Monet'],
      esperado: null,
    ),
    (
      termo: 'Paisagem — Monet',
      titulos: ['Paisagem'],
      artistas: ['Claude Monet'],
      esperado: null,
    ),
    (
      termo: '  paisagem - CLAUDE   MONET  ',
      titulos: ['Paisagem'],
      artistas: ['Claude Monet'],
      esperado: 1,
    ),
    (
      termo: 'Paisagem | Claude Monet',
      titulos: ['Paisagem'],
      artistas: ['Claude Monet'],
      esperado: 1,
    ),
    (
      termo: 'Paisagem — Artista não informado',
      titulos: ['Paisagem'],
      artistas: [''],
      esperado: null,
    ),
    (
      termo: 'Paisagem — Claude Monet',
      titulos: ['Paisagem'],
      artistas: ['Outro Artista'],
      esperado: null,
    ),
  ]) {
    test(
      'exatidão exige título e artista completos e uma única obra: $caso',
      () async {
        final provedor = ProvedorCatalogo(
          ServicoMuseuCleveland(
            cliente: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'info': {'total': caso.titulos.length},
                  'data': [
                    for (var i = 0; i < caso.titulos.length; i++)
                      {
                        'id': i + 1,
                        'title': caso.titulos[i],
                        'creators': [
                          {'description': caso.artistas[i]},
                        ],
                      },
                  ],
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            ),
          ),
        );
        addTearDown(provedor.dispose);
        final encontrada = await provedor.buscar(caso.termo);
        expect(encontrada?.id, caso.esperado);
        expect(provedor.buscando, isFalse);
        expect(provedor.erro, isNull);
        if (caso.esperado == null) {
          expect(provedor.avisoBusca, contains('Selecione'));
        }
      },
    );
  }

  for (final cenario in [
    'única na primeira página',
    'duplicada na segunda página',
    'única na segunda página',
  ]) {
    test('busca exata verifica todas as páginas: $cenario', () async {
      final paginas = <String>[];
      final provedor = ProvedorCatalogo(
        ServicoMuseuCleveland(
          cliente: MockClient((req) async {
            paginas.add(req.url.queryParameters['skip']!);
            expect(req.url.queryParameters['title'], 'Paisagem');
            expect(req.url.queryParameters['artists'], 'Claude Monet');
            final primeira = req.url.queryParameters['skip'] == '0';
            return http.Response(
              jsonEncode({
                'info': {'total': 13},
                'data': [
                  for (
                    var id = primeira ? 1 : 13;
                    id <= (primeira ? 12 : 13);
                    id++
                  )
                    {
                      'id': id,
                      'title':
                          (id == 1 && cenario != 'única na segunda página') ||
                              (id == 13 &&
                                  cenario != 'única na primeira página')
                          ? 'Paisagem'
                          : 'Paisagem, estudo $id',
                      'creators': [
                        {'description': 'Claude Monet'},
                      ],
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
      final encontrada = await provedor.buscar('Paisagem — Claude Monet');
      expect(paginas, ['0', '12']);
      expect(
        encontrada?.id,
        cenario == 'única na primeira página'
            ? 1
            : cenario == 'única na segunda página'
            ? 13
            : null,
      );
      expect(provedor.obras.length, 13);
      if (cenario == 'duplicada na segunda página') {
        expect(provedor.avisoBusca, contains('mais de uma obra'));
      }
    });
  }

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
