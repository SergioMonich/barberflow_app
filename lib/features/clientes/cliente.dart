class Cliente {
  const Cliente({
    required this.id,
    required this.nome,
    this.telefone,
    this.email,
    this.observacoes,
  });

  final int id;
  final String nome;
  final String? telefone;
  final String? email;
  final String? observacoes;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      nome: json['nome'] as String,
      telefone: json['telefone'] as String?,
      email: json['email'] as String?,
      observacoes: json['observacoes'] as String?,
    );
  }
}
