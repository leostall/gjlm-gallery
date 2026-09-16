import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gjlm_gallery/configuracoes/tema_aplicativo.dart';
import 'package:gjlm_gallery/aplicativo.dart';
import 'package:gjlm_gallery/modelos/obra.dart';
import 'package:gjlm_gallery/provedores/provedor_autenticacao.dart';
import 'package:gjlm_gallery/provedores/provedor_catalogo.dart';
import 'package:gjlm_gallery/provedores/provedor_colecao.dart';
import 'package:gjlm_gallery/servicos/servico_autenticacao.dart';
import 'package:gjlm_gallery/servicos/servico_museu_cleveland.dart';
import 'package:gjlm_gallery/servicos/servico_persistencia_local.dart';
import 'package:gjlm_gallery/servicos/servico_sincronizacao_nuvem.dart';
import 'package:gjlm_gallery/telas/tela_autenticacao.dart';
import 'package:gjlm_gallery/telas/tela_catalogo.dart';
import 'package:gjlm_gallery/telas/tela_colecao.dart';
import 'package:gjlm_gallery/telas/tela_detalhes_obra.dart';
import 'package:gjlm_gallery/telas/tela_principal.dart';
import 'package:gjlm_gallery/widgets/cartao_obra.dart';
import 'package:gjlm_gallery/widgets/grade_obras.dart';

Future<void> estabilizar(WidgetTester tester) async {
  // SharedPreferences e clientes criados no setUp completam no executor real.
  await tester.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}

const obra = Obra(id: 1, titulo: 'Nenúfares', nomeArtista: 'Claude Monet');

