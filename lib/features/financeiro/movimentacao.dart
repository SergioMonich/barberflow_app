class Categoria {
  const Categoria({required this.id, required this.nome, required this.tipo});

  final int id;
  final String nome;

  /// 'receita' ou 'despesa'
  final String tipo;

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int,
      nome: json['nome'] as String,
      tipo: json['tipo'] as String,
    );
  }
}

class Movimentacao {
  const Movimentacao({
    required this.id,
    required this.tipo,
    required this.categoriaId,
    required this.valor,
    required this.data,
    this.descricao,
    this.agendamentoId,
  });

  final int id;
  final String tipo;
  final int categoriaId;
  final double valor;
  final DateTime data;
  final String? descricao;
  final int? agendamentoId;

  bool get ehReceita => tipo == 'receita';

  /// Receita criada sozinha quando um atendimento foi concluído.
  bool get geradaPorAtendimento => agendamentoId != null;

  factory Movimentacao.fromJson(Map<String, dynamic> json) {
    return Movimentacao(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      categoriaId: json['categoria_id'] as int,
      valor: (json['valor'] as num).toDouble(),
      // "2026-10-05" vira meia-noite local, sem mudança de dia.
      data: DateTime.parse(json['data'] as String),
      descricao: json['descricao'] as String?,
      agendamentoId: json['agendamento_id'] as int?,
    );
  }
}

class ResumoFinanceiro {
  const ResumoFinanceiro({
    required this.receitas,
    required this.despesas,
    required this.saldo,
    required this.quantidade,
  });

  final double receitas;
  final double despesas;
  final double saldo;
  final int quantidade;

  factory ResumoFinanceiro.fromJson(Map<String, dynamic> json) {
    return ResumoFinanceiro(
      receitas: (json['receitas'] as num).toDouble(),
      despesas: (json['despesas'] as num).toDouble(),
      saldo: (json['saldo'] as num).toDouble(),
      quantidade: json['quantidade'] as int,
    );
  }
}
