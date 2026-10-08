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

      final token = await repo.login(_emailCtrl.text.trim(), _senhaCtrl.text);
      // Guardar o token faz o router redirecionar para /clientes.
      ref.read(tokenProvider.notifier).definir(token);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BarberFlow',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 24),
                if (_modoRegistro) ...[
                  TextField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Seu nome'),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: _barbeariaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome da barbearia',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _senhaCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                ),
                const SizedBox(height: 16),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _erro!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                FilledButton(
                  onPressed: _carregando ? null : _enviar,
                  child: _carregando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_modoRegistro ? 'Criar conta' : 'Entrar'),
                ),
                TextButton(
                  onPressed: _carregando
                      ? null
                      : () => setState(() {
                          _modoRegistro = !_modoRegistro;
                          _erro = null;
                        }),

                  child: Text(
                    _modoRegistro
                        ? 'Ja tenho conta'
                        : 'Nao tenho conta, quero me cadastrar',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
