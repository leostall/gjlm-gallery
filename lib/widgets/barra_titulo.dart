import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mede o título com a fonte do sistema, reservando espaço para voltar e ações.
AppBar barraTitulo(
  BuildContext context, {
  required String titulo,
  required Color fundo,
  required Color cor,
  List<Widget>? acoes,
  double larguraAcoes = 0,
  PreferredSizeWidget? rodape,
}) {
  final voltar = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
  final estilo = Theme.of(context).textTheme.titleLarge!
      .copyWith(fontSize: 20, height: 1.2, color: cor);
  final pintor =
      TextPainter(
        text: TextSpan(text: titulo, style: estilo),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(
        maxWidth: math.max(
          1,
          MediaQuery.sizeOf(context).width -
              MediaQuery.paddingOf(context).horizontal -
              32 -
              (voltar ? 56 : 0) -
              larguraAcoes,
        ),
      );
  final altura = math.max(64.0, pintor.height + 24);
  pintor.dispose();
  return AppBar(
    primary: false,
    backgroundColor: fundo,
    foregroundColor: cor,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: altura,
    title: Text(titulo, style: estilo, maxLines: 100),
    actions: acoes,
    bottom: rodape,
  );
}
