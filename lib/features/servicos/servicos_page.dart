
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import 'servico.dart';
import 'servicos_repository.dart';

class ServicosPage extends ConsumerWidget {
  const ServicosPage({super.key});

  // Design System BarberFlow
  static const Color _fundo = Color(0xFFF8F9FA);
  static const Color _superficie = Color(0xFFFFFFFF);
  static const Color _texto = Color(0xFF21262C);
  static const Color _textoSecundario = Color(0xFF737980);
  static const Color _destaque = Color(0xFFB38B5D);
  static const Color _borda = Color(0xFFE5E7EB);
  static const Color _erroCor = Color(0xFFC35D5B);

  Future<void> _desativar(
    BuildContext context,
    WidgetRef ref,
    Servico servico,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Desativar serviço',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
        content: Text(
          'Deseja desativar "${servico.nome}"? '
          'Os agendamentos já feitos não são afetados.',
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
              backgroundColor: _erroCor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      await ref
          .read(servicosRepositoryProvider)
          .desativar(servico.id);

      ref.invalidate(servicosProvider);
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

  Widget _cardServico({
    required BuildContext context,
    required WidgetRef ref,
    required Servico servico,
  }) {
    final temDescricao = servico.descricao != null &&
        servico.descricao!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(
            '/servicos/editar',
            extra: servico,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone do serviço
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _destaque.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    size: 22,
                    color: _destaque,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        servico.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _texto,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Preço e duração
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 16,
                                color: _destaque,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                servico.precoFormatado,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _texto,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: _textoSecundario,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                '${servico.duracaoMinutos} min',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (temDescricao) ...[
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _fundo,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.notes_rounded,
                                size: 16,
                                color: _textoSecundario,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  servico.descricao!,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _textoSecundario,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Desativação
                IconButton(
                  tooltip: 'Desativar serviço',
                  icon: const Icon(
                    Icons.block_outlined,
                    size: 20,
                  ),
                  color: _textoSecundario,
                  hoverColor: _erroCor.withValues(
                    alpha: 0.08,
                  ),
                  onPressed: () =>
                      _desativar(context, ref, servico),
                ),
              ],
            ),
          ),
        ),
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
                Icons.content_cut_rounded,
                size: 34,
                color: _destaque,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nenhum serviço cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _texto,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Cadastre os serviços oferecidos '
              'pela barbearia para começar.',
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
              color: _erroCor,
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
                  ref.invalidate(servicosProvider),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicos = ref.watch(servicosProvider);

    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Serviços',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: _texto,
            letterSpacing: -0.5,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo serviço',
        backgroundColor: _destaque,
        foregroundColor: _texto,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () =>
            context.push('/servicos/novo'),
        child: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
      ),

      body: servicos.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _destaque,
            strokeWidth: 2.5,
          ),
        ),

        error: (erro, _) => _estadoErro(ref, erro),

        data: (lista) {
          if (lista.isEmpty) {
            return _estadoVazio();
          }

          return RefreshIndicator(
            color: _destaque,
            onRefresh: () async {
              ref.invalidate(servicosProvider);
              await ref.read(servicosProvider.future);
            },

            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 96,
              ),
              itemCount: lista.length,
              itemBuilder: (context, indice) {
                final servico = lista[indice];

                return _cardServico(
                  context: context,
                  ref: ref,
                  servico: servico,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
