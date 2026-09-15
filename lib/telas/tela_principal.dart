import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provedores/provedor_autenticacao.dart';
import 'tela_catalogo.dart';
import 'tela_colecao.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indiceAtual = 0;

  static const _titulos = ['Descobrir', 'Favoritos', 'Obras vistas'];

  Future<void> _confirmarSaida() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará entrar novamente para acessar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await context.read<ProvedorAutenticacao>().sair();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indiceAtual]),
        actions: [
          IconButton(
            onPressed: _confirmarSaida,
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _indiceAtual,
        children: const [
          TelaCatalogo(),
          TelaColecao(tipo: TipoColecao.favoritos),
          TelaColecao(tipo: TipoColecao.vistos),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAtual,
        onDestinationSelected: (indice) {
          setState(() => _indiceAtual = indice);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.visibility_outlined),
            selectedIcon: Icon(Icons.visibility),
            label: 'Vistas',
          ),
        ],
      ),
    );
  }
}
