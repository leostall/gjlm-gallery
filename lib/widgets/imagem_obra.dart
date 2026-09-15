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

    return Semantics(
      image: true,
      label: descricao,
      child: ExcludeSemantics(
        child: url == null
            ? const _PlaceholderImagem()
            : Image.network(
                url,
                fit: ajuste,
                width: double.infinity,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => const _PlaceholderImagem(),
              ),
      ),
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
        child: Padding(
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
