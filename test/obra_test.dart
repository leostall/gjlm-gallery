import 'package:flutter_test/flutter_test.dart';
import 'package:gjlm_gallery/modelos/obra.dart';

void main() {
  test('converte o JSON da API em uma obra', () {
    final obra = Obra.deJson({
      'id': 27992,
      'title': 'The Bedroom',
      'artist_title': 'Vincent van Gogh',
      'image_id': 'abc123',
      'thumbnail': {'alt_text': 'Um quarto com móveis azuis.'},
    });

    expect(obra.id, 27992);
    expect(obra.titulo, 'The Bedroom');
    expect(obra.nomeArtista, 'Vincent van Gogh');
    expect(obra.urlImagem, contains('/abc123/full/843,/0/default.jpg'));
    expect(obra.textoAlternativo, 'Um quarto com móveis azuis.');
  });

  test('usa valores seguros quando campos opcionais estão ausentes', () {
    final obra = Obra.deJson({'id': 1, 'title': null});

    expect(obra.titulo, 'Obra sem título');
    expect(obra.artistaParaExibicao, 'Artista não informado');
    expect(obra.urlImagem, isNull);
  });
}
