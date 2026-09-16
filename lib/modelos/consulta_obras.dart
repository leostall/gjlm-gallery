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
}
