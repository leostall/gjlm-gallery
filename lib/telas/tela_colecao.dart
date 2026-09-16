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

    return CustomScrollView(
      slivers: [
        if (colecao.avisoSincronizacao != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Semantics(
                liveRegion: true,
                child: Text(colecao.avisoSincronizacao!),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Semantics(
              header: true,
              child: Text(
                ehFavoritos
                    ? '${obras.length} favoritos'
                    : '${obras.length} obras vistas',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _vinho,
                ),
              ),
            ),
          ),
        ),
        GradeObras(
          emSliver: true,
          obras: obras,
          aoSelecionar: (obra) => _abrirDetalhes(context, obra),
        ),
      ],
    );
  }
}
