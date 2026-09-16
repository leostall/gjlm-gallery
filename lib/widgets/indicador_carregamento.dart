import 'package:flutter/material.dart';

class IndicadorCarregamento extends StatelessWidget {
  const IndicadorCarregamento({super.key, this.mensagem = 'Carregando...'});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: mensagem,
        excludeSemantics: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(semanticsLabel: mensagem),
              const SizedBox(height: 16),
              Text(mensagem, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
