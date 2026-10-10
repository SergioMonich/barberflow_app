/// Ex.: 35.5 -> "R$ 35,50"; -714.5 -> "-R$ 714,50"
String formatarDinheiro(double valor) {
  final texto = valor.abs().toStringAsFixed(2).replaceAll('.', ',');
  return '${valor < 0 ? '-' : ''}R\$ $texto';
}

String _dois(int n) => n.toString().padLeft(2, '0');

/// Ex.: 10/10/2026
String formatarData(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

/// Ex.: 15:00
String formatarHora(DateTime d) => '${_dois(d.hour)}:${_dois(d.minute)}';

const _diasDaSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

/// Ex.: "Sáb, 10/10/2026"
String rotuloDia(DateTime d) =>
    '${_diasDaSemana[d.weekday - 1]}, ${formatarData(d)}';

/// Formato que a API espera em datas sem hora. Ex.: 2026-10-05
String formatarDataIso(DateTime d) =>
    '${d.year}-${_dois(d.month)}-${_dois(d.day)}';

const _meses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Ex.: "Outubro de 2026"
String rotuloMes(DateTime d) => '${_meses[d.month - 1]} de ${d.year}';