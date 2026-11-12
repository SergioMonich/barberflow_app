import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatacao.dart';
import 'financeiro_repository.dart';
import 'movimentacao.dart';

class FinanceiroPage extends ConsumerWidget {
  const FinanceiroPage({super.key});

  // Design System BarberFlow
  static const Color _fundo = Color(0xFFF8F9FA);
  static const Color _superficie = Color(0xFFFFFFFF);
  static const Color _texto = Color(0xFF21262C);
  static const Color _textoSecundario = Color(0xFF737980);
  static const Color _destaque = Color(0xFFB38B5D);
  static const Color _borda = Color(0xFFE5E7EB);

  // Cores semânticas
  static const Color _receita = Color(0xFF27856B);
  static const Color _despesa = Color(0xFFC35D5B);

  Future<void> _excluir(
    BuildContext context,
    WidgetRef ref,
    Movimentacao mov,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Excluir lançamento',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
        content: Text(
          'Excluir ${mov.ehReceita ? 'a receita' : 'a despesa'} '
          'de ${formatarDinheiro(mov.valor)}?',
          style: const TextStyle(
            fontSize: 14,
            color: _textoSecundario,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: _textoSecundario,
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _despesa,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      await ref
          .read(financeiroRepositoryProvider)
          .excluirMovimentacao(mov.id);

      ref.invalidate(movimentacoesDoMesProvider);
      ref.invalidate(resumoDoMesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemDeErro(e)),
          ),
        );
      }
    }
  }

  // --------------------------------------------------
  // Navegação mensal
  // --------------------------------------------------

  Widget _seletorMes(
    WidgetRef ref,
    DateTime mes,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: _texto,
            ),
            onPressed: () {
              ref
                  .read(mesSelecionadoProvider.notifier)
                  .definir(
                    DateTime(mes.year, mes.month - 1),
                  );
            },
          ),

          Expanded(
            child: Column(
              children: [
                const Text(
                  'PERÍODO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: _textoSecundario,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  rotuloMes(mes),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _texto,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Próximo mês',
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: _texto,
            ),
            onPressed: () {
              ref
                  .read(mesSelecionadoProvider.notifier)
                  .definir(
                    DateTime(mes.year, mes.month + 1),
                  );
            },
          ),

          const SizedBox(width: 4),

          TextButton(
            onPressed: () {
              ref
                  .read(mesSelecionadoProvider.notifier)
                  .definir(DateTime.now());
            },
            style: TextButton.styleFrom(
              foregroundColor: _destaque,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
            ),
            child: const Text(
              'Este mês',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Card de resumo financeiro
  // --------------------------------------------------

  Widget _cartaoResumo({
    required String titulo,
    required double valor,
    required Color cor,
    required IconData icone,
  }) {
    return Container(
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
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textoSecundario,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            formatarDinheiro(valor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: cor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Resumo do mês
  // --------------------------------------------------

  Widget _resumoFinanceiro({
    required double receitas,
    required double despesas,
    required double saldo,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        // Em telas estreitas, evita comprimir os valores.
        final duasColunas = largura < 520;

        if (duasColunas) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _cartaoResumo(
                      titulo: 'Receitas',
                      valor: receitas,
                      cor: _receita,
                      icone: Icons.trending_up_rounded,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _cartaoResumo(
                      titulo: 'Despesas',
                      valor: despesas,
                      cor: _despesa,
                      icone: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _cartaoResumo(
                titulo: 'Saldo do mês',
                valor: saldo,
                cor: saldo >= 0 ? _receita : _despesa,
                icone: Icons.account_balance_wallet_outlined,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _cartaoResumo(
                titulo: 'Receitas',
                valor: receitas,
                cor: _receita,
                icone: Icons.trending_up_rounded,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _cartaoResumo(
                titulo: 'Despesas',
                valor: despesas,
                cor: _despesa,
                icone: Icons.trending_down_rounded,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _cartaoResumo(
                titulo: 'Saldo',
                valor: saldo,
                cor: saldo >= 0 ? _receita : _despesa,
                icone: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // Card de movimentação
  // --------------------------------------------------

  Widget _cardMovimentacao({
    required BuildContext context,
    required WidgetRef ref,
    required Movimentacao mov,
    required String categoria,
  }) {
    final cor = mov.ehReceita ? _receita : _despesa;

    final titulo = mov.descricao ?? categoria;

    final subtitulo = mov.descricao == null
        ? formatarData(mov.data)
        : '${formatarData(mov.data)} · $categoria';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Indicador de receita ou despesa
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              mov.ehReceita
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: cor,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _texto,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textoSecundario,
                    height: 1.4,
                  ),
                ),

                if (mov.geradaPorAtendimento) ...[
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _destaque.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Atendimento',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _destaque,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Valor e ação
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${mov.ehReceita ? '+' : '-'} '
                '${formatarDinheiro(mov.valor)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cor,
                ),
              ),

              const SizedBox(height: 8),

              if (mov.geradaPorAtendimento)
                const Tooltip(
                  message: 'Gerada por um atendimento',
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.event_available_rounded,
                      size: 19,
                      color: _textoSecundario,
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Excluir lançamento',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                  color: _textoSecundario,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      _excluir(context, ref, mov),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Estado vazio
  // --------------------------------------------------

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
                Icons.receipt_long_outlined,
                size: 34,
                color: _destaque,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nenhum lançamento neste mês',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _texto,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Registre receitas e despesas para '
              'acompanhar o financeiro da barbearia.',
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

  // --------------------------------------------------
  // Estado de erro
  // --------------------------------------------------

  Widget _estadoErro(
    WidgetRef ref,
    Object erro,
  ) {
    return Center(
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
              onPressed: () {
                ref.invalidate(movimentacoesDoMesProvider);
                ref.invalidate(resumoDoMesProvider);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _destaque,
                foregroundColor: _texto,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Tela principal
  // --------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSelecionadoProvider);

    final resumo = ref.watch(resumoDoMesProvider);

    final movimentacoes = ref.watch(
      movimentacoesDoMesProvider,
    );

    final categorias = {
      for (final c
          in ref.watch(categoriasProvider).asData?.value ?? [])
        c.id: c.nome,
    };

    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Financeiro',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: _texto,
            letterSpacing: -0.5,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Novo lançamento',
        onPressed: () =>
            context.push('/financeiro/novo'),
        backgroundColor: _destaque,
        foregroundColor: _texto,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 22,
        ),
        label: const Text(
          'Lançamento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Column(
        children: [
          // Seletor de mês
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 16,
            ),
            child: _seletorMes(ref, mes),
          ),

          // Resumo financeiro
          resumo.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              child: LinearProgressIndicator(
                color: _destaque,
                backgroundColor: _borda,
              ),
            ),

            error: (erro, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                mensagemDeErro(erro),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _despesa,
                ),
              ),
            ),

            data: (r) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: _resumoFinanceiro(
                receitas: r.receitas,
                despesas: r.despesas,
                saldo: r.saldo,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Título da lista
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Movimentações',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _texto,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lista de movimentações
          Expanded(
            child: movimentacoes.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: _destaque,
                  strokeWidth: 2.5,
                ),
              ),

              error: (erro, _) =>
                  _estadoErro(ref, erro),

              data: (lista) {
                if (lista.isEmpty) {
                  return _estadoVazio();
                }

                // Preserva a ordem original:
                // movimentações mais recentes primeiro.
                final ordenada = lista.reversed.toList();

                return RefreshIndicator(
                  color: _destaque,
                  onRefresh: () async {
                    ref.invalidate(
                      movimentacoesDoMesProvider,
                    );

                    ref.invalidate(resumoDoMesProvider);

                    await ref.read(
                      movimentacoesDoMesProvider.future,
                    );
                  },

                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 100,
                    ),
                    itemCount: ordenada.length,
                    itemBuilder: (context, indice) {
                      final mov = ordenada[indice];

                      final categoria =
                          categorias[mov.categoriaId] ??
                              'Sem categoria';

                      return _cardMovimentacao(
                        context: context,
                        ref: ref,
                        mov: mov,
                        categoria: categoria,
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