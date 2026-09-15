import 'package:flutter/material.dart';

class MensagemEstado extends StatelessWidget {
  const MensagemEstado({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.aoAcionar,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? aoAcionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: titulo,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center),
            if (rotuloAcao != null && aoAcionar != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: aoAcionar,
                child: Text(rotuloAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
