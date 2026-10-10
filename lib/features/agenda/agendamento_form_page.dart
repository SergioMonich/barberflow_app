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

  @override
  void initState() {
    super.initState();
    // Começa no dia que a agenda estava mostrando.
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
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

    Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: _hora,
      // Força o relógio de 24h, sem AM/PM.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (escolhida != null) setState(() => _hora = escolhida);
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

    // Monta a data/hora no fuso local e manda em UTC (o backend guarda em UTC).
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
      // Mostra o dia do novo agendamento ao voltar para a agenda.
      ref.read(diaSelecionadoProvider.notifier).definir(_data);
      ref.invalidate(agendamentosDoDiaProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesProvider).asData?.value ?? [];
    final servicos = ref.watch(servicosProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Novo agendamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (clientes.isEmpty || servicos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Para agendar, cadastre antes pelo menos um cliente e um serviço.',
                ),
              ),
            DropdownMenu<int>(
              label: const Text('Cliente *'),
              expandedInsets: EdgeInsets.zero,
              enableFilter: true,
              dropdownMenuEntries: [
                for (final c in clientes)
                  DropdownMenuEntry(value: c.id, label: c.nome),
              ],
              onSelected: (valor) => setState(() => _clienteId = valor),
            ),
            const SizedBox(height: 16),
            DropdownMenu<int>(
              label: const Text('Serviço *'),
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: [
                for (final s in servicos)
                  DropdownMenuEntry(
                    value: s.id,
                    label: '${s.nome} · ${formatarDinheiro(s.preco)}',
                  ),
              ],
              onSelected: (valor) => setState(() => _servicoId = valor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherData,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(formatarData(_data)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _escolherHora,
                    icon: const Icon(Icons.access_time),
                      label: Text(
                        '${_hora.hour.toString().padLeft(2, '0')}:'
                        '${_hora.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 16),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _carregando ? null : _salvar,
              child: _carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Agendar'),
            ),
          ],
        ),
      ),
    );
  }
}