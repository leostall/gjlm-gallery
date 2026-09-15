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

  static const _vinho = Color(0xFF70263A);
  static const _creme = Color(0xFFF5F1E8);
  static const _dourado = Color(0xFFB49763);

  Future<void> _confirmarSaida() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _creme,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: _dourado, width: 0.8),
        ),
        title: const Text(
          'Sair da conta?',
          style: TextStyle(
            color: _vinho,
            fontWeight: FontWeight.w600,
            fontFamily: 'Georgia',
          ),
        ),
        content: const Text(
          'Você precisará entrar novamente para acessar a galeria.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _vinho),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _vinho,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
      backgroundColor: _creme,

      // =========================================================
      // CABEÇALHO
      // =========================================================

      appBar: AppBar(
        backgroundColor: _creme,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 92,
        titleSpacing: 22,

        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 42,
              color: _dourado,
              margin: const EdgeInsets.only(right: 14),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GJLM',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5,
                    color: _dourado,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'GALLERY',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                    color: _vinho,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _dourado.withValues(alpha: 0.55),
                width: 0.9,
              ),
            ),
            child: IconButton(
              tooltip: 'Sair da conta',
              padding: EdgeInsets.zero,
              onPressed: _confirmarSaida,
              icon: const Icon(
                Icons.logout_outlined,
                color: _vinho,
                size: 18,
              ),
            ),
          ),
        ],

        // friso decorativo em duas linhas, no estilo de uma placa clássica
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Column(
            children: [
              Container(height: 1.4, color: _dourado.withValues(alpha: 0.75)),
              const SizedBox(height: 2),
              Container(height: 0.6, color: _dourado.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),

      // =========================================================
      // CONTEÚDO
      // =========================================================

      body: IndexedStack(
        index: _indiceAtual,
        children: const [
          TelaCatalogo(),
          TelaColecao(
            tipo: TipoColecao.favoritos,
          ),
          TelaColecao(
            tipo: TipoColecao.vistos,
          ),
        ],
      ),

      // =========================================================
      // MENU INFERIOR
      // =========================================================

      bottomNavigationBar: Container(
        height: 68,
        decoration: BoxDecoration(
          color: _creme,
          border: Border(
            top: BorderSide(
              color: _dourado.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: _vinho.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 67,
          backgroundColor: _creme,
          elevation: 0,
          selectedIndex: _indiceAtual,

          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,

          indicatorColor: _vinho,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selecionado = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
              color: selecionado ? _vinho : _vinho.withValues(alpha: 0.65),
            );
          }),

          onDestinationSelected: (indice) {
            setState(() {
              _indiceAtual = indice;
            });
          },

          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.grid_view_outlined,
                size: 19,
                color: _vinho,
              ),
              selectedIcon: Icon(
                Icons.grid_view_rounded,
                size: 19,
                color: _creme,
              ),
              label: 'Catálogo',
            ),

            NavigationDestination(
              icon: Icon(
                Icons.favorite_border_rounded,
                size: 19,
                color: _vinho,
              ),
              selectedIcon: Icon(
                Icons.favorite_rounded,
                size: 19,
                color: _creme,
              ),
              label: 'Favoritos',
            ),

            NavigationDestination(
              icon: Icon(
                Icons.visibility_outlined,
                size: 19,
                color: _vinho,
              ),
              selectedIcon: Icon(
                Icons.visibility_rounded,
                size: 19,
                color: _creme,
              ),
              label: 'Vistas',
            ),
          ],
        ),
      ),
    );
  }
}