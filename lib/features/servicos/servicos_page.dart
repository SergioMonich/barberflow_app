import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'servico.dart';
import 'servicos_repository.dart';

class ServicosPage extends ConsumerWidget {
  const ServicosPage({super.key});

  Future<void> _desativar(
    BuildContext context,
    WidgetRef ref,
    Servico servico,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar serviço'),
        content: Text(
          'Deseja desativar "${servico.nome}"? '
          'Os agendamentos já feitos não são afetados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await ref.read(servicosRepositoryProvider).desativar(servico.id);
      ref.invalidate(servicosProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemDeErro(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicos = ref.watch(servicosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/servicos/novo'),
        child: const Icon(Icons.add),
      ),
      body: servicos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensagemDeErro(erro)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(servicosProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Text('Nenhum serviço cadastrado ainda.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(servicosProvider);
              await ref.read(servicosProvider.future);
            },
            child: ListView.separated(
              itemCount: lista.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, indice) {
                final servico = lista[indice];
                return ListTile(
                  title: Text(servico.nome),
                                    subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${servico.precoFormatado} · ${servico.duracaoMinutos} min',
                      ),
                      if (servico.descricao != null &&
                          servico.descricao!.isNotEmpty)
                        Text(
                          servico.descricao!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/servicos/editar', extra: servico),
                  trailing: IconButton(
                    tooltip: 'Desativar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _desativar(context, ref, servico),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
