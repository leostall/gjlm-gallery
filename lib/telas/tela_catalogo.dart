import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../modelos/obra.dart';
import '../provedores/provedor_catalogo.dart';
import '../widgets/grade_obras.dart';
import '../widgets/indicador_carregamento.dart';
import '../widgets/mensagem_estado.dart';
import 'tela_detalhes_obra.dart';

class TelaCatalogo extends StatefulWidget {
  const TelaCatalogo({super.key});
  @override
  State<TelaCatalogo> createState() => _TelaCatalogoState();
}

class _TelaCatalogoState extends State<TelaCatalogo> {
  static const _orientacaoBusca =
      'Digite o título, o nome do artista ou use o formato Título — Artista. '
      'A primeira obra encontrada será aberta.';

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

  void _voltarAoInicio() {
    if (_controladorScroll.hasClients) _controladorScroll.jumpTo(0);
  }

  Future<void> _limparBusca() async {
    final catalogo = context.read<ProvedorCatalogo>();
    _controladorBusca.clear();
    setState(() {});
    _voltarAoInicio();
    await catalogo.limparBusca();
  }

  void _mostrarOrientacaoBusca() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como buscar'),
        content: const Text(_orientacaoBusca),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _buscar() async {
    final catalogo = context.read<ProvedorCatalogo>();
    if (catalogo.buscando) return;
    FocusScope.of(context).unfocus();
    _voltarAoInicio();
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
    final campo = TextField(
      controller: _controladorBusca,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _buscar(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Buscar obra ou artista',
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_controladorBusca.text.trim().isNotEmpty)
              IconButton(
                tooltip: 'Limpar busca',
                onPressed: _limparBusca,
                icon: const Icon(Icons.clear),
              ),
            Semantics(
              key: const ValueKey('informacoes-busca'),
              container: true,
              button: true,
              label: 'Informações sobre a busca. $_orientacaoBusca',
              hint: 'Ative para abrir esta orientação.',
              onTap: _mostrarOrientacaoBusca,
              excludeSemantics: true,
              child: IconButton(
                tooltip: _orientacaoBusca,
                onPressed: _mostrarOrientacaoBusca,
                icon: const Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
      ),
    );
    final buscar = ElevatedButton.icon(
      onPressed: catalogo.buscando ? null : _buscar,
      icon: catalogo.buscando
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
                semanticsLabel: 'Buscando obra',
              ),
            )
          : const Icon(Icons.search),
      label: Text(catalogo.buscando ? 'Buscando...' : 'Buscar'),
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
                    SizedBox(height: 56, child: buscar),
                  ],
                );
              },
            ),
          ),
        ),
        if (catalogo.carregandoInicial && catalogo.obras.isNotEmpty)
          const SliverToBoxAdapter(
            child: IndicadorCarregamento(mensagem: 'Atualizando obras'),
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
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: catalogo.carregandoMais || catalogo.buscando
                      ? null
                      : catalogo.carregarMais,
                  icon: catalogo.carregandoMais
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                            semanticsLabel: 'Carregando mais obras',
                          ),
                        )
                      : const Icon(Icons.add, size: 16),
                  label: Text(
                    catalogo.carregandoMais ? 'Carregando...' : 'Carregar Mais',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
