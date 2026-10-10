class Agendamento {
  const Agendamento({
    required this.id,
    required this.clienteId,
    required this.servicoId,
    required this.dataHora,
    required this.status,
    required this.valor,
    this.observacoes,
  });

  final int id;
  final int clienteId;
  final int servicoId;

  /// Já convertido para o fuso do aparelho (a API devolve em UTC).
  final DateTime dataHora;
  final String status;
  final double valor;
  final String? observacoes;

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'] as int,
      clienteId: json['cliente_id'] as int,
      servicoId: json['servico_id'] as int,
      dataHora: DateTime.parse(json['data_hora'] as String).toLocal(),
      status: json['status'] as String,
      valor: (json['valor'] as num).toDouble(),
      observacoes: json['observacoes'] as String?,
    );
  }

  String get statusRotulo => rotuloDoStatus(status);

  /// Mesmas regras do backend: para onde este agendamento pode ir.
  List<String> get proximosStatus {
    switch (status) {
      case 'agendado':
        return ['confirmado', 'concluido', 'cancelado', 'nao_compareceu'];
      case 'confirmado':
        return ['concluido', 'cancelado', 'nao_compareceu'];
      default:
        return [];
    }
  }
}

String rotuloDoStatus(String status) {
  switch (status) {
    case 'agendado':
      return 'Agendado';
    case 'confirmado':
      return 'Confirmado';
    case 'concluido':
      return 'Concluído';
    case 'cancelado':
      return 'Cancelado';
    case 'nao_compareceu':
      return 'Não compareceu';
    default:
      return status;
  }
}