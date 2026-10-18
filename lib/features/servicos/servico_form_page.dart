import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import 'servico.dart';
import 'servicos_repository.dart';

class ServicoFormPage extends ConsumerStatefulWidget {
  const ServicoFormPage({super.key, this.servico});

  /// null = criando; preenchido = editando.
  final Servico? servico;

  @override
  ConsumerState<ServicoFormPage> createState() => _ServicoFormPageState();
}

class _ServicoFormPageState extends ConsumerState<ServicoFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _precoCtrl;
  late final TextEditingController _duracaoCtrl;
  late final TextEditingController _descricaoCtrl;

  bool _carregando = false;
  String? _erro;

  bool get _editando => widget.servico != null;

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

    final s = widget.servico;

    _nomeCtrl = TextEditingController(text: s?.nome);

    _precoCtrl = TextEditingController(
      text: s == null ? '' : s.preco.toStringAsFixed(2).replaceAll('.', ','),
    );

    _duracaoCtrl = TextEditingController(
      text: (s?.duracaoMinutos ?? 30).toString(),
    );

    _descricaoCtrl = TextEditingController(text: s?.descricao);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _precoCtrl.dispose();
    _duracaoCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  /// Aceita "35,50" e "35.50".
  double? _lerPreco(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final descricao = _descricaoCtrl.text.trim();

    final dados = {
      'nome': _nomeCtrl.text.trim(),
      'preco': _lerPreco(_precoCtrl.text),
      'duracao_minutos': int.parse(_duracaoCtrl.text.trim()),
      'descricao': descricao.isEmpty ? null : descricao,
    };

    final repo = ref.read(servicosRepositoryProvider);

    try {
      if (_editando) {
        await repo.atualizar(widget.servico!.id, dados);
      } else {
        await repo.criar(dados);
      }

      ref.invalidate(servicosProvider);

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
    String? prefixo,
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
      prefixText: prefixo,
      prefixStyle: const TextStyle(
        fontSize: 14,
        color: _texto,
        fontWeight: FontWeight.w500,
      ),
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
          _editando ? 'Editar serviço' : 'Novo serviço',
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
                      // Cabeçalho do formulário
                      Text(
                        _editando
                            ? 'Informações do serviço'
                            : 'Cadastrar serviço',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: _texto,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _editando
                            ? 'Atualize os dados do serviço '
                                  'oferecido pela barbearia.'
                            : 'Defina as informações do serviço '
                                  'que será oferecido.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textoSecundario,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Nome do serviço
                      TextFormField(
                        controller: _nomeCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracaoCampo(
                          label: 'Nome do serviço *',
                          icone: Icons.content_cut_rounded,
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                            ? 'Informe o nome'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Preço
                      TextFormField(
                        controller: _precoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: _decoracaoCampo(
                          label: 'Preço *',
                          icone: Icons.payments_outlined,
                          prefixo: 'R\$ ',
                        ),
                        validator: (valor) {
                          final preco = _lerPreco(valor ?? '');

                          if (preco == null || preco <= 0) {
                            return 'Informe um preço maior que zero';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Duração
                      TextFormField(
                        controller: _duracaoCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracaoCampo(
                          label: 'Duração (minutos) *',
                          icone: Icons.schedule_rounded,
                        ),
                        validator: (valor) {
                          final minutos = int.tryParse((valor ?? '').trim());

                          if (minutos == null || minutos <= 0) {
                            return 'Informe a duração em minutos';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Descrição
                      TextFormField(
                        controller: _descricaoCtrl,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration: _decoracaoCampo(
                          label: 'Descrição',
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
