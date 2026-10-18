import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatacao.dart';
import 'financeiro_repository.dart';

class MovimentacaoFormPage extends ConsumerStatefulWidget {
  const MovimentacaoFormPage({super.key});

  @override
  ConsumerState<MovimentacaoFormPage> createState() =>
      _MovimentacaoFormPageState();
}

class _MovimentacaoFormPageState extends ConsumerState<MovimentacaoFormPage> {
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  String _tipo = 'despesa';
  int? _categoriaId;
  DateTime _data = DateTime.now();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  /// Aceita "35,50" e "35.50".
  double? _lerValor(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _novaCategoria() async {
    final controlador = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Nova categoria de ${_tipo == 'despesa' ? 'despesa' : 'receita'}',
        ),
        content: TextField(
          controller: controlador,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controlador.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (nome == null || nome.isEmpty) return;

    try {
      final categoria = await ref
          .read(financeiroRepositoryProvider)
          .criarCategoria(nome, _tipo);
      ref.invalidate(categoriasProvider);
      await ref.read(categoriasProvider.future);
      if (mounted) setState(() => _categoriaId = categoria.id);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  Future<void> _salvar() async {
    final valor = _lerValor(_valorCtrl.text);
    if (_categoriaId == null) {
      setState(() => _erro = 'Selecione a categoria');
      return;
    }
    if (valor == null || valor <= 0) {
      setState(() => _erro = 'Informe um valor maior que zero');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final descricao = _descricaoCtrl.text.trim();
    final dados = {
      'tipo': _tipo,
      'categoria_id': _categoriaId,
      'descricao': descricao.isEmpty ? null : descricao,
      'valor': valor,
      'data': formatarDataIso(_data),
    };

    try {
      await ref.read(financeiroRepositoryProvider).criarMovimentacao(dados);
      // Mostra o mês do lançamento ao voltar.
      ref.read(mesSelecionadoProvider.notifier).definir(_data);
      ref.invalidate(movimentacoesDoMesProvider);
      ref.invalidate(resumoDoMesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todas = ref.watch(categoriasProvider).asData?.value ?? [];
    final categorias = todas.where((c) => c.tipo == _tipo).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Novo lançamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'despesa',
                  label: Text('Despesa'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: 'receita',
                  label: Text('Receita'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (escolha) => setState(() {
                _tipo = escolha.first;
                _categoriaId = null; // categoria é de um tipo só
              }),
            ),
            const SizedBox(height: 16),
            DropdownMenu<int>(
              // A chave força recriar o campo quando muda o tipo ou a seleção.
              key: ValueKey('$_tipo-$_categoriaId'),
              label: const Text('Categoria *'),
              expandedInsets: EdgeInsets.zero,
              initialSelection: _categoriaId,
              dropdownMenuEntries: [
                for (final c in categorias)
                  DropdownMenuEntry(value: c.id, label: c.nome),
              ],
              onSelected: (valor) => setState(() => _categoriaId = valor),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _novaCategoria,
                icon: const Icon(Icons.add),
                label: const Text('Nova categoria'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Valor (R\$) *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _escolherData,
              icon: const Icon(Icons.calendar_today),
              label: Text(formatarData(_data)),
            ),
            const SizedBox(height: 16),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    );
  }
}
