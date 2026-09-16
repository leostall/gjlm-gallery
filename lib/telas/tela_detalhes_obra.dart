import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../configuracoes/tema_aplicativo.dart';
import '../modelos/obra.dart';
import '../provedores/provedor_catalogo.dart';
import '../provedores/provedor_colecao.dart';
import '../widgets/imagem_obra.dart';
import '../widgets/barra_titulo.dart';
import '../widgets/estrutura_pagina.dart';
import '../widgets/indicador_carregamento.dart';
import '../widgets/mensagem_estado.dart';

class TelaDetalhesObra extends StatefulWidget {
  const TelaDetalhesObra({super.key, required this.obraInicial});

  final Obra obraInicial;

  @override
  State<TelaDetalhesObra> createState() => _TelaDetalhesObraState();
}

class _TelaDetalhesObraState extends State<TelaDetalhesObra> {
  late Future<Obra> _futuroObra;

  static const _vinho = Color(0xFF70263A);
  static const _creme = Color(0xFFF5F1E8);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futuroObra = context.read<ProvedorCatalogo>().carregarDetalhes(
      widget.obraInicial.id,
    );
  }

  void _tentarNovamente() {
    setState(_carregar);
  }

  @override
  Widget build(BuildContext context) {
    return EstruturaPagina(
      backgroundColor: _creme,
      appBar: barraTitulo(
        context,
        titulo: 'Detalhes da obra',
        fundo: _creme,
        cor: _vinho,
      ),
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
    final imagem = AspectRatio(
      aspectRatio: 1,
      child: ImagemObra(obra: obra, ajuste: BoxFit.contain),
    );
    final ficha = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            obra.titulo,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          obra.artistaParaExibicao,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Semantics(
              button: true,
              toggled: favorito,
              excludeSemantics: true,
              label: favorito
                  ? 'Remover ${obra.titulo} dos favoritos'
                  : 'Adicionar ${obra.titulo} aos favoritos',
              onTap: () => colecao.alternarFavorito(obra),
              child: ElevatedButton.icon(
                onPressed: () => colecao.alternarFavorito(obra),
                icon: Icon(favorito ? Icons.favorite : Icons.favorite_border),
                label: Text(favorito ? 'Favoritada' : 'Favoritar'),
              ),
            ),
            Semantics(
              button: true,
              toggled: visto,
              excludeSemantics: true,
              label: visto
                  ? 'Marcar ${obra.titulo} como não vista'
                  : 'Marcar ${obra.titulo} como vista',
              onTap: () => colecao.alternarVisto(obra),
              child: OutlinedButton.icon(
                onPressed: () => colecao.alternarVisto(obra),
                icon: Icon(
                  visto ? Icons.visibility : Icons.visibility_outlined,
                ),
                label: Text(visto ? 'Vista' : 'Marcar vista'),
              ),
            ),
          ],
        ),
        if (colecao.avisoSincronizacao != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(colecao.avisoSincronizacao!)),
        ],
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            'Ficha técnica',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _CampoInfo(rotulo: 'Artista', valor: obra.dadosArtista),
        _CampoInfo(rotulo: 'Data', valor: obra.data),
        _CampoInfo(rotulo: 'Tipo', valor: obra.tipo),
        _CampoInfo(rotulo: 'Técnica', valor: obra.tecnica),
        _CampoInfo(rotulo: 'Dimensões', valor: obra.dimensoes),
        _CampoInfo(rotulo: 'Origem', valor: obra.origem),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            'Sobre a obra',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          obra.descricao == null
              ? 'Descrição não informada pelo museu.'
              : _removerHtml(obra.descricao!),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, limites) {
        final amplo =
            limites.maxWidth >= 900 &&
            MediaQuery.textScalerOf(context).scale(14) <= 21;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: amplo
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: imagem),
                    const SizedBox(width: 24),
                    Expanded(child: ficha),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [imagem, const SizedBox(height: 24), ficha],
                ),
        );
      },
    );
  }

  String _removerHtml(String texto) => texto
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _CampoInfo extends StatelessWidget {
  const _CampoInfo({required this.rotulo, required this.valor});
  final String rotulo;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CoresGaleria.vinho,
              ),
            ),
            Text(
              valor == null || valor!.trim().isEmpty ? 'Não informado' : valor!,
            ),
          ],
        ),
      ),
    );
  }
}
