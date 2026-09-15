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
  const TelaDetalhesObra({super.key, required this.obraInicial});

  final Obra obraInicial;

  @override
  State<TelaDetalhesObra> createState() => _TelaDetalhesObraState();
}

class _TelaDetalhesObraState extends State<TelaDetalhesObra> {
  late Future<Obra> _futuroObra;

  static const _vinho = Color(0xFF70263A);
  static const _creme = Color(0xFFF5F1E8);
  static const _dourado = Color(0xFFB49763);

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
    return Scaffold(
      backgroundColor: _creme,
      appBar: AppBar(
        backgroundColor: _creme,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: _vinho,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2.4,
              height: 18,
              color: _dourado,
              margin: const EdgeInsets.only(right: 10),
            ),
            const Text(
              'DETALHES DA OBRA',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _vinho,
              ),
            ),
          ],
        ),
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

// ===============================================================
// LAYOUT PRINCIPAL — imagem fixa à esquerda, texto rolável à direita
// ===============================================================

class _ConteudoDetalhes extends StatelessWidget {
  const _ConteudoDetalhes({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final colecao = context.watch<ProvedorColecao>();
    final favorito = colecao.ehFavorito(obra.id);
    final visto = colecao.foiVisto(obra.id);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // -------- coluna esquerda: moldura da obra (fixa) --------
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
            child: _MolduraObra(obra: obra, favorito: favorito, visto: visto),
          ),
        ),

        // -------- coluna direita: conteúdo rolável --------
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obra.titulo,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Georgia',
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  obra.artistaParaExibicao,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CoresGaleria.dourado,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 18),

                // ações — favoritar / marcar como vista (compactas, lado a lado)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Semantics(
                      button: true,
                      label: favorito
                          ? 'Remover ${obra.titulo} dos favoritos'
                          : 'Adicionar ${obra.titulo} aos favoritos',
                      child: ElevatedButton.icon(
                        onPressed: () => colecao.alternarFavorito(obra),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CoresGaleria.vinho,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 17,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          favorito ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                        ),
                        label: Text(
                          favorito ? 'Favoritada' : 'Favoritar',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Semantics(
                      button: true,
                      label: visto
                          ? 'Marcar ${obra.titulo} como não vista'
                          : 'Marcar ${obra.titulo} como vista',
                      child: OutlinedButton.icon(
                        onPressed: () => colecao.alternarVisto(obra),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CoresGaleria.vinho,
                          side: BorderSide(
                            color: CoresGaleria.dourado.withValues(alpha: 0.8),
                            width: 0.9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 17,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          visto ? Icons.visibility : Icons.visibility_outlined,
                          size: 18,
                        ),
                        label: Text(
                          visto ? 'Vista' : 'Marcar vista',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),
                _TituloSecao(texto: 'Ficha técnica'),
                const SizedBox(height: 4),

                _CampoInfo(rotulo: 'Artista', valor: obra.dadosArtista),
                _CampoInfo(rotulo: 'Data', valor: obra.data),
                _CampoInfo(rotulo: 'Tipo', valor: obra.tipo),
                _CampoInfo(rotulo: 'Técnica', valor: obra.tecnica),
                _CampoInfo(rotulo: 'Dimensões', valor: obra.dimensoes),
                _CampoInfo(
                  rotulo: 'Origem',
                  valor: obra.origem,
                  ultimo: true,
                ),

                if (obra.descricao != null) ...[
                  const SizedBox(height: 22),
                  _TituloSecao(texto: 'Sobre a obra'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: CoresGaleria.dourado.withValues(alpha: 0.55),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _removerHtml(obra.descricao!),
                      style: const TextStyle(
                        height: 1.6,
                        fontSize: 14,
                        color: Color(0xFF3A332B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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

// ===============================================================
// MOLDURA DA OBRA — coluna esquerda, fixa, estilo placa de museu
// ===============================================================

class _MolduraObra extends StatelessWidget {
  const _MolduraObra({
    required this.obra,
    required this.favorito,
    required this.visto,
  });

  final Obra obra;
  final bool favorito;
  final bool visto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: CoresGaleria.dourado.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: CoresGaleria.dourado.withValues(alpha: 0.3),
                  width: 0.6,
                ),
                color: CoresGaleria.cremeEscuro,
              ),
              padding: const EdgeInsets.all(10),
              child: ImagemObra(obra: obra, ajuste: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // pequenos indicadores de status abaixo da moldura
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            if (favorito) const _SeloStatus(icone: Icons.favorite, texto: 'Favorita'),
            if (visto) const _SeloStatus(icone: Icons.visibility, texto: 'Vista'),
          ],
        ),
      ],
    );
  }
}

class _SeloStatus extends StatelessWidget {
  const _SeloStatus({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: CoresGaleria.vinho.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CoresGaleria.dourado.withValues(alpha: 0.5),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 11, color: CoresGaleria.vinho),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: CoresGaleria.vinho,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// PEQUENOS COMPONENTES DE TEXTO
// ===============================================================

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: CoresGaleria.vinho,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 0.8,
            color: CoresGaleria.dourado.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

class _CampoInfo extends StatelessWidget {
  const _CampoInfo({
    required this.rotulo,
    required this.valor,
    this.ultimo = false,
  });

  final String rotulo;
  final String? valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    if (valor == null || valor!.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: ultimo
            ? null
            : Border(
                bottom: BorderSide(
                  color: CoresGaleria.dourado.withValues(alpha: 0.18),
                  width: 0.7,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              rotulo.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: CoresGaleria.vinho.withValues(alpha: 0.85),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor!,
              style: const TextStyle(fontSize: 13.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}