import 'package:flutter/material.dart';

import '../configuracoes/tema_aplicativo.dart';
import '../modelos/obra.dart';

class ImagemObra extends StatelessWidget {
  const ImagemObra({super.key, required this.obra, this.ajuste = BoxFit.cover});

  final Obra obra;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    final url = obra.urlImagem;
    final descricao =
        obra.textoAlternativo ??
        'Imagem da obra ${obra.titulo}, de ${obra.artistaParaExibicao}';

    Widget semantica(Widget child, {bool indisponivel = false}) => Semantics(
      image: true,
      excludeSemantics: true,
      label: indisponivel
          ? 'Imagem indisponível para ${obra.titulo}, de ${obra.artistaParaExibicao}'
          : descricao,
      child: child,
    );

    return url == null
        ? semantica(const _PlaceholderImagem(), indisponivel: true)
        : Image.network(
            url,
            fit: ajuste,
            width: double.infinity,
            excludeFromSemantics: true,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            frameBuilder: (_, child, _, _) => semantica(child),
            errorBuilder: (_, _, _) =>
                semantica(const _PlaceholderImagem(), indisponivel: true),
          );
  }
}

class _PlaceholderImagem extends StatelessWidget {
  const _PlaceholderImagem();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CoresGaleria.cremeEscuro,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_not_supported_outlined,
                size: 42,
                color: CoresGaleria.vinho,
              ),
              const SizedBox(height: 8),
              Text(
                'Imagem indisponível',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
