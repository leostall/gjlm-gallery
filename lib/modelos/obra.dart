class Obra {
  const Obra({
    required this.id,
    required this.titulo,
    this.nomeArtista,
    this.dadosArtista,
    this.data,
    this.tipo,
    this.tecnica,
    this.dimensoes,
    this.origem,
    this.descricao,
    this.identificadorImagem,
    this.textoAlternativo,
  });

  final int id;
  final String titulo;
  final String? nomeArtista;
  final String? dadosArtista;
  final String? data;
  final String? tipo;
  final String? tecnica;
  final String? dimensoes;
  final String? origem;
  final String? descricao;
  final String? identificadorImagem;
  final String? textoAlternativo;

  String? get urlImagem {
    final imagem = identificadorImagem;
    if (imagem == null || imagem.isEmpty) return null;
    return 'https://www.artic.edu/iiif/2/$imagem/full/843,/0/default.jpg';
  }

  String get artistaParaExibicao =>
      _textoValido(nomeArtista) ?? 'Artista não informado';

  factory Obra.deJson(Map<String, dynamic> json) {
    final miniatura = json['thumbnail'];
    final dadosMiniatura = miniatura is Map
        ? Map<String, dynamic>.from(miniatura)
        : <String, dynamic>{};

    return Obra(
      id: (json['id'] as num).toInt(),
      titulo: _textoValido(json['title']) ?? 'Obra sem título',
      nomeArtista: _textoValido(json['artist_title']),
      dadosArtista: _textoValido(json['artist_display']),
      data: _textoValido(json['date_display']),
      tipo: _textoValido(json['artwork_type_title']),
      tecnica: _textoValido(json['medium_display']),
      dimensoes: _textoValido(json['dimensions']),
      origem: _textoValido(json['place_of_origin']),
      descricao: _textoValido(json['description']),
      identificadorImagem: _textoValido(json['image_id']),
      textoAlternativo: _textoValido(dadosMiniatura['alt_text']),
    );
  }

  factory Obra.deMapa(Map<String, dynamic> mapa) {
    return Obra(
      id: (mapa['id'] as num).toInt(),
      titulo: _textoValido(mapa['titulo']) ?? 'Obra sem título',
      nomeArtista: _textoValido(mapa['nomeArtista']),
      dadosArtista: _textoValido(mapa['dadosArtista']),
      data: _textoValido(mapa['data']),
      tipo: _textoValido(mapa['tipo']),
      tecnica: _textoValido(mapa['tecnica']),
      dimensoes: _textoValido(mapa['dimensoes']),
      origem: _textoValido(mapa['origem']),
      descricao: _textoValido(mapa['descricao']),
      identificadorImagem: _textoValido(mapa['identificadorImagem']),
      textoAlternativo: _textoValido(mapa['textoAlternativo']),
    );
  }

  Map<String, dynamic> paraMapa() {
    return {
      'id': id,
      'titulo': titulo,
      'nomeArtista': nomeArtista,
      'dadosArtista': dadosArtista,
      'data': data,
      'tipo': tipo,
      'tecnica': tecnica,
      'dimensoes': dimensoes,
      'origem': origem,
      'descricao': descricao,
      'identificadorImagem': identificadorImagem,
      'textoAlternativo': textoAlternativo,
    };
  }

  static String? _textoValido(Object? valor) {
    if (valor is! String) return null;
    final texto = valor.trim();
    return texto.isEmpty ? null : texto;
  }
}
