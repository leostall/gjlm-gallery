import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../configuracoes/tema_aplicativo.dart';
import '../modelos/obra.dart';
import '../provedores/provedor_colecao.dart';
import 'imagem_obra.dart';

class CartaoObra extends StatelessWidget {
  const CartaoObra({super.key, required this.obra, required this.aoTocar});

  static const estiloTitulo = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 15,
    height: 1.2,
    color: CoresGaleria.tinta,
  );
  static const estiloArtista = TextStyle(
    fontSize: 13,
    height: 1.3,
    color: CoresGaleria.vinho,
  );

  final Obra obra;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final colecao = context.watch<ProvedorColecao>();
    final favorito = colecao.ehFavorito(obra.id);
    void alternar() => colecao.alternarFavorito(obra);

    return Material(
      color: CoresGaleria.creme,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CoresGaleria.cremeEscuro),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              container: true,
              button: true,
              excludeSemantics: true,
              label: '${obra.titulo}, de ${obra.artistaParaExibicao}',
              hint: 'Abrir detalhes da obra',
              onTap: aoTocar,
              child: InkWell(
                onTap: aoTocar,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 210,
                      child: ColoredBox(
                        color: CoresGaleria.cremeEscuro,
                        child: ImagemObra(obra: obra, ajuste: BoxFit.contain),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            obra.titulo,
                            style: estiloTitulo,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            obra.artistaParaExibicao,
                            style: estiloArtista,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Semantics(
              container: true,
              button: true,
              toggled: favorito,
              label: favorito
                  ? 'Remover ${obra.titulo} dos favoritos'
                  : 'Adicionar ${obra.titulo} aos favoritos',
              onTap: alternar,
              excludeSemantics: true,
              child: Tooltip(
                message: favorito
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
                child: SizedBox.square(
                  key: ValueKey('favorito-${obra.id}'),
                  dimension: 56,
                  child: Material(
                    color: CoresGaleria.vinho,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: alternar,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Icon(
                          favorito ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
