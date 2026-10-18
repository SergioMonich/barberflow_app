import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/formatacao.dart';
import 'movimentacao.dart';

class FinanceiroRepository {
  FinanceiroRepository(this._dio);

  final Dio _dio;

  Map<String, String> _periodo(DateTime inicio, DateTime fim) => {
    'inicio': formatarDataIso(inicio),
    'fim': formatarDataIso(fim),
  };

  Future<List<Movimentacao>> listarMovimentacoes(
    DateTime inicio,
    DateTime fim,
  ) async {
    final resposta = await _dio.get(
      '/financeiro/movimentacoes',
      queryParameters: _periodo(inicio, fim),
    );
    return (resposta.data as List)
        .map((json) => Movimentacao.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ResumoFinanceiro> resumo(DateTime inicio, DateTime fim) async {
    final resposta = await _dio.get(
      '/financeiro/resumo',
      queryParameters: _periodo(inicio, fim),
    );
    return ResumoFinanceiro.fromJson(resposta.data as Map<String, dynamic>);
  }

  Future<List<Categoria>> listarCategorias() async {
    final resposta = await _dio.get('/financeiro/categorias');
    return (resposta.data as List)
        .map((json) => Categoria.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Categoria> criarCategoria(String nome, String tipo) async {
    final resposta = await _dio.post(
      '/financeiro/categorias',
      data: {'nome': nome, 'tipo': tipo},
    );
    return Categoria.fromJson(resposta.data as Map<String, dynamic>);
  }

  Future<void> criarMovimentacao(Map<String, dynamic> dados) async {
    await _dio.post('/financeiro/movimentacoes', data: dados);
  }

  Future<void> excluirMovimentacao(int id) async {
    await _dio.delete('/financeiro/movimentacoes/$id');
  }
}

final financeiroRepositoryProvider = Provider<FinanceiroRepository>((ref) {
  return FinanceiroRepository(ref.watch(dioProvider));
});

/// Mês que o financeiro está mostrando (sempre o dia 1).
class MesSelecionado extends Notifier<DateTime> {
  @override
  DateTime build() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, 1);
  }

  void definir(DateTime mes) {
    state = DateTime(mes.year, mes.month, 1);
  }
}

final mesSelecionadoProvider = NotifierProvider<MesSelecionado, DateTime>(
  MesSelecionado.new,
);

DateTime _ultimoDiaDoMes(DateTime mes) => DateTime(mes.year, mes.month + 1, 0);

// autoDispose: ao voltar para a tela, recarrega. Assim uma receita criada ao
// concluir um atendimento na agenda já aparece aqui.
final movimentacoesDoMesProvider =
    FutureProvider.autoDispose<List<Movimentacao>>((ref) async {
      final token = ref.watch(tokenProvider);
      if (token == null) return [];
      final mes = ref.watch(mesSelecionadoProvider);
      return ref
          .watch(financeiroRepositoryProvider)
          .listarMovimentacoes(mes, _ultimoDiaDoMes(mes));
    });

final resumoDoMesProvider = FutureProvider.autoDispose<ResumoFinanceiro>((
  ref,
) async {
  final token = ref.watch(tokenProvider);
  final mes = ref.watch(mesSelecionadoProvider);
  if (token == null) {
    return const ResumoFinanceiro(
      receitas: 0,
      despesas: 0,
      saldo: 0,
      quantidade: 0,
    );
  }
  return ref
      .watch(financeiroRepositoryProvider)
      .resumo(mes, _ultimoDiaDoMes(mes));
});

final categoriasProvider = FutureProvider<List<Categoria>>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null) return [];
  return ref.watch(financeiroRepositoryProvider).listarCategorias();
});
