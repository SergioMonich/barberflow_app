import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import 'cliente.dart';
import 'clientes_repository.dart';

class ClientesPage extends ConsumerWidget {
  const ClientesPage({super.key});

  Future<void> _excluir(
    BuildContext context,
    WidgetRef ref,
    Cliente cliente,
  ) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Deseja excluir ${cliente.nome}?'),
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
      await ref.read(clientesRepositoryProvider).excluir(cliente.id);
      ref.invalidate(clientesProvider);
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
    final clientes = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(tokenProvider.notifier).definir(null),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/clientes/novo'),
        child: const Icon(Icons.add),
      ),
      body: clientes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensagemDeErro(erro)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(clientesProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Text('Nenhum cliente cadastrado ainda.'),
            );
          }
          return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(clientesProvider);
                await ref.read(clientesProvider.future);
              },
            child: ListView.separated(
              itemCount: lista.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, indice) {
                final cliente = lista[indice];
                final detalhe = cliente.telefone ?? cliente.email;
                return ListTile(
                  title: Text(cliente.nome),
                  subtitle: detalhe == null ? null : Text(detalhe),
                  onTap: () => context.push('/clientes/editar', extra: cliente),
                  trailing: IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _excluir(context, ref, cliente),
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
