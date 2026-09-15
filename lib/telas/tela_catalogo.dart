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
  final _controladorBusca = TextEditingController();
  final _controladorScroll = ScrollController();

  bool _chegouAoFim = false;

  static const _vinho = Color(0xFF70263A);
  static const _creme = Color(0xFFF5F1E8);
  static const _texto = Color(0xFF302A25);
  static const _dourado = Color(0xFFB49763);

  @override
  void initState() {
    super.initState();

    _controladorScroll.addListener(_verificarFimDaLista);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProvedorCatalogo>().carregarInicial();
    });
  }

  void _verificarFimDaLista() {
    if (!_controladorScroll.hasClients) return;

    final posicao = _controladorScroll.position;

    final chegouAoFim =
        posicao.pixels >= posicao.maxScrollExtent - 30;

    if (chegouAoFim != _chegouAoFim) {
      setState(() {
        _chegouAoFim = chegouAoFim;
      });
    }
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    _controladorScroll.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();

    final provedor = context.read<ProvedorCatalogo>();

    final obra = await provedor.buscar(
      _controladorBusca.text,
    );

    if (!mounted) return;

    if (obra == null) {
      final mensagem = provedor.erro;

      if (mensagem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: _vinho,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      return;
    }

    _abrirDetalhes(obra);
  }

  void _abrirDetalhes(Obra obra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaDetalhesObra(
          obraInicial: obra,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<ProvedorCatalogo>();

    if (catalogo.carregandoInicial && catalogo.obras.isEmpty) {
      return const IndicadorCarregamento(
        mensagem: 'Buscando obras do acervo...',
      );
    }

    if (catalogo.erro != null && catalogo.obras.isEmpty) {
      return MensagemEstado(
        icone: Icons.cloud_off_outlined,
        titulo: 'Não foi possível carregar',
        mensagem: catalogo.erro!,
        rotuloAcao: 'Tentar novamente',
        aoAcionar: () => catalogo.carregarInicial(
          forcar: true,
        ),
      );
    }

    return Column(
      children: [
        // =========================================================
        // BARRA DE PESQUISA (compacta) + BOTÃO SEPARADO
        // =========================================================
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
          child: _CampoBusca(
            controller: _controladorBusca,
            buscando: catalogo.buscando,
            aoBuscar: _buscar,
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
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
                '${catalogo.obras.length} OBRAS NO ACERVO',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: _texto,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 0.8,
                  color: _dourado.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _dourado.withValues(alpha: 0.6),
                    width: 0.9,
                  ),
                ),
                child: const Icon(
                  Icons.tune,
                  size: 14,
                  color: _vinho,
                ),
              ),
            ],
          ),
        ),

        if (catalogo.erro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
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
                  const Icon(Icons.info_outline, size: 16, color: _vinho),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      catalogo.erro!,
                      style: const TextStyle(fontSize: 12.5, color: _texto),
                    ),
                  ),
                  TextButton(
                    onPressed: catalogo.limparErro,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(color: _vinho, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            color: _vinho,
            onRefresh: () => catalogo.carregarInicial(
              forcar: true,
            ),
            child: GradeObras(
              obras: catalogo.obras,
              aoSelecionar: _abrirDetalhes,
              controller: _controladorScroll,
            ),
          ),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _chegouAoFim
              ? Padding(
                  key: const ValueKey('carregar'),
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    4,
                    22,
                    12,
                  ),
                  child: _BotaoCarregarMais(
                    carregando: catalogo.carregandoMais,
                    possuiMais: catalogo.temProximaPagina,
                    aoTocar: catalogo.carregarMais,
                  ),
                )
              : const SizedBox(
                  key: ValueKey('vazio'),
                  height: 14,
                ),
        ),
      ],
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({
    required this.controller,
    required this.buscando,
    required this.aoBuscar,
  });

  final TextEditingController controller;
  final bool buscando;
  final VoidCallback aoBuscar;

  static const _vinho = Color(0xFF70263A);
  static const _dourado = Color(0xFFB49763);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de texto — agora compacto (42px de altura, cantos retos)
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => aoBuscar(),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Obra, artista ou período...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF4A433C),
                  size: 18,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.7),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _dourado.withValues(alpha: 0.55),
                    width: 0.8,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _vinho,
                    width: 1.2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Botão de pesquisar — separado, estilo "selo" vinho + borda dourada
        Semantics(
          button: true,
          label: 'Pesquisar',
          child: Material(
            color: _vinho,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: buscando ? null : aoBuscar,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dourado.withValues(alpha: 0.7),
                    width: 0.9,
                  ),
                ),
                alignment: Alignment.center,
                child: buscando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotaoCarregarMais extends StatelessWidget {
  const _BotaoCarregarMais({
    required this.carregando,
    required this.possuiMais,
    required this.aoTocar,
  });

  final bool carregando;
  final bool possuiMais;
  final VoidCallback aoTocar;

  static const vinho = Color(0xFF70263A);
  static const dourado = Color(0xFFB49763);

  @override
  Widget build(BuildContext context) {
    if (!possuiMais && !carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '· TODO O ACERVO FOI CARREGADO ·',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
            color: Color(0xFF82786C),
          ),
        ),
      );
    }

    return Center(
      child: OutlinedButton.icon(
        onPressed: carregando ? null : aoTocar,
        icon: carregando
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: vinho,
                ),
              )
            : const Icon(
                Icons.add,
                size: 16,
              ),
        label: Text(
          carregando ? 'Carregando...' : 'Carregar mais',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: vinho,
          side: const BorderSide(
            color: dourado,
            width: 0.9,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}