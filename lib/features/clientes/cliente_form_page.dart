import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'cliente.dart';
import 'clientes_repository.dart';

class ClienteFormPage extends ConsumerStatefulWidget {
  const ClienteFormPage({super.key, this.cliente});

  /// null = criando um cliente novo; preenchido = editando.
  final Cliente? cliente;

  @override
  ConsumerState<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends ConsumerState<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _obsCtrl;

  bool _carregando = false;
  String? _erro;

  bool get _editando => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nomeCtrl = TextEditingController(text: c?.nome);
    _telefoneCtrl = TextEditingController(text: c?.telefone);
    _emailCtrl = TextEditingController(text: c?.email);
    _obsCtrl = TextEditingController(text: c?.observacoes);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  /// Campo vazio vira null, para a API limpar o valor.
  String? _valorOuNulo(String texto) {
    final valor = texto.trim();
    return valor.isEmpty ? null : valor;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final dados = {
      'nome': _nomeCtrl.text.trim(),
      'telefone': _valorOuNulo(_telefoneCtrl.text),
      'email': _valorOuNulo(_emailCtrl.text),
      'observacoes': _valorOuNulo(_obsCtrl.text),
    };

    final repo = ref.read(clientesRepositoryProvider);
    try {
      if (_editando) {
        await repo.atualizar(widget.cliente!.id, dados);
      } else {
        await repo.criar(dados);
      }
      ref.invalidate(clientesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar cliente' : 'Novo cliente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (valor) => (valor == null || valor.trim().isEmpty)
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observacoes'),
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
                onPressed: _carregando ? null : _salvar,
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
