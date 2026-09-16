import 'package:flutter/material.dart';

/// O rótulo pode ocupar várias linhas sem ser cortado pela decoração do campo.
class CampoRotulado extends StatelessWidget {
  const CampoRotulado({super.key, required this.rotulo, required this.child});

  final String rotulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExcludeSemantics(
        child: Text(rotulo, style: Theme.of(context).textTheme.titleSmall),
      ),
      const SizedBox(height: 8),
      Semantics(label: rotulo, child: child),
    ],
  );
}
