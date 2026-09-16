import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../configuracoes/tema_aplicativo.dart';
import '../provedores/provedor_autenticacao.dart';
import '../widgets/campo_rotulado.dart';

class TelaAutenticacao extends StatefulWidget {
  const TelaAutenticacao({super.key, required this.firebaseAtivo});

  final bool firebaseAtivo;

  @override
  State<TelaAutenticacao> createState() => _TelaAutenticacaoState();
}

class _TelaAutenticacaoState extends State<TelaAutenticacao> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  final _controladorConfirmacao = TextEditingController();

  bool _modoCadastro = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirmacao.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_chaveFormulario.currentState?.validate() ?? false)) return;

    final provedor = context.read<ProvedorAutenticacao>();
    if (provedor.carregando) return;
    if (_modoCadastro) {
      await provedor.cadastrar(
        nome: _controladorNome.text,
        email: _controladorEmail.text,
        senha: _controladorSenha.text,
      );
    } else {
      await provedor.entrar(
        email: _controladorEmail.text,
        senha: _controladorSenha.text,
      );
    }
  }

  void _alternarModo() {
    context.read<ProvedorAutenticacao>().limparErro();
    setState(() {
      _modoCadastro = !_modoCadastro;
      _controladorConfirmacao.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ProvedorAutenticacao>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _chaveFormulario,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          label: 'Logotipo da GJLM Gallery',
                          child: ExcludeSemantics(
                            child: const Icon(
                              Icons.museum_outlined,
                              size: 64,
                              color: CoresGaleria.vinho,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'GJLM Gallery',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _modoCadastro
                              ? 'Crie sua conta para começar a explorar.'
                              : 'Entre para acessar sua coleção de arte.',
                          textAlign: TextAlign.center,
                        ),
                        if (!widget.firebaseAtivo) ...[
                          const SizedBox(height: 16),
                          const _AvisoModoLocal(),
                        ],
                        const SizedBox(height: 24),
                        if (_modoCadastro) ...[
                          CampoRotulado(
                            rotulo: 'Nome',
                            child: TextFormField(
                              controller: _controladorNome,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().length < 2) {
                                  return 'Informe seu nome.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        CampoRotulado(
                          rotulo: 'E-mail',
                          child: TextFormField(
                            controller: _controladorEmail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (valor) {
                              final email = valor?.trim() ?? '';
                              if (!email.contains('@') ||
                                  !email.contains('.')) {
                                return 'Digite um e-mail válido.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        CampoRotulado(
                          rotulo: 'Senha',
                          child: TextFormField(
                            controller: _controladorSenha,
                            obscureText: _ocultarSenha,
                            textInputAction: _modoCadastro
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: _modoCadastro
                                ? const [AutofillHints.newPassword]
                                : const [AutofillHints.password],
                            onFieldSubmitted: (_) {
                              if (!_modoCadastro) _enviar();
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _ocultarSenha
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: () => setState(
                                  () => _ocultarSenha = !_ocultarSenha,
                                ),
                                icon: Icon(
                                  _ocultarSenha
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (valor) {
                              if (valor == null || valor.length < 6) {
                                return 'Use pelo menos 6 caracteres.';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_modoCadastro) ...[
                          const SizedBox(height: 14),
                          CampoRotulado(
                            rotulo: 'Confirmar senha',
                            child: TextFormField(
                              controller: _controladorConfirmacao,
                              obscureText: _ocultarSenha,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _enviar(),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock_reset_outlined),
                              ),
                              validator: (valor) {
                                if (valor != _controladorSenha.text) {
                                  return 'As senhas não são iguais.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                        if (autenticacao.erro != null) ...[
                          const SizedBox(height: 14),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              autenticacao.erro!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: autenticacao.carregando ? null : _enviar,
                          child: autenticacao.carregando
                              ? const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    semanticsLabel: 'Autenticando',
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_modoCadastro ? 'Criar conta' : 'Entrar'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: autenticacao.carregando
                              ? null
                              : _alternarModo,
                          child: Text(
                            _modoCadastro
                                ? 'Já tenho uma conta'
                                : 'Ainda não tenho uma conta',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoModoLocal extends StatelessWidget {
  const _AvisoModoLocal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CoresGaleria.cremeEscuro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, semanticLabel: 'Modo local'),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo local: sua conta e suas obras são salvas somente neste aparelho.',
            ),
          ),
        ],
      ),
    );
  }
}
