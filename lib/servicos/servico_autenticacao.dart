import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/usuario_sessao.dart';
import 'servico_persistencia_local.dart';

class ServicoAutenticacao {
  ServicoAutenticacao(
    this._persistenciaLocal, {
    required this.firebaseAtivo,
  });

  final bool firebaseAtivo;
  final ServicoPersistenciaLocal _persistenciaLocal;

  static const _chaveContaLocal = 'gjlm_conta_local';
  static const _chaveSessaoLocal = 'gjlm_sessao_local';

  Future<UsuarioSessao?> recuperarSessao() async {
    if (firebaseAtivo) {
      final usuario = FirebaseAuth.instance.currentUser;
      return usuario == null ? null : _converterUsuarioFirebase(usuario);
    }

    if (!_persistenciaLocal.lerBooleano(_chaveSessaoLocal)) return null;
    final conta = _lerContaLocal();
    return conta == null ? null : _usuarioDaContaLocal(conta);
  }

  Future<UsuarioSessao> entrar({
    required String email,
    required String senha,
  }) async {
    final emailNormalizado = email.trim().toLowerCase();

    if (firebaseAtivo) {
      try {
        final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailNormalizado,
          password: senha,
        );
        return _converterUsuarioFirebase(credencial.user!);
      } on FirebaseAuthException catch (erro) {
        throw ExcecaoAutenticacao(_mensagemFirebase(erro.code));
      }
    }

    final conta = _lerContaLocal();
    if (conta == null || conta['email'] != emailNormalizado) {
      throw const ExcecaoAutenticacao('Conta não encontrada. Faça seu cadastro.');
    }

    final hashInformado = _gerarHash(senha, conta['sal'] as String);
    if (hashInformado != conta['hashSenha']) {
      throw const ExcecaoAutenticacao('E-mail ou senha incorretos.');
    }

    await _persistenciaLocal.salvarBooleano(_chaveSessaoLocal, true);
    return _usuarioDaContaLocal(conta);
  }

  Future<UsuarioSessao> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final nomeNormalizado = nome.trim();
    final emailNormalizado = email.trim().toLowerCase();

    if (firebaseAtivo) {
      try {
        final credencial = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailNormalizado,
          password: senha,
        );
        await credencial.user!.updateDisplayName(nomeNormalizado);
        await credencial.user!.reload();
        return _converterUsuarioFirebase(
          FirebaseAuth.instance.currentUser ?? credencial.user!,
        );
      } on FirebaseAuthException catch (erro) {
        throw ExcecaoAutenticacao(_mensagemFirebase(erro.code));
      }
    }

    final geradorSeguro = Random.secure();
    final sal = base64UrlEncode(
      List<int>.generate(16, (_) => geradorSeguro.nextInt(256)),
    );
    final id = sha256.convert(utf8.encode(emailNormalizado)).toString();
    final conta = <String, dynamic>{
      'id': id,
      'nome': nomeNormalizado,
      'email': emailNormalizado,
      'sal': sal,
      'hashSenha': _gerarHash(senha, sal),
    };

    await _persistenciaLocal.salvarTexto(_chaveContaLocal, jsonEncode(conta));
    await _persistenciaLocal.salvarBooleano(_chaveSessaoLocal, true);
    return _usuarioDaContaLocal(conta);
  }

  Future<void> sair() async {
    if (firebaseAtivo) {
      await FirebaseAuth.instance.signOut();
      return;
    }
    await _persistenciaLocal.salvarBooleano(_chaveSessaoLocal, false);
  }

  Map<String, dynamic>? _lerContaLocal() {
    final conteudo = _persistenciaLocal.lerTexto(_chaveContaLocal);
    if (conteudo == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(conteudo) as Map);
    } catch (_) {
      return null;
    }
  }

  UsuarioSessao _usuarioDaContaLocal(Map<String, dynamic> conta) {
    return UsuarioSessao(
      id: conta['id'] as String,
      email: conta['email'] as String,
      nome: conta['nome'] as String,
    );
  }

  UsuarioSessao _converterUsuarioFirebase(User usuario) {
    final email = usuario.email ?? '';
    final nome = usuario.displayName?.trim();
    return UsuarioSessao(
      id: usuario.uid,
      email: email,
      nome: nome == null || nome.isEmpty ? email.split('@').first : nome,
    );
  }

  String _gerarHash(String senha, String sal) =>
      sha256.convert(utf8.encode('$sal:$senha')).toString();

  String _mensagemFirebase(String codigo) {
    if ({
      'user-not-found',
      'wrong-password',
      'invalid-credential',
    }.contains(codigo)) {
      return 'E-mail ou senha incorretos.';
    }

    return switch (codigo) {
      'email-already-in-use' => 'Este e-mail já está cadastrado.',
      'invalid-email' => 'Digite um e-mail válido.',
      'weak-password' => 'A senha precisa ter pelo menos 6 caracteres.',
      'user-disabled' => 'Esta conta foi desativada.',
      'network-request-failed' =>
        'Sem conexão. Verifique sua internet e tente novamente.',
      _ => 'Não foi possível autenticar. Tente novamente.',
    };
  }
}

class ExcecaoAutenticacao implements Exception {
  const ExcecaoAutenticacao(this.mensagem);

  final String mensagem;
}
