class Servico {
  const Servico({
    required this.id,
    required this.nome,
    required this.preco,
    required this.duracaoMinutos,
    this.descricao,
  });

  final int id;
  final String nome;
  final double preco;
  final int duracaoMinutos;
  final String? descricao;

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'] as int,
      nome: json['nome'] as String,
      preco: (json['preco'] as num).toDouble(),
      duracaoMinutos: json['duracao_minutos'] as int,
      descricao: json['descricao'] as String?,
    );
  }

  /// Ex.: 35.5 -> "R$ 35,50"
  String get precoFormatado =>
      'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
}
