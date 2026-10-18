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

  // Identidade visual BarberFlow
  static const Color _fundo = Color(0xFFF8F9FA);
  static const Color _superficie = Color(0xFFFFFFFF);
  static const Color _texto = Color(0xFF21262C);
  static const Color _textoSecundario = Color(0xFF737980);
  static const Color _destaque = Color(0xFFB38B5D);
  static const Color _borda = Color(0xFFE5E7EB);
  static const Color _receita = Color(0xFF27856B);
  static const Color _despesa = Color(0xFFC35D5B);

  Future<bool> _confirmar(
    BuildContext context,
    String titulo,
    String texto,
  ) async {
    final resposta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          titulo,
          style: const TextStyle(
            color: _texto,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          texto,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: _textoSecundario),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _destaque,
              foregroundColor: _texto,
              elevation: 0,
            ),
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
    // Preserva as confirmações originais.
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemDeErro(e))));
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _destaque,
              onPrimary: _texto,
              surface: _superficie,
              onSurface: _texto,
            ),
          ),
          child: child!,
        );
      },
    );

    if (escolhido != null) {
      ref.read(diaSelecionadoProvider.notifier).definir(escolhido);
    }
  }

  Color _corDoStatus(String status) {
    switch (status) {
      case 'confirmado':
        return const Color(0xFF427FA8);
      case 'concluido':
        return _receita;
      case 'cancelado':
        return _textoSecundario;
      case 'nao_compareceu':
        return _despesa;
      default:
        return const Color(0xFFB17B35);
    }
  }

  Widget _indicadorStatus(Agendamento ag) {
    final cor = _corDoStatus(ag.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ag.statusRotulo,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _cardAgendamento({
    required BuildContext context,
    required WidgetRef ref,
    required Agendamento ag,
    required String cliente,
    required String servico,
  }) {
    final proximos = ag.proximosStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _destaque.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _destaque,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _texto,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      servico,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              if (proximos.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Alterar status',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: _textoSecundario,
                  ),
                  color: _superficie,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (novo) => _mudarStatus(context, ref, ag, novo),
                  itemBuilder: (_) => [
                    for (final s in proximos)
                      PopupMenuItem<String>(
                        value: s,
                        child: Text(rotuloDoStatus(s)),
                      ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 16),

          Container(height: 1, color: _borda),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _indicadorStatus(ag),

              Text(
                formatarDinheiro(ag.valor),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _texto,
                ),
              ),
            ],
          ),

          if (ag.observacoes != null && ag.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 17,
                  color: _textoSecundario,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    ag.observacoes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textoSecundario,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _destaque.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 34,
                color: _destaque,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nenhum agendamento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _texto,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Não há agendamentos registrados para este dia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textoSecundario,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dia = ref.watch(diaSelecionadoProvider);
    final agendamentos = ref.watch(agendamentosDoDiaProvider);

    final clientes = {
      for (final c in ref.watch(clientesProvider).asData?.value ?? [])
        c.id: c.nome,
    };

    final servicos = {
      for (final s in ref.watch(servicosProvider).asData?.value ?? [])
        s.id: s.nome,
    };

    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Agenda',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: _texto,
            letterSpacing: -0.5,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Clientes',
            icon: const Icon(Icons.people_outline_rounded),
            color: _texto,
            onPressed: () => context.push('/clientes'),
          ),

          IconButton(
            tooltip: 'Serviços',
            icon: const Icon(Icons.content_cut_rounded),
            color: _texto,
            onPressed: () => context.push('/servicos'),
          ),

          IconButton(
            tooltip: 'Financeiro',
            icon: const Icon(Icons.attach_money),
            onPressed: () => context.push('/financeiro'),
          ),

          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            color: _textoSecundario,
            onPressed: () => ref.read(tokenProvider.notifier).definir(null),
          ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo agendamento',
        backgroundColor: _destaque,
        foregroundColor: _texto,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => context.push('/agenda/novo'),
        child: const Icon(Icons.add_rounded, size: 28),
      ),

      body: Column(
        children: [
          // Seletor de data
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: _superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borda),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Dia anterior',
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: _texto,
                  onPressed: () => ref
                      .read(diaSelecionadoProvider.notifier)
                      .definir(DateTime(dia.year, dia.month, dia.day - 1)),
                ),

                Expanded(
                  child: TextButton(
                    onPressed: () => _escolherDia(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: _texto,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: _destaque,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            rotuloDia(dia),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _texto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Próximo dia',
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: _texto,
                  onPressed: () => ref
                      .read(diaSelecionadoProvider.notifier)
                      .definir(DateTime(dia.year, dia.month, dia.day + 1)),
                ),

                TextButton(
                  onPressed: () => ref
                      .read(diaSelecionadoProvider.notifier)
                      .definir(DateTime.now()),
                  style: TextButton.styleFrom(
                    foregroundColor: _destaque,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Hoje'),
                ),
              ],
            ),
          ),

          Expanded(
            child: agendamentos.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: _destaque,
                  strokeWidth: 2.5,
                ),
              ),

              error: (erro, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: _despesa,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        mensagemDeErro(erro),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textoSecundario,
                        ),
                      ),

                      const SizedBox(height: 20),

                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(agendamentosDoDiaProvider),
                        style: FilledButton.styleFrom(
                          backgroundColor: _destaque,
                          foregroundColor: _texto,
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),

              data: (lista) {
                if (lista.isEmpty) {
                  return _estadoVazio();
                }

                return RefreshIndicator(
                  color: _destaque,
                  onRefresh: () async {
                    ref.invalidate(agendamentosDoDiaProvider);
                    await ref.read(agendamentosDoDiaProvider.future);
                  },

                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: lista.length,
                    itemBuilder: (context, indice) {
                      final ag = lista[indice];

                      final cliente =
                          clientes[ag.clienteId] ?? 'Cliente #${ag.clienteId}';

                      final servico =
                          servicos[ag.servicoId] ?? 'Serviço #${ag.servicoId}';

                      return _cardAgendamento(
                        context: context,
                        ref: ref,
                        ag: ag,
                        cliente: cliente,
                        servico: servico,
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
