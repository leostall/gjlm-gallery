import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'aplicativo.dart';
import 'configuracoes/inicializador_firebase.dart';
import 'provedores/provedor_autenticacao.dart';
import 'provedores/provedor_catalogo.dart';
import 'provedores/provedor_colecao.dart';
import 'servicos/servico_art_institute.dart';
import 'servicos/servico_autenticacao.dart';
import 'servicos/servico_persistencia_local.dart';
import 'servicos/servico_sincronizacao_nuvem.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseAtivo = await InicializadorFirebase.inicializar();
  final preferencias = await SharedPreferences.getInstance();
  final persistenciaLocal = ServicoPersistenciaLocal(preferencias);
  final autenticacao = ServicoAutenticacao(
    persistenciaLocal,
    firebaseAtivo: firebaseAtivo,
  );
  final sincronizacaoNuvem = ServicoSincronizacaoNuvem(
    firebaseAtivo: firebaseAtivo,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProvedorAutenticacao(autenticacao)..inicializar(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProvedorCatalogo(ServicoArtInstitute()),
        ),
        ChangeNotifierProxyProvider<ProvedorAutenticacao, ProvedorColecao>(
          create: (_) => ProvedorColecao(
            persistenciaLocal,
            sincronizacaoNuvem,
          ),
          update: (_, autenticacao, colecao) {
            final provedor = colecao ??
                ProvedorColecao(
                  persistenciaLocal,
                  sincronizacaoNuvem,
                );
            provedor.atualizarUsuario(autenticacao.usuario?.id);
            return provedor;
          },
        ),
      ],
      child: AplicativoGaleria(firebaseAtivo: firebaseAtivo),
    ),
  );
}
