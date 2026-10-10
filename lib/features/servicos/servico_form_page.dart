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
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar serviço' : 'Novo serviço'),
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
                controller: _precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Preço (R\$) *'),
                validator: (valor) {
                  final preco = _lerPreco(valor ?? '');
                  if (preco == null || preco <= 0) {
                    return 'Informe um preço maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _duracaoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração (minutos) *',
                ),
                validator: (valor) {
                  final minutos = int.tryParse((valor ?? '').trim());
                  if (minutos == null || minutos <= 0) {
                    return 'Informe a duração em minutos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrição'),
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
