import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modelos/obra.dart';
import '../provedores/provedor_colecao.dart';
import '../widgets/grade_obras.dart';
import '../widgets/indicador_carregamento.dart';
import '../widgets/mensagem_estado.dart';
import 'tela_detalhes_obra.dart';

enum TipoColecao { favoritos, vistos }

class TelaColecao extends StatelessWidget {
  const TelaColecao({super.key, required this.tipo});

  final TipoColecao tipo;

  static const _vinho = Color(0xFF70263A);
  static const _dourado = Color(0xFFB49763);

  void _abrirDetalhes(BuildContext context, Obra obra) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TelaDetalhesObra(obraInicial: obra)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colecao = context.watch<ProvedorColecao>();
    final ehFavoritos = tipo == TipoColecao.favoritos;
    final obras = ehFavoritos ? colecao.favoritos : colecao.vistos;

    if (colecao.carregando && obras.isEmpty) {
      return IndicadorCarregamento(
        mensagem: ehFavoritos
            ? 'Carregando favoritos...'
            : 'Carregando obras vistas...',
      );
    }

    if (obras.isEmpty) {
      return MensagemEstado(
        icone: ehFavoritos ? Icons.favorite_border : Icons.visibility_outlined,
        titulo: ehFavoritos ? 'Nenhum favorito ainda' : 'Nenhuma obra vista',
        mensagem: ehFavoritos
            ? 'Abra uma obra no catálogo e toque no coração para salvá-la.'
            : 'Abra uma obra e marque que você já a viu.',
      );
    }

    return Column(
      children: [
        if (colecao.avisoSincronizacao != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEDE3D3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _dourado.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 17, color: _vinho),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      colecao.avisoSincronizacao!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF302A25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _dourado,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ehFavoritos
                    ? '${obras.length} FAVORITOS'
                    : '${obras.length} OBRAS VISTAS',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Color(0xFF302A25),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 0.8,
                  color: _dourado.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: GradeObras(
            obras: obras,
            aoSelecionar: (obra) => _abrirDetalhes(context, obra),
          ),
        ),
      ],
    );
  }
}