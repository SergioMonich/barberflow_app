import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatacao.dart';
import 'financeiro_repository.dart';
import 'movimentacao.dart';

class FinanceiroPage extends ConsumerWidget {
  const FinanceiroPage({super.key});

  Future<void> _excluir(
    BuildContext context,
    WidgetRef ref,
    Movimentacao mov,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lançamento'),
        content: Text(
          'Excluir ${mov.ehReceita ? 'a receita' : 'a despesa'} '
          'de ${formatarDinheiro(mov.valor)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await ref.read(financeiroRepositoryProvider).excluirMovimentacao(mov.id);
      ref.invalidate(movimentacoesDoMesProvider);
      ref.invalidate(resumoDoMesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemDeErro(e))));
      }
    }
  }

  Widget _cartaoResumo(
    BuildContext context,
    String titulo,
    double valor,
    Color cor,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatarDinheiro(valor),
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSelecionadoProvider);
    final resumo = ref.watch(resumoDoMesProvider);
    final movimentacoes = ref.watch(movimentacoesDoMesProvider);
    final categorias = {
      for (final c in ref.watch(categoriasProvider).asData?.value ?? [])
        c.id: c.nome,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/financeiro/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Lançamento'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Mês anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref
                      .read(mesSelecionadoProvider.notifier)
                      .definir(DateTime(mes.year, mes.month - 1)),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      rotuloMes(mes),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo mês',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref
                      .read(mesSelecionadoProvider.notifier)
                      .definir(DateTime(mes.year, mes.month + 1)),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(mesSelecionadoProvider.notifier)
                      .definir(DateTime.now()),
                  child: const Text('Este mês'),
                ),
              ],
            ),
          ),
          resumo.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (erro, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(mensagemDeErro(erro)),
            ),
            data: (r) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _cartaoResumo(context, 'Receitas', r.receitas, Colors.green),
                  _cartaoResumo(context, 'Despesas', r.despesas, Colors.red),
                  _cartaoResumo(
                    context,
                    'Saldo',
                    r.saldo,
                    r.saldo >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: movimentacoes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (erro, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mensagemDeErro(erro)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        ref.invalidate(movimentacoesDoMesProvider);
                        ref.invalidate(resumoDoMesProvider);
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (lista) {
                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Nenhum lançamento neste mês.'),
                  );
                }
                // Mais recentes primeiro.
                final ordenada = lista.reversed.toList();
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(movimentacoesDoMesProvider);
                    ref.invalidate(resumoDoMesProvider);
                    await ref.read(movimentacoesDoMesProvider.future);
                  },
                  child: ListView.separated(
                    itemCount: ordenada.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, indice) {
                      final mov = ordenada[indice];
                      final cor = mov.ehReceita ? Colors.green : Colors.red;
                      final categoria =
                          categorias[mov.categoriaId] ?? 'Sem categoria';
                      return ListTile(
                        leading: Icon(
                          mov.ehReceita
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: cor,
                        ),
                        title: Text(mov.descricao ?? categoria),
                        subtitle: Text(
                          mov.descricao == null
                              ? formatarData(mov.data)
                              : '${formatarData(mov.data)} · $categoria',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${mov.ehReceita ? '+' : '-'} '
                              '${formatarDinheiro(mov.valor)}',
                              style: TextStyle(
                                color: cor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (mov.geradaPorAtendimento)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Tooltip(
                                  message: 'Gerada por um atendimento',
                                  child: Icon(Icons.event_available, size: 20),
                                ),
                              )
                            else
                              IconButton(
                                tooltip: 'Excluir',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _excluir(context, ref, mov),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
