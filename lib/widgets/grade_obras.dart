import 'package:flutter/material.dart';

import '../modelos/obra.dart';
import 'cartao_obra.dart';

class GradeObras extends StatelessWidget {
  const GradeObras({
    super.key,
    required this.obras,
    required this.aoSelecionar,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Obra> obras;
  final ValueChanged<Obra> aoSelecionar;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final escalaTexto = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.6);
    final colunas = largura >= 900 ? 4 : (largura >= 600 ? 3 : 2);

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: colunas,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.67 / escalaTexto,
      ),
      itemCount: obras.length,
      itemBuilder: (context, indice) {
        final obra = obras[indice];
        return CartaoObra(obra: obra, aoTocar: () => aoSelecionar(obra));
      },
    );
  }
}
