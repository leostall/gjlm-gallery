import 'package:flutter/material.dart';

import '../modelos/obra.dart';
import 'imagem_obra.dart';

class CartaoObra extends StatelessWidget {
  const CartaoObra({
    super.key,
    required this.obra,
    required this.aoTocar,
  });

  final Obra obra;
  final VoidCallback aoTocar;

  static const vinho = Color(0xFF70263A);
  static const creme = Color(0xFFF7F3EA);
  static const dourado = Color(0xFFB49763);
  static const texto = Color(0xFF302A25);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Abrir detalhes de ${obra.titulo}, ${obra.artistaParaExibicao}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: creme,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: dourado.withValues(alpha: 0.35),
                width: 0.7,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImagemObra(obra: obra),

                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.25,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      10,
                      12,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          obra.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 15,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            color: texto,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          obra.artistaParaExibicao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.2,
                            color: vinho,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}