void main() {
  late ProvedorColecao colecao;
  late ProvedorCatalogo catalogo;
  late ProvedorAutenticacao autenticacao;
  late List<Uri> consultas;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final local = ServicoPersistenciaLocal(
      await SharedPreferences.getInstance(),
    );
    colecao = ProvedorColecao(
      local,
      const ServicoSincronizacaoNuvem(firebaseAtivo: false),
    );
    colecao.atualizarUsuario('teste');
    while (colecao.carregando) {
      await Future<void>.value();
    }
    autenticacao = ProvedorAutenticacao(
      ServicoAutenticacao(local, firebaseAtivo: false),
    );
    consultas = [];
    catalogo = ProvedorCatalogo(
      ServicoMuseuCleveland(
        cliente: MockClient((req) async {
          consultas.add(req.url);
          final dados = {
            'id': 1,
            'title': 'Nenúfares',
            'creators': [
              {'description': 'Claude Monet'},
            ],
            'description': 'Pintura de flores',
            'type': 'Pintura',
          };
          if (req.url.path.endsWith('/1')) {
            return http.Response(
              jsonEncode({'data': dados}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          final termo =
              req.url.queryParameters['q'] ??
              req.url.queryParameters['title'] ??
              '';
          return http.Response(
            jsonEncode({
              'info': {'total': termo.toLowerCase() == 'nenúfares' ? 1 : 24},
              'data': [
                if (termo.isEmpty ||
                    termo.toLowerCase().contains('monet') ||
                    termo.toLowerCase() == 'nenúfares')
                  dados,
                if (termo.isEmpty) {'id': 2, 'title': 'Outra obra'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
  });

  tearDown(() {
    colecao.dispose();
    catalogo.dispose();
    autenticacao.dispose();
  });

  Widget app(Widget tela, {double escala = 1}) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: colecao),
      ChangeNotifierProvider.value(value: catalogo),
      ChangeNotifierProvider.value(value: autenticacao),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: TemaAplicativo.claro,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: tela,
    ),
  );

  testWidgets(
    'coração aceita toque nas bordas sem abrir detalhes e anuncia estado',
    (tester) async {
      final semantics = tester.ensureSemantics();

      var navegacoes = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SizedBox(
              width: 240,
              height: 350,
              child: CartaoObra(obra: obra, aoTocar: () => navegacoes++),
            ),
          ),
        ),
      );
      final botao = find.byKey(const ValueKey('favorito-1'));
      final retangulo = tester.getRect(botao);
      expect(retangulo.width, 56);
      expect(retangulo.height, 56);
      await tester.tapAt(retangulo.topLeft + const Offset(5, 5));
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      await estabilizar(tester);
      expect(colecao.ehFavorito(1), isTrue);
      expect(navegacoes, 0);
      final no = tester.getSemantics(
        find.bySemanticsLabel('Remover Nenúfares dos favoritos'),
      );
      expect(no.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(no.getSemanticsData().flagsCollection.isToggled, Tristate.isTrue);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tapAt(retangulo.bottomRight - const Offset(5, 5));
      await estabilizar(tester);
      expect(colecao.ehFavorito(1), isFalse);
      await tester.tap(find.text('Nenúfares'));
      expect(navegacoes, 1);
      semantics.dispose();
    },
  );

  testWidgets('favoritos atualizam automaticamente ao remover pelo coração', (
    tester,
  ) async {
    await tester.runAsync(() => colecao.alternarFavorito(obra));
    await tester.pumpWidget(
      app(const Scaffold(body: TelaColecao(tipo: TipoColecao.favoritos))),
    );
    await tester.tap(find.byKey(const ValueKey('favorito-1')));
    await estabilizar(tester);
    expect(find.text('Nenhum favorito ainda'), findsOneWidget);
  });

  testWidgets('digitar filtra e Buscar abre diretamente o detalhe (RF08)', (
    tester,
  ) async {
    await tester.pumpWidget(app(const Scaffold(body: TelaCatalogo())));
    await estabilizar(tester);
    expect(find.text('Outra obra'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'monet');
    await tester.pump();
    expect(find.text('Outra obra'), findsNothing);
    await tester.pump(const Duration(milliseconds: 350));
    await estabilizar(tester);
    expect(consultas.last.queryParameters['q'], 'monet');
    expect(find.byType(TelaDetalhesObra), findsNothing);
    await tester.tap(find.text('Buscar'));
    await estabilizar(tester);
    expect(find.byType(TelaDetalhesObra), findsNothing);
    expect(catalogo.avisoBusca, contains('várias obras'));
    await tester.enterText(find.byType(TextField), 'Nenúfares');
    await tester.tap(find.text('Buscar'));
    await estabilizar(tester);
    expect(find.byType(TelaDetalhesObra), findsNothing);
    await tester.enterText(find.byType(TextField), 'Nenúfares — Claude Monet');
    await tester.tap(find.text('Buscar'));
    await estabilizar(tester);
    expect(catalogo.erro, isNull, reason: consultas.toString());
    expect(catalogo.buscando, isFalse);
    expect(find.byType(TelaDetalhesObra), findsOneWidget);
    expect(find.text('Nenúfares'), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expect(consultas.last.path, endsWith('/1'));
    expect(
      consultas[consultas.length - 2].queryParameters['title'],
      'Nenúfares',
    );
    expect(
      consultas[consultas.length - 2].queryParameters['artists'],
      'Claude Monet',
    );
    await tester.tap(find.byTooltip('Voltar'));
    await estabilizar(tester);
    await tester.enterText(find.byType(TextField), 'obra inexistente');
    await tester.tap(find.text('Buscar'));
    await estabilizar(tester);
    expect(find.text('Nenhuma obra encontrada'), findsOneWidget);
    expect(find.text('Acervo indisponível'), findsNothing);
    expect(find.byType(TelaDetalhesObra), findsNothing);
  });

  testWidgets(
    'limpar busca restaura catálogo e botão Carregar mais é ElevatedButton',
    (tester) async {
      await tester.pumpWidget(app(const Scaffold(body: TelaCatalogo())));
      await estabilizar(tester);
      await tester.enterText(find.byType(TextField), 'monet');
      await tester.pump(const Duration(milliseconds: 350));
      await estabilizar(tester);
      await tester.tap(find.byTooltip('Limpar busca'));
      await tester.pump(const Duration(milliseconds: 350));
      await estabilizar(tester);
      expect(find.text('Outra obra'), findsOneWidget);
      final botao = find.widgetWithText(ElevatedButton, 'Carregar mais');
      expect(botao, findsOneWidget);
      await tester.tap(botao);
      await estabilizar(tester);
      expect(consultas.last.queryParameters['skip'], '12');
      expect(find.text('Nenúfares'), findsOneWidget);
    },
  );

  testWidgets(
    'leitor de tela consegue acionar favorito e ler os controles principais',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(const TelaPrincipal()));
      await estabilizar(tester);
      final no = tester.getSemantics(
        find.bySemanticsLabel('Adicionar Nenúfares aos favoritos'),
      );
      tester.binding.rootPipelineOwner.visitChildren((owner) {
        owner.semanticsOwner?.performAction(no.id, SemanticsAction.tap);
      });
      await estabilizar(tester);
      expect(colecao.ehFavorito(1), isTrue);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.pumpWidget(
        app(const TelaAutenticacao(firebaseAtivo: false)),
      );
      await estabilizar(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    },
  );

  testWidgets(
    'aplicativo usa traduções brasileiras inclusive no botão Voltar',
    (tester) async {
      await autenticacao.inicializar();
      await tester.pumpWidget(
        app(const AplicativoGaleria(firebaseAtivo: false)),
      );
      await estabilizar(tester);
      final contexto = tester.element(find.byType(PortalAutenticacao));
      expect(Localizations.localeOf(contexto), const Locale('pt', 'BR'));
      expect(MaterialLocalizations.of(contexto).backButtonTooltip, 'Voltar');
      expect(
        MaterialLocalizations.of(contexto).tabLabel(tabIndex: 1, tabCount: 3),
        'Guia 1 de 3',
      );
      Navigator.of(contexto).push(
        MaterialPageRoute<void>(
          builder: (_) => const TelaDetalhesObra(obraInicial: obra),
        ),
      );
      await estabilizar(tester);
      expect(find.byTooltip('Voltar'), findsOneWidget);
    },
  );

  testWidgets(
    'cartão é um único botão com título e artista e favorito independente',
    (tester) async {
      final handle = tester.ensureSemantics();
      var abriu = false;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SizedBox(
              width: 240,
              height: 350,
              child: CartaoObra(obra: obra, aoTocar: () => abriu = true),
            ),
          ),
        ),
      );
      await estabilizar(tester);
      final no = tester.getSemantics(
        find.bySemanticsLabel('Nenúfares, de Claude Monet'),
      );
      final dados = no.getSemanticsData();
      expect(dados.flagsCollection.isButton, isTrue);
      expect(dados.flagsCollection.isImage, isFalse);
      expect(dados.hint, 'Abrir detalhes da obra');
      var filhos = 0;
      no.visitChildren((_) {
        filhos++;
        return true;
      });
      expect(filhos, 0, reason: 'Imagem e textos não devem repetir o cartão');
      tester.binding.rootPipelineOwner.visitChildren((owner) {
        owner.semanticsOwner?.performAction(no.id, SemanticsAction.tap);
      });
      expect(abriu, isTrue);
      expect(colecao.ehFavorito(obra.id), isFalse);
      expect(
        find.bySemanticsLabel('Adicionar Nenúfares aos favoritos'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets('leitor abre os detalhes pelo cartão e retorna por Voltar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(const TelaPrincipal()));
    await estabilizar(tester);
    final cartao = tester.getSemantics(
      find.bySemanticsLabel('Nenúfares, de Claude Monet'),
    );
    tester.binding.rootPipelineOwner.visitChildren((owner) {
      owner.semanticsOwner?.performAction(cartao.id, SemanticsAction.tap);
    });
    await estabilizar(tester);
    expect(find.byType(TelaDetalhesObra), findsOneWidget);
    expect(find.text('Detalhes da obra'), findsOneWidget);
    expect(consultas.last.path, endsWith('/1'));
    expect(colecao.ehFavorito(obra.id), isFalse);
    final voltar = tester.getSemantics(find.byTooltip('Voltar'));
    expect(voltar.getSemanticsData().flagsCollection.isButton, isTrue);
    tester.binding.rootPipelineOwner.visitChildren((owner) {
      owner.semanticsOwner?.performAction(voltar.id, SemanticsAction.tap);
    });
    await estabilizar(tester);
    expect(find.byType(TelaDetalhesObra), findsNothing);
    expect(find.bySemanticsLabel('Nenúfares, de Claude Monet'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'abas anunciam posição e seleção e funcionam pela ação semântica',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(const TelaPrincipal()));
      await estabilizar(tester);
      var no = tester.getSemantics(find.bySemanticsLabel('Catálogo'));
      expect(no.getSemanticsData().value, 'Aba 1 de 3');
      expect(no.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
      no = tester.getSemantics(find.bySemanticsLabel('Favoritos'));
      tester.binding.rootPipelineOwner.visitChildren((owner) {
        owner.semanticsOwner?.performAction(no.id, SemanticsAction.tap);
      });
      await estabilizar(tester);
      expect(find.text('Nenhum favorito ainda'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Favoritos'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    },
  );

  testWidgets('campos mantêm nome e papel de edição e senha muda de estado', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(const TelaAutenticacao(firebaseAtivo: true)));
    await estabilizar(tester);
    for (final rotulo in ['E-mail', 'Senha']) {
      final dados = tester
          .getSemantics(find.bySemanticsLabel(rotulo))
          .getSemanticsData();
      expect(dados.flagsCollection.isTextField, isTrue);
    }
    await tester.tap(find.byTooltip('Mostrar senha'));
    await estabilizar(tester);
    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Senha'))
          .getSemanticsData()
          .flagsCollection
          .isObscured,
      isFalse,
    );
    handle.dispose();
  });

  testWidgets(
    'detalhes anunciam imagem ausente e permitem marcar vista pelo leitor',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(const TelaDetalhesObra(obraInicial: obra)));
      await estabilizar(tester);
      expect(
        find.bySemanticsLabel(
          'Imagem indisponível para Nenúfares, de Claude Monet',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Marcar vista'));
      await estabilizar(tester);
      final no = tester.getSemantics(
        find.bySemanticsLabel('Marcar Nenúfares como vista'),
      );
      expect(no.getSemanticsData().flagsCollection.isButton, isTrue);
      tester.binding.rootPipelineOwner.visitChildren((owner) {
        owner.semanticsOwner?.performAction(no.id, SemanticsAction.tap);
      });
      await estabilizar(tester);
      expect(colecao.foiVisto(obra.id), isTrue);
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel('Marcar Nenúfares como não vista'),
            )
            .getSemanticsData()
            .flagsCollection
            .isToggled,
        Tristate.isTrue,
      );
      handle.dispose();
    },
  );

  testWidgets('cadastro, teclado, coleção e saída cabem com fonte 300%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      app(const TelaAutenticacao(firebaseAtivo: true), escala: 3),
    );
    await tester.ensureVisible(find.text('Ainda não tenho uma conta'));
    await tester.tap(find.text('Ainda não tenho uma conta'));
    await estabilizar(tester);
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await estabilizar(tester);
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.ensureVisible(find.text('Criar conta'));
    await estabilizar(tester);
    expect(tester.takeException(), isNull);
    tester.testTextInput.hide();
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetViewInsets();
    await tester.runAsync(() async {
      await colecao.alternarFavorito(obra);
      await colecao.alternarVisto(obra);
    });
    await tester.pumpWidget(app(const TelaPrincipal(), escala: 3));
    await estabilizar(tester);
    await tester.ensureVisible(find.byType(TextField));
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await estabilizar(tester);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    tester.testTextInput.hide();
    await estabilizar(tester);
    for (final aba in ['Favoritos', 'Vistas']) {
      await tester.ensureVisible(find.text(aba));
      await tester.tap(find.text(aba));
      await estabilizar(tester);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Nenúfares'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(TelaColecao),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await estabilizar(tester);
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.byTooltip('Sair da conta'));
    await tester.tap(find.byTooltip('Sair da conta'));
    await estabilizar(tester);
    expect(find.text('Sair da conta?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancelar'));
    await estabilizar(tester);
    expect(find.byType(AlertDialog), findsNothing);
  });

  for (final escala in [1.0, 2.0, 3.0]) {
    for (final tamanho in [
      const Size(320, 568),
      const Size(568, 320),
      const Size(320, 740),
      const Size(1024, 768),
    ]) {
      testWidgets(
        'telas sem overflow, fonte $escala, largura ${tamanho.width}',
        (tester) async {
          tester.view.physicalSize = tamanho;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final tela in [
            const TelaAutenticacao(firebaseAtivo: false),
            const TelaPrincipal(),
            const TelaDetalhesObra(obraInicial: obra),
            Scaffold(
              body: GradeObras(
                obras: const [
                  Obra(
                    id: 42,
                    titulo: 'Uma obra com um título muito longo para testar a ampliação da fonte e a leitura completa',
                    nomeArtista: 'Um artista com nome extenso',
                  ),
                ],
                aoSelecionar: (_) {},
              ),
            ),
          ]) {
            await tester.pumpWidget(app(tela, escala: escala));
            await estabilizar(tester);
            expect(tester.takeException(), isNull, reason: '$tela');
          }
        },
      );
    }
  }
}
