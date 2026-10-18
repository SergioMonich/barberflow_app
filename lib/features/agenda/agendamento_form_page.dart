import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatacao.dart';
import '../clientes/clientes_repository.dart';
import '../servicos/servicos_repository.dart';
import 'agendamentos_repository.dart';

class AgendamentoFormPage extends ConsumerStatefulWidget {
  const AgendamentoFormPage({super.key});

  @override
  ConsumerState<AgendamentoFormPage> createState() =>
      _AgendamentoFormPageState();
}

class _AgendamentoFormPageState extends ConsumerState<AgendamentoFormPage> {
  final _obsCtrl = TextEditingController();

  int? _clienteId;
  int? _servicoId;

  late DateTime _data;
  TimeOfDay _hora = const TimeOfDay(hour: 9, minute: 0);

  bool _carregando = false;
  String? _erro;

  // Design System BarberFlow
  static const Color _fundo = Color(0xFFF8F9FA);
  static const Color _superficie = Color(0xFFFFFFFF);
  static const Color _texto = Color(0xFF21262C);
  static const Color _textoSecundario = Color(0xFF737980);
  static const Color _destaque = Color(0xFFB38B5D);
  static const Color _borda = Color(0xFFE5E7EB);
  static const Color _erroCor = Color(0xFFC35D5B);

  @override
  void initState() {
    super.initState();
    // Mantém o dia selecionado na agenda.
    _data = ref.read(diaSelecionadoProvider);
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _destaque,
              onPrimary: _texto,
              surface: _superficie,
              onSurface: _texto,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (escolhida != null) {
      setState(() => _data = escolhida);
    }
  }

  Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (context, child) {
        final tema = Theme.of(context);

        return Theme(
          data: tema.copyWith(
            colorScheme: const ColorScheme.light(
              primary: _destaque,
              onPrimary: _texto,
              surface: _superficie,
              onSurface: _texto,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (!mounted) return;

    if (escolhida != null) {
      setState(() => _hora = escolhida);
    }
  }

  Future<void> _salvar() async {
    if (_clienteId == null) {
      setState(() => _erro = 'Selecione o cliente');
      return;
    }

    if (_servicoId == null) {
      setState(() => _erro = 'Selecione o serviço');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    // Preserva o envio da data/hora em UTC.
    final dataHora = DateTime(
      _data.year,
      _data.month,
      _data.day,
      _hora.hour,
      _hora.minute,
    );

    final obs = _obsCtrl.text.trim();

    final dados = {
      'cliente_id': _clienteId,
      'servico_id': _servicoId,
      'data_hora': dataHora.toUtc().toIso8601String(),
      'observacoes': obs.isEmpty ? null : obs,
    };

    try {
      await ref.read(agendamentosRepositoryProvider).criar(dados);

      ref.read(diaSelecionadoProvider.notifier).definir(_data);

      ref.invalidate(agendamentosDoDiaProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _erro = mensagemDeErro(e));
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  InputDecoration _decoracaoCampo({required String label, IconData? icone}) {
    OutlineInputBorder borda(Color cor, double largura) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: _textoSecundario),
      prefixIcon: icone == null
          ? null
          : Icon(icone, size: 20, color: _textoSecundario),
      filled: true,
      fillColor: _superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: borda(_borda, 1),
      enabledBorder: borda(_borda, 1),
      focusedBorder: borda(_destaque, 1.5),
    );
  }

  Widget _tituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _texto,
        ),
      ),
    );
  }

  Widget _seletorDataHora({
    required String titulo,
    required String valor,
    required IconData icone,
    required VoidCallback aoPressionar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textoSecundario,
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: aoPressionar,
            icon: Icon(icone, size: 19, color: _destaque),
            label: Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: _texto,
              backgroundColor: _superficie,
              side: const BorderSide(color: _borda),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesProvider).asData?.value ?? [];

    final servicos = ref.watch(servicosProvider).asData?.value ?? [];

    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _texto),
        title: const Text(
          'Novo agendamento',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borda),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Informações do atendimento',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: _texto,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Preencha os dados para registrar '
                      'um novo agendamento.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textoSecundario,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (clientes.isEmpty || servicos.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _destaque.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: _destaque,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Para agendar, cadastre antes '
                                'pelo menos um cliente e um serviço.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _texto,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],

                    _tituloSecao('Dados do agendamento'),

                    DropdownMenu<int>(
                      label: const Text('Cliente *'),
                      leadingIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: _textoSecundario,
                      ),
                      expandedInsets: EdgeInsets.zero,
                      enableFilter: true,
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: _superficie,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _borda),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _borda),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _destaque,
                            width: 1.5,
                          ),
                        ),
                      ),
                      dropdownMenuEntries: [
                        for (final c in clientes)
                          DropdownMenuEntry(value: c.id, label: c.nome),
                      ],
                      onSelected: (valor) {
                        setState(() => _clienteId = valor);
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownMenu<int>(
                      label: const Text('Serviço *'),
                      leadingIcon: const Icon(
                        Icons.content_cut_rounded,
                        color: _textoSecundario,
                      ),
                      expandedInsets: EdgeInsets.zero,
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: _superficie,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _borda),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _borda),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _destaque,
                            width: 1.5,
                          ),
                        ),
                      ),
                      dropdownMenuEntries: [
                        for (final s in servicos)
                          DropdownMenuEntry(
                            value: s.id,
                            label:
                                '${s.nome} · '
                                '${formatarDinheiro(s.preco)}',
                          ),
                      ],
                      onSelected: (valor) {
                        setState(() => _servicoId = valor);
                      },
                    ),

                    const SizedBox(height: 28),

                    _tituloSecao('Data e horário'),

                    Row(
                      children: [
                        Expanded(
                          child: _seletorDataHora(
                            titulo: 'Data',
                            valor: formatarData(_data),
                            icone: Icons.calendar_today_outlined,
                            aoPressionar: _escolherData,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _seletorDataHora(
                            titulo: 'Horário',
                            valor:
                                '${_hora.hour.toString().padLeft(2, '0')}:'
                                '${_hora.minute.toString().padLeft(2, '0')}',
                            icone: Icons.access_time_rounded,
                            aoPressionar: _escolherHora,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _tituloSecao('Informações adicionais'),

                    TextField(
                      controller: _obsCtrl,
                      maxLines: 3,
                      decoration: _decoracaoCampo(
                        label: 'Observações',
                        icone: Icons.notes_rounded,
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_erro != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _erroCor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: _erroCor,
                              size: 20,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                _erro!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _erroCor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _carregando ? null : _salvar,
                        style: FilledButton.styleFrom(
                          backgroundColor: _destaque,
                          foregroundColor: _texto,
                          disabledBackgroundColor: _destaque.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: _carregando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _texto,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(_carregando ? 'Salvando...' : 'Agendar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
