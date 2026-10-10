import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'servico.dart';

class ServicosRepository {
  ServicosRepository(this._dio);

  final Dio _dio;

  Future<List<Servico>> listar() async {
    final resposta = await _dio.get('/servicos');
    return (resposta.data as List)
        .map((json) => Servico.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> criar(Map<String, dynamic> dados) async {
    await _dio.post('/servicos', data: dados);
  }

  Future<void> atualizar(int id, Map<String, dynamic> dados) async {
    await _dio.put('/servicos/$id', data: dados);
  }

  /// No backend o DELETE só desativa (soft delete): o serviço some da lista,
  /// mas os agendamentos antigos continuam intactos.
  Future<void> desativar(int id) async {
    await _dio.delete('/servicos/$id');
  }
}

final servicosRepositoryProvider = Provider<ServicosRepository>((ref) {
  return ServicosRepository(ref.watch(dioProvider));
});

/// Lista de serviços ativos. Para recarregar: ref.invalidate(servicosProvider).
final servicosProvider = FutureProvider<List<Servico>>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null) return [];
  return ref.watch(servicosRepositoryProvider).listar();
});
