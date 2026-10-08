import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'cliente.dart';

class ClientesRepository {
  ClientesRepository(this._dio);

  final Dio _dio;

  Future<List<Cliente>> listar() async {
    final resposta = await _dio.get('/clientes');
    return (resposta.data as List)
        .map((json) => Cliente.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> criar(Map<String, dynamic> dados) async {
    await _dio.post('/clientes', data: dados);
  }

  Future<void> atualizar(int id, Map<String, dynamic> dados) async {
    await _dio.put('/clientes/$id', data: dados);
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/clientes/$id');
  }
}

final clientesRepositoryProvider = Provider<ClientesRepository>((ref) {
  return ClientesRepository(ref.watch(dioProvider));
});

/// Lista de clientes. Para recarregar: ref.invalidate(clientesProvider).
/// Observa o token, entao trocar de usuario nunca mostra dados do anterior.
final clientesProvider = FutureProvider<List<Cliente>>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null) return [];
  return ref.watch(clientesRepositoryProvider).listar();
});
