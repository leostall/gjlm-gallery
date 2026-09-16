import 'package:flutter/material.dart';

/// Quando falta altura, permite rolar o cabeçalho para alcançar o conteúdo.
class EstruturaPagina extends StatelessWidget {
  const EstruturaPagina({
    super.key,
    required this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  final AppBar appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    bottomNavigationBar: bottomNavigationBar,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, limites) {
          final cabecalho = SizedBox(
            height: appBar.preferredSize.height,
            child: appBar,
          );
          if (limites.maxHeight - appBar.preferredSize.height >= 240) {
            return Column(
              children: [
                cabecalho,
                Expanded(child: body),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                cabecalho,
                SizedBox(height: limites.maxHeight, child: body),
              ],
            ),
          );
        },
      ),
    ),
  );
}
