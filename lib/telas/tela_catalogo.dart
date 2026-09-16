import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modelos/obra.dart';
import '../provedores/provedor_catalogo.dart';
import '../widgets/grade_obras.dart';
import '../widgets/campo_rotulado.dart';
import '../widgets/indicador_carregamento.dart';
import '../widgets/mensagem_estado.dart';
import 'tela_detalhes_obra.dart';

class TelaCatalogo extends StatefulWidget {
  const TelaCatalogo({super.key});
  @override
  State<TelaCatalogo> createState() => _TelaCatalogoState();
}

class _TelaCatalogoState extends State<TelaCatalogo> {
  final _controladorBusca = TextEditingController();
  final _controladorScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProvedorCatalogo>().carregarInicial();
    });
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    _controladorScroll.dispose();
    super.dispose();
  }

  void _filtrar(String texto) {
    context.read<ProvedorCatalogo>().filtrar(texto);
    if (_controladorScroll.hasClients) _controladorScroll.jumpTo(0);
  }

  Future<void> _buscar() async {
    final catalogo = context.read<ProvedorCatalogo>();
    if (catalogo.buscando) return;
    FocusScope.of(context).unfocus();
    final obra = await catalogo.buscar(_controladorBusca.text);
    if (mounted && obra != null) {
      _abrirDetalhes(obra);
    }
  }

  void _abrirDetalhes(Obra obra) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TelaDetalhesObra(obraInicial: obra)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<ProvedorCatalogo>();
    final campo = CampoRotulado(
      rotulo: 'Buscar obra ou artista',
      child: TextField(
        controller: _controladorBusca,
        onChanged: (texto) {
          _filtrar(texto);
          setState(() {});
        },
        onSubmitted: (_) => _buscar(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controladorBusca.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    _controladorBusca.clear();
                    _filtrar('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
        ),
      ),
    );
    final buscar = ElevatedButton(
      onPressed: catalogo.buscando ? null : _buscar,
      child: catalogo.buscando
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(semanticsLabel: 'Buscando obra'),
            )
          : const Text('Buscar'),
    );
    return CustomScrollView(
      controller: _controladorScroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LayoutBuilder(
              builder: (context, limites) {
                if (limites.maxWidth < 450 ||
                    MediaQuery.textScalerOf(context).scale(14) > 21) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [campo, const SizedBox(height: 8), buscar],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: campo),
                    const SizedBox(width: 12),
                    buscar,
                  ],
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Para abrir uma correspondência exata, digite: Título — Artista.',
            ),
          ),
        ),
        if (catalogo.carregandoInicial && catalogo.obras.isNotEmpty)
          const SliverToBoxAdapter(
            child: IndicadorCarregamento(mensagem: 'Filtrando obras'),
          ),
        if (catalogo.erro != null || catalogo.avisoBusca != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Text(catalogo.erro ?? catalogo.avisoBusca!),
              ),
            ),
          ),
        if (catalogo.obras.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: catalogo.carregandoInicial
                ? const IndicadorCarregamento(mensagem: 'Buscando obras...')
                : MensagemEstado(
                    icone: catalogo.erro == null
                        ? Icons.search_off
                        : Icons.cloud_off,
                    titulo: catalogo.erro == null
                        ? 'Nenhuma obra encontrada'
                        : 'Acervo indisponível',
                    mensagem: catalogo.erro == null
                        ? 'Tente outro nome de obra ou artista.'
                        : 'Verifique a conexão e tente novamente.',
                    rotuloAcao: catalogo.erro == null
                        ? null
                        : 'Tentar novamente',
                    aoAcionar: () => catalogo.carregarInicial(forcar: true),
                  ),
          )
        else
          GradeObras(
            emSliver: true,
            obras: catalogo.obras,
            aoSelecionar: _abrirDetalhes,
          ),
        if (catalogo.temProximaPagina && !catalogo.carregandoInicial)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: catalogo.carregandoMais || catalogo.buscando
                    ? null
                    : catalogo.carregarMais,
                icon: catalogo.carregandoMais
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Carregando mais obras',
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  catalogo.carregandoMais ? 'Carregando...' : 'Carregar mais',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
