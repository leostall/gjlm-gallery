import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../configuracoes/tema_aplicativo.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProvedorCatalogo>().carregarInicial();
    });
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();
    final provedor = context.read<ProvedorCatalogo>();
    final obra = await provedor.buscar(_controladorBusca.text);
    if (!mounted) return;

    if (obra == null) {
      final mensagem = provedor.erro;
      if (mensagem != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagem)));
      }
      return;
    }

    _abrirDetalhes(obra);
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
        aoAcionar: () => catalogo.carregarInicial(forcar: true),
      );
    }

    return Column(
      children: [
        Container(
          color: CoresGaleria.vinho,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controladorBusca,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _buscar(),
                decoration: const InputDecoration(
                  hintText: 'Busque uma obra ou artista',
                  labelText: 'Buscar no acervo',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: catalogo.buscando ? null : _buscar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoresGaleria.dourado,
                  foregroundColor: CoresGaleria.vinhoEscuro,
                ),
                icon: catalogo.buscando
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Icon(Icons.search),
                label: Text(catalogo.buscando ? 'Buscando...' : 'Buscar'),
              ),
            ],
          ),
        ),
        if (catalogo.erro != null)
          MaterialBanner(
            content: Text(catalogo.erro!),
            actions: [
              TextButton(
                onPressed: catalogo.limparErro,
                child: const Text('Fechar'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => catalogo.carregarInicial(forcar: true),
            child: GradeObras(
              obras: catalogo.obras,
              aoSelecionar: _abrirDetalhes,
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: catalogo.carregandoMais || !catalogo.temProximaPagina
                  ? null
                  : catalogo.carregarMais,
              icon: catalogo.carregandoMais
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                catalogo.carregandoMais
                    ? 'Carregando...'
                    : catalogo.temProximaPagina
                    ? 'Carregar mais'
                    : 'Todo o acervo foi carregado',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
