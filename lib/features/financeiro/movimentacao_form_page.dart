import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/formatacao.dart';
import 'financeiro_repository.dart';

class MovimentacaoFormPage extends ConsumerStatefulWidget {
  const MovimentacaoFormPage({super.key});

  @override
  ConsumerState<MovimentacaoFormPage> createState() =>
      _MovimentacaoFormPageState();
}

class _MovimentacaoFormPageState
    extends ConsumerState<MovimentacaoFormPage> {
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  String _tipo = 'despesa';
  int? _categoriaId;
  DateTime _data = DateTime.now();

  bool _carregando = false;
  String? _erro;

  // Design System BarberFlow
  static const Color _fundo = Color(0xFFF8F9FA);
  static const Color _superficie = Color(0xFFFFFFFF);
  static const Color _texto = Color(0xFF21262C);
  static const Color _textoSecundario = Color(0xFF737980);
  static const Color _destaque = Color(0xFFB38B5D);
  static const Color _borda = Color(0xFFE5E7EB);

  // Cores semânticas
  static const Color _receita = Color(0xFF27856B);
  static const Color _despesa = Color(0xFFC35D5B);

  bool get _ehReceita => _tipo == 'receita';

  Color get _corTipo => _ehReceita ? _receita : _despesa;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  /// Aceita "35,50" e "35.50".
  double? _lerValor(String texto) {
    return double.tryParse(
      texto.trim().replaceAll(',', '.'),
    );
  }

  // --------------------------------------------------
  // Seleção de data
  // --------------------------------------------------

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

  // --------------------------------------------------
  // Criação de categoria
  // --------------------------------------------------

  Future<void> _novaCategoria() async {
    final controlador = TextEditingController();

    // Guarda o tipo para associar a categoria ao tipo
    // selecionado no momento da abertura do diálogo.
    final tipoCategoria = _tipo;

    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Nova categoria de '
          '${tipoCategoria == 'despesa' ? 'despesa' : 'receita'}',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),
        content: TextField(
          controller: controlador,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoracaoCampo(
            label: 'Nome da categoria',
            icone: Icons.category_outlined,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: _textoSecundario,
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                controlador.text.trim(),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _destaque,
              foregroundColor: _texto,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    // O diálogo já foi encerrado.
    controlador.dispose();

    if (!mounted || nome == null || nome.isEmpty) {
      return;
    }

    try {
      final categoria = await ref
          .read(financeiroRepositoryProvider)
          .criarCategoria(nome, tipoCategoria);

      ref.invalidate(categoriasProvider);

      await ref.read(categoriasProvider.future);

      if (mounted) {
        setState(() {
          // Evita selecionar uma categoria de outro tipo
          // caso o tipo tenha mudado durante a operação.
          if (_tipo == tipoCategoria) {
            _categoriaId = categoria.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erro = mensagemDeErro(e));
      }
    }
  }

  // --------------------------------------------------
  // Salvamento
  // --------------------------------------------------

  Future<void> _salvar() async {
    final valor = _lerValor(_valorCtrl.text);

    if (_categoriaId == null) {
      setState(() {
        _erro = 'Selecione a categoria';
      });
      return;
    }

    if (valor == null || valor <= 0) {
      setState(() {
        _erro = 'Informe um valor maior que zero';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final descricao = _descricaoCtrl.text.trim();

    final dados = {
      'tipo': _tipo,
      'categoria_id': _categoriaId,
      'descricao': descricao.isEmpty ? null : descricao,
      'valor': valor,
      'data': formatarDataIso(_data),
    };

    try {
      await ref
          .read(financeiroRepositoryProvider)
          .criarMovimentacao(dados);

      // Mantém o mês do lançamento selecionado.
      ref
          .read(mesSelecionadoProvider.notifier)
          .definir(_data);

      ref.invalidate(movimentacoesDoMesProvider);
      ref.invalidate(resumoDoMesProvider);

      if (mounted) {
        context.pop();
      }
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

  // --------------------------------------------------
  // Decoração dos campos
  // --------------------------------------------------

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
    String? prefixo,
  }) {
    OutlineInputBorder criarBorda(
      Color cor,
      double largura,
    ) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cor,
          width: largura,
        ),
      );
    }

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: _textoSecundario,
      ),
      prefixIcon: Icon(
        icone,
        size: 20,
        color: _textoSecundario,
      ),
      prefixText: prefixo,
      prefixStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _texto,
      ),
      filled: true,
      fillColor: _superficie,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: criarBorda(_borda, 1),
      enabledBorder: criarBorda(_borda, 1),
      focusedBorder: criarBorda(_destaque, 1.5),
    );
  }

  // --------------------------------------------------
  // Seletor de receita ou despesa
  // --------------------------------------------------

  Widget _seletorTipo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tipo de lançamento',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _texto,
          ),
        ),

        const SizedBox(height: 12),

        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _corTipo,
              primary: _corTipo,
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'despesa',
                  label: Text('Despesa'),
                  icon: Icon(
                    Icons.arrow_downward_rounded,
                  ),
                ),
                ButtonSegment(
                  value: 'receita',
                  label: Text('Receita'),
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                  ),
                ),
              ],
              selected: {_tipo},
              showSelectedIcon: false,
              style: ButtonStyle(
                side: WidgetStateProperty.all(
                  const BorderSide(color: _borda),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              onSelectionChanged: (escolha) {
                setState(() {
                  _tipo = escolha.first;

                  // Cada categoria pertence a um tipo.
                  _categoriaId = null;
                  _erro = null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // Campo de categoria
  // --------------------------------------------------

  Widget _campoCategoria(
    List<DropdownMenuEntry<int>> entradas,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownMenu<int>(
          // Recria o campo quando muda o tipo
          // ou a categoria selecionada.
          key: ValueKey('$_tipo-$_categoriaId'),
          label: const Text('Categoria *'),
          leadingIcon: const Icon(
            Icons.category_outlined,
            color: _textoSecundario,
          ),
          expandedInsets: EdgeInsets.zero,
          initialSelection: _categoriaId,
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
          dropdownMenuEntries: entradas,
          onSelected: (valor) {
            setState(() {
              _categoriaId = valor;
              _erro = null;
            });
          },
        ),

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _novaCategoria,
            style: TextButton.styleFrom(
              foregroundColor: _destaque,
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              size: 19,
            ),
            label: const Text(
              'Nova categoria',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // Seletor de data
  // --------------------------------------------------

  Widget _campoData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data do lançamento',
          style: TextStyle(
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
            onPressed: _escolherData,
            icon: const Icon(
              Icons.calendar_today_outlined,
              size: 19,
              color: _destaque,
            ),
            label: Text(
              formatarData(_data),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _texto,
              backgroundColor: _superficie,
              side: const BorderSide(color: _borda),
              alignment: Alignment.centerLeft,
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

  // --------------------------------------------------
  // Mensagem de erro
  // --------------------------------------------------

  Widget _mensagemErro() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _despesa.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _despesa,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _erro!,
              style: const TextStyle(
                fontSize: 13,
                color: _despesa,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Tela principal
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final todas =
        ref.watch(categoriasProvider).asData?.value ?? [];

    final categorias = todas
        .where((c) => c.tipo == _tipo)
        .toList();

    final entradas = [
      for (final c in categorias)
        DropdownMenuEntry<int>(
          value: c.id,
          label: c.nome,
        ),
    ];

    return Scaffold(
      backgroundColor: _fundo,

      appBar: AppBar(
        backgroundColor: _fundo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: _texto,
        ),
        title: const Text(
          'Novo lançamento',
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
            padding: const EdgeInsets.fromLTRB(
              16, 16, 16, 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borda),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho
                    const Text(
                      'Informações do lançamento',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: _texto,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Registre uma receita ou despesa '
                      'para manter o controle financeiro.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textoSecundario,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Receita ou despesa
                    _seletorTipo(),

                    const SizedBox(height: 24),

                    // Categoria
                    _campoCategoria(entradas),

                    const SizedBox(height: 16),

                    // Valor
                    TextField(
                      controller: _valorCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _decoracaoCampo(
                        label: 'Valor *',
                        icone: Icons.payments_outlined,
                        prefixo: 'R\$ ',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descrição
                    TextField(
                      controller: _descricaoCtrl,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: _decoracaoCampo(
                        label: 'Descrição',
                        icone: Icons.notes_rounded,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Data
                    _campoData(),

                    const SizedBox(height: 28),

                    // Erro
                    if (_erro != null) ...[
                      _mensagemErro(),
                      const SizedBox(height: 16),
                    ],

                    // Salvar
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed:
                            _carregando ? null : _salvar,
                        style: FilledButton.styleFrom(
                          backgroundColor: _destaque,
                          foregroundColor: _texto,
                          disabledBackgroundColor:
                              _destaque.withValues(
                                alpha: 0.5,
                              ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
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
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _texto,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                                size: 20,
                              ),
                        label: Text(
                          _carregando
                              ? 'Salvando...'
                              : 'Salvar lançamento',
                        ),
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