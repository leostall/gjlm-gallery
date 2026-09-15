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
    this.urlImagem,
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
  final String? urlImagem;
  final String? textoAlternativo;

  String get artistaParaExibicao =>
      _textoValido(nomeArtista) ?? 'Artista não informado';

  factory Obra.deJson(Map<String, dynamic> json) {
    final imagens = json['images'];
    final dadosImagens = imagens is Map
        ? Map<String, dynamic>.from(imagens)
        : <String, dynamic>{};
    final imagemWeb = dadosImagens['web'];
    final dadosImagemWeb = imagemWeb is Map
        ? Map<String, dynamic>.from(imagemWeb)
        : <String, dynamic>{};
    final criadores = json['creators'] is List
        ? List<dynamic>.from(json['creators'] as List)
        : <dynamic>[];
    final primeiroCriador = criadores.isNotEmpty && criadores.first is Map
        ? Map<String, dynamic>.from(criadores.first as Map)
        : <String, dynamic>{};
    final dadosCriador = _textoValido(primeiroCriador['description']);
    final culturas = json['culture'] is List
        ? List<dynamic>.from(json['culture'] as List)
        : <dynamic>[];

    return Obra(
      id: (json['id'] as num).toInt(),
      titulo: _textoValido(json['title']) ?? 'Obra sem título',
      nomeArtista: _nomeResumidoCriador(dadosCriador),
      dadosArtista: dadosCriador,
      data: _textoValido(json['creation_date']),
      tipo: _textoValido(json['type']),
      tecnica: _textoValido(json['technique']),
      dimensoes: _textoValido(json['measurements']),
      origem: _juntarTextos(culturas),
      descricao: _textoValido(json['description']),
      urlImagem: _textoValido(dadosImagemWeb['url']),
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
      urlImagem: _textoValido(mapa['urlImagem']),
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
      'urlImagem': urlImagem,
      'textoAlternativo': textoAlternativo,
    };
  }

  static String? _textoValido(Object? valor) {
    if (valor is! String) return null;
    final texto = valor.trim();
    return texto.isEmpty ? null : texto;
  }

  static String? _nomeResumidoCriador(String? descricao) {
    if (descricao == null) return null;
    final inicioDetalhes = descricao.indexOf(' (');
    return inicioDetalhes > 0
        ? descricao.substring(0, inicioDetalhes).trim()
        : descricao;
  }

  static String? _juntarTextos(List<dynamic> valores) {
    final textos = valores.map(_textoValido).whereType<String>().toList();
    return textos.isEmpty ? null : textos.join(', ');
  }
}
