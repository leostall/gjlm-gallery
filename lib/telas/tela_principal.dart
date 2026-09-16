import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provedores/provedor_autenticacao.dart';
import '../widgets/barra_titulo.dart';
import '../widgets/estrutura_pagina.dart';
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
        scrollable: true,
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
            child: const Text('Cancelar', style: TextStyle(color: _vinho)),
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
    return EstruturaPagina(
      backgroundColor: _creme,

      // =========================================================
      // CABEÇALHO
      // =========================================================
      appBar: barraTitulo(
        context,
        titulo: 'GJLM Gallery',
        fundo: _creme,
        cor: _vinho,
        larguraAcoes: 74,
        acoes: [
          Container(
            width: 56,
            height: 56,
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
              icon: const Icon(Icons.logout_outlined, color: _vinho, size: 18),
            ),
          ),
        ],

        // friso decorativo em duas linhas, no estilo de uma placa clássica
        rodape: PreferredSize(
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
          TelaColecao(tipo: TipoColecao.favoritos),
          TelaColecao(tipo: TipoColecao.vistos),
        ],
      ),

      // =========================================================
      // MENU INFERIOR
      // =========================================================
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : Container(
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
              child: SafeArea(
                top: false,
                child: Material(
                  color: _creme,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _destino(0, 'Catálogo', Icons.grid_view_outlined),
                        _destino(1, 'Favoritos', Icons.favorite_border_rounded),
                        _destino(2, 'Vistas', Icons.visibility_outlined),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _destino(int indice, String rotulo, IconData icone) {
    final selecionado = indice == _indiceAtual;
    void selecionar() => setState(() => _indiceAtual = indice);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MediaQuery.sizeOf(context).width / 3,
      ),
      child: IntrinsicWidth(
        child: Semantics(
          container: true,
          button: true,
          selected: selecionado,
          label: rotulo,
          value: 'Aba ${indice + 1} de 3',
          onTap: selecionar,
          excludeSemantics: true,
          child: InkWell(
            onTap: selecionar,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selecionado ? _vinho : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icone,
                      size: 20,
                      color: selecionado ? _creme : _vinho,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rotulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selecionado
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _vinho,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
