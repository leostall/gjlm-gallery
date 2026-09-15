import 'package:flutter_test/flutter_test.dart';
import 'package:gjlm_gallery/modelos/obra.dart';

void main() {
  test('converte o JSON da API em uma obra', () {
    final obra = Obra.deJson({
      'id': 135382,
      'title': 'The Red Kerchief',
      'creation_date': '1868–1873',
      'creators': [
        {'description': 'Claude Monet (French, 1840–1926)'},
      ],
      'culture': ['France'],
      'images': {
        'web': {'url': 'https://openaccess-cdn.clevelandart.org/obra_web.jpg'},
      },
    });

    expect(obra.id, 135382);
    expect(obra.titulo, 'The Red Kerchief');
    expect(obra.nomeArtista, 'Claude Monet');
    expect(obra.dadosArtista, 'Claude Monet (French, 1840–1926)');
    expect(obra.origem, 'France');
    expect(
      obra.urlImagem,
      'https://openaccess-cdn.clevelandart.org/obra_web.jpg',
    );
  });

  test('usa valores seguros quando campos opcionais estão ausentes', () {
    final obra = Obra.deJson({'id': 1, 'title': null});

    expect(obra.titulo, 'Obra sem título');
    expect(obra.artistaParaExibicao, 'Artista não informado');
    expect(obra.urlImagem, isNull);
  });

  test('preserva a URL da imagem ao converter a obra para armazenamento', () {
    const obra = Obra(
      id: 2,
      titulo: 'Obra persistida',
      urlImagem: 'https://openaccess-cdn.clevelandart.org/obra.jpg',
    );

    final restaurada = Obra.deMapa(obra.paraMapa());

    expect(restaurada.urlImagem, obra.urlImagem);
  });
}
