import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

abstract final class InicializadorFirebase {
  static Future<bool> inicializar() async {
    try {
      final opcoes = DefaultFirebaseOptions.currentPlatform;

      // O arquivo de exemplo permite executar o modo local antes da configuração.
      if (opcoes.projectId == 'configure-o-firebase') {
        return false;
      }

      await Firebase.initializeApp(options: opcoes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
