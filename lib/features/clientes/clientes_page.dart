
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import 'cliente.dart';
import 'clientes_repository.dart';

class ClientesPage extends ConsumerWidget {
  const ClientesPage({super.key});

  // Design System BarberFlow
  static const Color _fundo = Color(0xFFF8F9FA);
  static const Color _superficie = Color(0xFFFFFFFF);
  static const Color _texto = Color(0xFF21262C);
  static const Color _textoSecundario = Color(0xFF737980);
  static const Color _destaque = Color(0xFFB38B5D);
  static const Color _borda = Color(0xFFE5E7EB);
  static const Color _erroCor = Color(0xFFC35D5B);

  Future<void> _excluir(
    BuildContext context,
    WidgetRef ref,
    Cliente cliente,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Excluir cliente',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
        content: Text(
          'Deseja excluir ${cliente.nome}?',
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
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      await ref
          .read(clientesRepositoryProvider)
          .excluir(cliente.id);

      ref.invalidate(clientesProvider);
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

  Widget _cardCliente({
    required BuildContext context,
    required WidgetRef ref,
    required Cliente cliente,
  }) {
    final nome = cliente.nome.trim();

    final inicial = nome.isNotEmpty
        ? nome.substring(0, 1).toUpperCase()
        : '?';

    final temTelefone = cliente.telefone != null &&
        cliente.telefone!.isNotEmpty;

    final temEmail = cliente.email != null &&
        cliente.email!.isNotEmpty;

    final temObservacoes = cliente.observacoes != null &&
        cliente.observacoes!.isNotEmpty;

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
            '/clientes/editar',
            extra: cliente,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar com inicial do cliente
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _destaque.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _destaque,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _texto,
                        ),
                      ),

                      if (temTelefone) ...[
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: _textoSecundario,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cliente.telefone!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textoSecundario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (temEmail) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 16,
                              color: _textoSecundario,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cliente.email!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textoSecundario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (temObservacoes) ...[
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
                                  cliente.observacoes!,
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

                // Ação de exclusão
                IconButton(
                  tooltip: 'Excluir cliente',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                  color: _textoSecundario,
                  hoverColor: _erroCor.withValues(
                    alpha: 0.08,
                  ),
                  onPressed: () =>
                      _excluir(context, ref, cliente),
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
                Icons.people_outline_rounded,
                size: 34,
                color: _destaque,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nenhum cliente cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _texto,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Cadastre seu primeiro cliente para '
              'começar a organizar seus atendimentos.',
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
                  ref.invalidate(clientesProvider),
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
    final clientes = ref.watch(clientesProvider);

    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Clientes',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: _texto,
            letterSpacing: -0.5,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Serviços',
            icon: const Icon(
              Icons.content_cut_rounded,
            ),
            color: _texto,
            onPressed: () => context.push('/servicos'),
          ),

          IconButton(
            tooltip: 'Sair',
            icon: const Icon(
              Icons.logout_rounded,
            ),
            color: _textoSecundario,
            onPressed: () => ref
                .read(tokenProvider.notifier)
                .definir(null),
          ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo cliente',
        backgroundColor: _destaque,
        foregroundColor: _texto,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () =>
            context.push('/clientes/novo'),
        child: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
      ),

      body: clientes.when(
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
              ref.invalidate(clientesProvider);
              await ref.read(clientesProvider.future);
            },

            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 96,
              ),
              itemCount: lista.length,
              itemBuilder: (context, indice) {
                final cliente = lista[indice];

                return _cardCliente(
                  context: context,
                  ref: ref,
                  cliente: cliente,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
