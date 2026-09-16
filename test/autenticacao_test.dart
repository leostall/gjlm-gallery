import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gjlm_gallery/servicos/servico_autenticacao.dart';
import 'package:gjlm_gallery/servicos/servico_persistencia_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'login local exige cadastro, valida senha e restaura sessão após reinício',
    () async {
      SharedPreferences.setMockInitialValues({});
      final local = ServicoPersistenciaLocal(
        await SharedPreferences.getInstance(),
      );
      final servico = ServicoAutenticacao(local, firebaseAtivo: false);
      expect(await servico.recuperarSessao(), isNull);
      await expectLater(
        servico.entrar(email: 'teste@example.com', senha: '123456'),
        throwsA(isA<ExcecaoAutenticacao>()),
      );
      final usuario = await servico.cadastrar(
        nome: 'Teste',
        email: 'teste@example.com',
        senha: '123456',
      );
      await servico.sair();
      expect(await servico.recuperarSessao(), isNull);
      await expectLater(
        servico.entrar(email: 'teste@example.com', senha: 'errada'),
        throwsA(isA<ExcecaoAutenticacao>()),
      );
      await servico.entrar(email: 'teste@example.com', senha: '123456');
      final novo = ServicoAutenticacao(local, firebaseAtivo: false);
      expect((await novo.recuperarSessao())?.id, usuario.id);
    },
  );
}
