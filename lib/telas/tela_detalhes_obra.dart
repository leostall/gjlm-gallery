import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../configuracoes/tema_aplicativo.dart';
import '../modelos/obra.dart';
import '../provedores/provedor_catalogo.dart';
import '../provedores/provedor_colecao.dart';
import '../widgets/imagem_obra.dart';
import '../widgets/indicador_carregamento.dart';
import '../widgets/mensagem_estado.dart';

class TelaDetalhesObra extends StatefulWidget {
  const TelaDetalhesObra({
    super.key,
    required this.obraInicial,
  });

  final Obra obraInicial;

  @override
  State<TelaDetalhesObra> createState() => _TelaDetalhesObraState();
}

class _TelaDetalhesObraState extends State<TelaDetalhesObra> {
  late Future<Obra> _futuroObra;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futuroObra = context
        .read<ProvedorCatalogo>()
        .carregarDetalhes(widget.obraInicial.id);
  }

  void _tentarNovamente() {
    setState(_carregar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da obra')),
      body: FutureBuilder<Obra>(
        future: _futuroObra,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const IndicadorCarregamento(
              mensagem: 'Carregando detalhes...',
            );
          }

          if (snapshot.hasError) {
            return MensagemEstado(
              icone: Icons.error_outline,
              titulo: 'Detalhes indisponíveis',
              mensagem: 'Não foi possível carregar os dados completos da obra.',
              rotuloAcao: 'Tentar novamente',
              aoAcionar: _tentarNovamente,
            );
          }

          return _ConteudoDetalhes(obra: snapshot.data ?? widget.obraInicial);
        },
      ),
    );
  }
}

class _ConteudoDetalhes extends StatelessWidget {
  const _ConteudoDetalhes({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final colecao = context.watch<ProvedorColecao>();
    final favorito = colecao.ehFavorito(obra.id);
    final visto = colecao.foiVisto(obra.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Container(
              color: CoresGaleria.cremeEscuro,
              padding: const EdgeInsets.all(16),
              child: ImagemObra(obra: obra, ajuste: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obra.titulo,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  obra.artistaParaExibicao,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CoresGaleria.dourado,
                      ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Semantics(
                      button: true,
                      label: favorito
                          ? 'Remover ${obra.titulo} dos favoritos'
                          : 'Adicionar ${obra.titulo} aos favoritos',
                      child: ElevatedButton.icon(
                        onPressed: () => colecao.alternarFavorito(obra),
                        icon: Icon(
                          favorito ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: Text(favorito ? 'Favoritada' : 'Favoritar'),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: visto
                          ? 'Marcar ${obra.titulo} como não vista'
                          : 'Marcar ${obra.titulo} como vista',
                      child: OutlinedButton.icon(
                        onPressed: () => colecao.alternarVisto(obra),
                        icon: Icon(
                          visto ? Icons.visibility : Icons.visibility_outlined,
                        ),
                        label: Text(visto ? 'Obra vista' : 'Marcar como vista'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _LinhaInformacao(rotulo: 'Artista', valor: obra.dadosArtista),
                _LinhaInformacao(rotulo: 'Data', valor: obra.data),
                _LinhaInformacao(rotulo: 'Tipo', valor: obra.tipo),
                _LinhaInformacao(rotulo: 'Técnica', valor: obra.tecnica),
                _LinhaInformacao(rotulo: 'Dimensões', valor: obra.dimensoes),
                _LinhaInformacao(rotulo: 'Origem', valor: obra.origem),
                if (obra.descricao != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Sobre a obra',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_removerHtml(obra.descricao!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _removerHtml(String texto) {
    return texto
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _LinhaInformacao extends StatelessWidget {
  const _LinhaInformacao({required this.rotulo, required this.valor});

  final String rotulo;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    if (valor == null || valor!.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: CoresGaleria.vinho,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 3),
          Text(valor!),
        ],
      ),
    );
  }
}
