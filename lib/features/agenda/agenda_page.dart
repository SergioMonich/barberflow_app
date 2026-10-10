import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/formatacao.dart';
import '../clientes/clientes_repository.dart';
import '../servicos/servicos_repository.dart';
import 'agendamento.dart';
import 'agendamentos_repository.dart';

class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  Future<bool> _confirmar(
    BuildContext context,
    String titulo,
    String texto,
  ) async {
    final resposta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return resposta == true;
  }

  Future<void> _mudarStatus(
    BuildContext context,
    WidgetRef ref,
    Agendamento ag,
    String novoStatus,
  ) async {
    // "Confirmado" é só um aviso; os demais têm consequências, então pedem confirmação.
    if (novoStatus != 'confirmado') {
      final ok = await _confirmar(
        context,
        rotuloDoStatus(novoStatus),
        novoStatus == 'concluido'
            ? 'Marcar como concluído? A receita será lançada no financeiro '
                'e o status não poderá mais mudar.'
            : 'Marcar como "${rotuloDoStatus(novoStatus)}"? '
                'O status não poderá mais mudar.',
      );
      if (!ok) return;
    }

    try {
      await ref
          .read(agendamentosRepositoryProvider)
          .alterarStatus(ag.id, novoStatus);
      ref.invalidate(agendamentosDoDiaProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemDeErro(e))),
        );
      }
    }
  }

  Future<void> _escolherDia(BuildContext context, WidgetRef ref) async {
    final atual = ref.read(diaSelecionadoProvider);
    final escolhido = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (escolhido != null) {
      ref.read(diaSelecionadoProvider.notifier).definir(escolhido);
    }
  }

  Color _corDoStatus(String status) {
    switch (status) {
      case 'confirmado':
        return Colors.blue;
      case 'concluido':
        return Colors.green;
      case 'cancelado':
        return Colors.grey;
      case 'nao_compareceu':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dia = ref.watch(diaSelecionadoProvider);
    final agendamentos = ref.watch(agendamentosDoDiaProvider);

    // Para mostrar nomes em vez de números. Se ainda não carregou (ou o
    // serviço foi desativado), cai no texto padrão.
    final clientes = {
      for (final c in ref.watch(clientesProvider).asData?.value ?? [])
        c.id: c.nome,
    };
    final servicos = {
      for (final s in ref.watch(servicosProvider).asData?.value ?? [])
        s.id: s.nome,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            tooltip: 'Clientes',
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/clientes'),
          ),
          IconButton(
            tooltip: 'Serviços',
            icon: const Icon(Icons.content_cut),
            onPressed: () => context.push('/servicos'),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(tokenProvider.notifier).definir(null),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/agenda/novo'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Dia anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref
                      .read(diaSelecionadoProvider.notifier)
                      .definir(DateTime(dia.year, dia.month, dia.day - 1)),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _escolherDia(context, ref),
                    child: Text(
                      rotuloDia(dia),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo dia',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref
                      .read(diaSelecionadoProvider.notifier)
                      .definir(DateTime(dia.year, dia.month, dia.day + 1)),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(diaSelecionadoProvider.notifier)
                      .definir(DateTime.now()),
                  child: const Text('Hoje'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: agendamentos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (erro, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mensagemDeErro(erro)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(agendamentosDoDiaProvider),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (lista) {
                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Nenhum agendamento neste dia.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(agendamentosDoDiaProvider);
                    await ref.read(agendamentosDoDiaProvider.future);
                  },
                  child: ListView.separated(
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, indice) {
                      final ag = lista[indice];
                      final cliente =
                          clientes[ag.clienteId] ?? 'Cliente #${ag.clienteId}';
                      final servico =
                          servicos[ag.servicoId] ?? 'Serviço #${ag.servicoId}';
                      final proximos = ag.proximosStatus;
                      return ListTile(
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$servico · ${formatarDinheiro(ag.valor)}'),
                            Text(
                              ag.statusRotulo,
                              style: TextStyle(
                                color: _corDoStatus(ag.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (ag.observacoes != null &&
                                ag.observacoes!.isNotEmpty)
                              Text(
                                ag.observacoes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: proximos.isEmpty
                            ? null
                            : PopupMenuButton<String>(
                                tooltip: 'Alterar status',
                                onSelected: (novo) =>
                                    _mudarStatus(context, ref, ag, novo),
                                itemBuilder: (_) => [
                                  for (final s in proximos)
                                    PopupMenuItem(
                                      value: s,
                                      child: Text(rotuloDoStatus(s)),
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