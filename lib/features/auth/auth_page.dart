
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'auth_repository.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _nomeCtrl = TextEditingController();
  final _barbeariaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _modoRegistro = false;
  bool _carregando = false;
  String? _erro;

  // Paleta visual BarberFlow
  static const _fundo = Color(0xFFF8F9FA);
  static const _superficie = Color(0xFFFFFFFF);
  static const _texto = Color(0xFF21262C);
  static const _textoSecundario = Color(0xFF737980);
  static const _destaque = Color(0xFFB38B5D);
  static const _borda = Color(0xFFE5E7EB);
  static const _erroCor = Color(0xFFC35D5B);

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _barbeariaCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final repo = ref.read(authRepositoryProvider);

    try {
      if (_modoRegistro) {
        await repo.registrar(
          nome: _nomeCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          senha: _senhaCtrl.text,
          nomeBarbearia: _barbeariaCtrl.text.trim(),
        );
      }

      final token = await repo.login(
        _emailCtrl.text.trim(),
        _senhaCtrl.text,
      );

      // Mantém o redirecionamento original.
      ref.read(tokenProvider.notifier).definir(token);
    } catch (e) {
      if (mounted) {
        setState(() => _erro = mensagemDeErro(e));
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _textoSecundario,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icone,
        size: 20,
        color: _textoSecundario,
      ),
      filled: true,
      fillColor: _superficie,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _destaque,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Identidade visual
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _destaque.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        size: 30,
                        color: _destaque,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'BarberFlow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: _texto,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _modoRegistro
                        ? 'Crie sua conta para começar'
                        : 'Bem-vindo de volta',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _textoSecundario,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Formulário
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _superficie,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _borda),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _modoRegistro
                              ? 'Criar conta'
                              : 'Acessar conta',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: _texto,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _modoRegistro
                              ? 'Preencha os dados abaixo.'
                              : 'Informe suas credenciais.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textoSecundario,
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (_modoRegistro) ...[
                          TextField(
                            controller: _nomeCtrl,
                            textCapitalization:
                                TextCapitalization.words,
                            decoration: _decoracaoCampo(
                              label: 'Seu nome',
                              icone: Icons.person_outline_rounded,
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: _barbeariaCtrl,
                            decoration: _decoracaoCampo(
                              label: 'Nome da barbearia',
                              icone: Icons.storefront_outlined,
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],

                        TextField(
                          controller: _emailCtrl,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: _decoracaoCampo(
                            label: 'E-mail',
                            icone: Icons.mail_outline_rounded,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _senhaCtrl,
                          obscureText: true,
                          decoration: _decoracaoCampo(
                            label: 'Senha',
                            icone: Icons.lock_outline_rounded,
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_erro != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _erroCor.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: _erroCor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _erro!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _erroCor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed:
                                _carregando ? null : _enviar,
                            style: FilledButton.styleFrom(
                              backgroundColor: _destaque,
                              foregroundColor: _texto,
                              disabledBackgroundColor:
                                  _destaque.withValues(
                                    alpha: 0.5,
                                  ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: _carregando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _texto,
                                    ),
                                  )
                                : Text(
                                    _modoRegistro
                                        ? 'Criar conta'
                                        : 'Entrar',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: _carregando
                        ? null
                        : () => setState(() {
                            _modoRegistro = !_modoRegistro;
                            _erro = null;
                          }),
                    style: TextButton.styleFrom(
                      foregroundColor: _destaque,
                      padding: const EdgeInsets.all(12),
                    ),
                    child: Text(
                      _modoRegistro
                          ? 'Já tenho conta'
                          : 'Não tenho conta, quero me cadastrar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

