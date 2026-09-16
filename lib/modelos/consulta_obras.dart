import 'obra.dart';

/// Uma busca livre, ou título e artista separados por travessão, hífen ou barra.
class ConsultaObras {
  ConsultaObras(String texto) : termo = texto.trim() {
    final separadores = RegExp(r'\s+[—–|\-]\s+').allMatches(termo).toList();
    if (separadores.isNotEmpty) {
      final separador = separadores.last;
      titulo = termo.substring(0, separador.start).trim();
      artista = termo.substring(separador.end).trim();
    }
  }

  final String termo;
  String? titulo;
  String? artista;

  bool get temTituloEArtista =>
      titulo?.isNotEmpty == true && artista?.isNotEmpty == true;

  Map<String, String> get parametros => temTituloEArtista
      ? {'title': titulo!, 'artists': artista!}
      : {if (termo.isNotEmpty) 'q': termo};

  bool correspondeExatamente(Obra obra) =>
      temTituloEArtista &&
      obra.nomeArtista?.trim().isNotEmpty == true &&
      _normalizar(obra.titulo) == _normalizar(titulo!) &&
      _normalizar(obra.nomeArtista!) == _normalizar(artista!);

  bool correspondeAoFiltro(Obra obra) {
    if (temTituloEArtista) {
      return _normalizar(obra.titulo).contains(_normalizar(titulo!)) &&
          _normalizar(obra.artistaParaExibicao).contains(_normalizar(artista!));
    }
    return _normalizar('${obra.titulo} ${obra.artistaParaExibicao}')
        .contains(_normalizar(termo));
  }

  static String _normalizar(String texto) =>
      texto.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
