import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../modelos/obra.dart';
import 'cartao_obra.dart';

class GradeObras extends StatelessWidget {
  const GradeObras({
    super.key,
    required this.obras,
    required this.aoSelecionar,
    this.controller,
    this.emSliver = false,
    this.padding = const EdgeInsets.fromLTRB(22, 12, 22, 20),
  });

  final List<Obra> obras;
  final ValueChanged<Obra> aoSelecionar;
  final ScrollController? controller;
  final bool emSliver;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (emSliver) {
      return SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, limites) => _grade(context, limites.maxWidth),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, limites) => _grade(context, limites.maxWidth),
    );
  }

  Widget _grade(BuildContext context, double larguraDisponivel) {
    final escala = MediaQuery.textScalerOf(context);
    final largura = larguraDisponivel - padding.horizontal;
    final colunas = (largura / (180 * math.max(1, escala.scale(14) / 14)))
        .floor()
        .clamp(1, 4);
    final larguraTexto = (largura - 16 * (colunas - 1)) / colunas - 24;
    double alturaTexto(String texto, TextStyle estilo) {
      final pintor = TextPainter(
        text: TextSpan(text: texto, style: estilo),
        textDirection: Directionality.of(context),
        textScaler: escala,
      )..layout(maxWidth: math.max(1, larguraTexto));
      final altura = pintor.height;
      pintor.dispose();
      return altura;
    }

    var altura = 290.0;
    for (final obra in obras) {
      altura = math.max(
        altura,
        210 +
            24 +
            6 +
            alturaTexto(
              obra.titulo,
              const TextStyle(fontFamily: 'Georgia', fontSize: 15, height: 1.2),
            ) +
            alturaTexto(
              obra.artistaParaExibicao,
              const TextStyle(fontSize: 13, height: 1.3),
            ) +
            4,
      );
    }
    final delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: colunas,
      crossAxisSpacing: 16,
      mainAxisSpacing: 20,
      mainAxisExtent: altura,
    );
    Widget item(BuildContext context, int indice) => CartaoObra(
      obra: obras[indice],
      aoTocar: () => aoSelecionar(obras[indice]),
    );
    return GridView.builder(
      // Mantém o GridView pedido no RF01 e deixa a página rolar como um todo.
      shrinkWrap: emSliver,
      primary: emSliver ? false : null,
      physics: emSliver ? const NeverScrollableScrollPhysics() : null,
      controller: controller,
      padding: padding,
      gridDelegate: delegate,
      itemCount: obras.length,
      itemBuilder: item,
    );
  }
}
