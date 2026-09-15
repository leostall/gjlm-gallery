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

  void _abrirDetalhes(BuildContext context, Obra obra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaDetalhesObra(obraInicial: obra),
      ),
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
        icone: ehFavoritos
            ? Icons.favorite_border
            : Icons.visibility_outlined,
        titulo: ehFavoritos ? 'Nenhum favorito ainda' : 'Nenhuma obra vista',
        mensagem: ehFavoritos
            ? 'Abra uma obra no catálogo e toque no coração para salvá-la.'
            : 'Abra uma obra e marque que você já a viu.',
      );
    }

    return Column(
      children: [
        if (colecao.avisoSincronizacao != null)
          MaterialBanner(
            content: Text(colecao.avisoSincronizacao!),
            leading: const Icon(Icons.cloud_off_outlined),
            actions: const [SizedBox.shrink()],
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
