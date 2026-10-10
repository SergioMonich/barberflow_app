import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'agendamento.dart';

class AgendamentosRepository {
  AgendamentosRepository(this._dio);

  final Dio _dio;

  /// Agendamentos do dia local [dia] (da meia-noite até a próxima).
  Future<List<Agendamento>> listarDoDia(DateTime dia) async {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fim = DateTime(dia.year, dia.month, dia.day + 1);
    final resposta = await _dio.get(
      '/agendamentos',
      queryParameters: {
        'inicio': inicio.toUtc().toIso8601String(),
        'fim': fim.toUtc().toIso8601String(),
      },
    );
    return (resposta.data as List)
        .map((json) => Agendamento.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> criar(Map<String, dynamic> dados) async {
    await _dio.post('/agendamentos', data: dados);
  }

  Future<void> alterarStatus(int id, String novoStatus) async {
    await _dio.patch('/agendamentos/$id/status', data: {'status': novoStatus});
  }
}

final agendamentosRepositoryProvider = Provider<AgendamentosRepository>((ref) {
  return AgendamentosRepository(ref.watch(dioProvider));
});

/// Dia que a agenda está mostrando.
class DiaSelecionado extends Notifier<DateTime> {
  @override
  DateTime build() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  void definir(DateTime dia) {
    state = DateTime(dia.year, dia.month, dia.day);
  }
}

final diaSelecionadoProvider =
    NotifierProvider<DiaSelecionado, DateTime>(DiaSelecionado.new);

/// Agendamentos do dia selecionado. Recarregar: ref.invalidate(agendamentosDoDiaProvider).
final agendamentosDoDiaProvider = FutureProvider<List<Agendamento>>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null) return [];
  final dia = ref.watch(diaSelecionadoProvider);
  return ref.watch(agendamentosRepositoryProvider).listarDoDia(dia);
});