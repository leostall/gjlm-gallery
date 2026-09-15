import 'package:flutter/foundation.dart';

import '../modelos/usuario_sessao.dart';
import '../servicos/servico_autenticacao.dart';

class ProvedorAutenticacao extends ChangeNotifier {
  ProvedorAutenticacao(this._servico);

  final ServicoAutenticacao _servico;

  UsuarioSessao? _usuario;
  bool _carregando = false;
  bool _inicializado = false;
  String? _erro;

  UsuarioSessao? get usuario => _usuario;
  bool get carregando => _carregando;
  bool get inicializado => _inicializado;
  bool get firebaseAtivo => _servico.firebaseAtivo;
  String? get erro => _erro;

  Future<void> inicializar() async {
    try {
      _usuario = await _servico.recuperarSessao();
    } finally {
      _inicializado = true;
      notifyListeners();
    }
  }

  Future<bool> entrar({required String email, required String senha}) async {
    return _executar(() => _servico.entrar(email: email, senha: senha));
  }

  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    return _executar(
      () => _servico.cadastrar(nome: nome, email: email, senha: senha),
    );
  }

  Future<void> sair() async {
    _carregando = true;
    notifyListeners();
    try {
      await _servico.sair();
      _usuario = null;
      _erro = null;
    } catch (_) {
      _erro = 'Não foi possível sair da conta. Tente novamente.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void limparErro() {
    if (_erro == null) return;
    _erro = null;
    notifyListeners();
  }

  Future<bool> _executar(Future<UsuarioSessao> Function() acao) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _usuario = await acao();
      return true;
    } on ExcecaoAutenticacao catch (erro) {
      _erro = erro.mensagem;
      return false;
    } catch (_) {
      _erro = 'Ocorreu um erro inesperado. Tente novamente.';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
