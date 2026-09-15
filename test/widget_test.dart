import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjlm_gallery/modelos/obra.dart';
import 'package:gjlm_gallery/widgets/cartao_obra.dart';

void main() {
  testWidgets('o card apresenta título e artista', (testador) async {
    const obra = Obra(id: 1, titulo: 'Nenúfares', nomeArtista: 'Claude Monet');

    await testador.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 340,
            child: CartaoObra(obra: obra, aoTocar: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Nenúfares'), findsOneWidget);
    expect(find.text('Claude Monet'), findsOneWidget);
  });
}
