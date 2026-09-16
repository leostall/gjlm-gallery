import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'configuracoes/tema_aplicativo.dart';
import 'provedores/provedor_autenticacao.dart';
import 'telas/tela_autenticacao.dart';
import 'telas/tela_principal.dart';
import 'widgets/indicador_carregamento.dart';

class AplicativoGaleria extends StatelessWidget {
  const AplicativoGaleria({super.key, required this.firebaseAtivo});

  final bool firebaseAtivo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GJLM Gallery',
      debugShowCheckedModeBanner: false,
      theme: TemaAplicativo.claro,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) =>
          Semantics(localeForSubtree: const Locale('pt', 'BR'), child: child!),
      home: PortalAutenticacao(firebaseAtivo: firebaseAtivo),
    );
  }
}

class PortalAutenticacao extends StatelessWidget {
  const PortalAutenticacao({super.key, required this.firebaseAtivo});

  final bool firebaseAtivo;

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ProvedorAutenticacao>();

    if (!autenticacao.inicializado) {
      return const Scaffold(
        body: IndicadorCarregamento(mensagem: 'Preparando sua galeria...'),
      );
    }

    if (autenticacao.usuario == null) {
      return TelaAutenticacao(firebaseAtivo: firebaseAtivo);
    }

    return const TelaPrincipal();
  }
}
