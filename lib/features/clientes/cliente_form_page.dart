import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import 'cliente.dart';
import 'clientes_repository.dart';

class ClienteFormPage extends ConsumerStatefulWidget {
  const ClienteFormPage({super.key, this.cliente});

  /// null = novo cliente; preenchido = edição.
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

  // Design System BarberFlow
  static const Color _fundo = Color(0xFFF8F9FA);
  static const Color _superficie = Color(0xFFFFFFFF);
  static const Color _texto = Color(0xFF21262C);
  static const Color _textoSecundario = Color(0xFF737980);
  static const Color _destaque = Color(0xFFB38B5D);
  static const Color _borda = Color(0xFFE5E7EB);
  static const Color _erroCor = Color(0xFFC35D5B);

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

  /// Campo vazio vira null para a API limpar o valor.
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
    OutlineInputBorder criarBorda(Color cor, double largura) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: _textoSecundario),
      prefixIcon: Icon(icone, size: 20, color: _textoSecundario),
      filled: true,
      fillColor: _superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: criarBorda(_borda, 1),
      enabledBorder: criarBorda(_borda, 1),
      focusedBorder: criarBorda(_destaque, 1.5),
      errorBorder: criarBorda(_erroCor, 1),
      focusedErrorBorder: criarBorda(_erroCor, 1.5),
      errorStyle: const TextStyle(color: _erroCor, fontSize: 12),
    );
  }

  Widget _mensagemErro() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _erroCor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _erroCor, size: 20),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _erro!,
              style: const TextStyle(
                fontSize: 13,
                color: _erroCor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _texto),
        title: Text(
          _editando ? 'Editar cliente' : 'Novo cliente',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borda),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título do formulário
                      Text(
                        _editando
                            ? 'Informações do cliente'
                            : 'Cadastrar cliente',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: _texto,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _editando
                            ? 'Atualize os dados cadastrais '
                                  'do cliente.'
                            : 'Preencha os dados para adicionar '
                                  'um novo cliente.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textoSecundario,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Nome obrigatório
                      TextFormField(
                        controller: _nomeCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracaoCampo(
                          label: 'Nome *',
                          icone: Icons.person_outline_rounded,
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Telefone
                      TextFormField(
                        controller: _telefoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracaoCampo(
                          label: 'Telefone',
                          icone: Icons.phone_outlined,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // E-mail
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracaoCampo(
                          label: 'E-mail',
                          icone: Icons.mail_outline_rounded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Observações
                      TextFormField(
                        controller: _obsCtrl,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: _decoracaoCampo(
                          label: 'Observações',
                          icone: Icons.notes_rounded,
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (_erro != null) ...[
                        _mensagemErro(),
                        const SizedBox(height: 16),
                      ],

                      // Botão principal
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _carregando ? null : _salvar,
                          style: FilledButton.styleFrom(
                            backgroundColor: _destaque,
                            foregroundColor: _texto,
                            disabledBackgroundColor: _destaque.withValues(
                              alpha: 0.5,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: _carregando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _texto,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(_carregando ? 'Salvando...' : 'Salvar'),
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
    );
  }
}
