import 'package:flutter/material.dart';

import '../modelos/obra.dart';
import 'cartao_obra.dart';

class GradeObras extends StatelessWidget {
  const GradeObras({
    super.key,
    required this.obras,
    required this.aoSelecionar,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(
      22,
      12,
      22,
      20,
    ),
  });

  final List<Obra> obras;
  final ValueChanged<Obra> aoSelecionar;
  final ScrollController? controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;

    final colunas = largura >= 1200
        ? 4
        : largura >= 900
            ? 4
            : largura >= 600
                ? 3
                : 2;

    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: colunas,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.72,
      ),
      itemCount: obras.length,
      itemBuilder: (context, indice) {
        final obra = obras[indice];

        return CartaoObra(
          obra: obra,
          aoTocar: () => aoSelecionar(obra),
        );
      },
    );
  }
}