import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gjlm_gallery/modelos/obra.dart';
import 'package:gjlm_gallery/provedores/provedor_colecao.dart';
import 'package:gjlm_gallery/servicos/servico_persistencia_local.dart';
import 'package:gjlm_gallery/servicos/servico_sincronizacao_nuvem.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('favoritos permanecem no armazenamento local', () async {
    SharedPreferences.setMockInitialValues({});
    final preferencias = await SharedPreferences.getInstance();
    final persistencia = ServicoPersistenciaLocal(preferencias);
    const nuvem = ServicoSincronizacaoNuvem(firebaseAtivo: false);
    const obra = Obra(id: 7, titulo: 'Obra persistida');

    final primeiro = ProvedorColecao(persistencia, nuvem);
    primeiro.atualizarUsuario('usuario-1');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await primeiro.alternarFavorito(obra);

    final segundo = ProvedorColecao(persistencia, nuvem);
    segundo.atualizarUsuario('usuario-1');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(segundo.ehFavorito(7), isTrue);
    expect(segundo.favoritos.single.titulo, 'Obra persistida');
  });
}
