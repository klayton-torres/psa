import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:peladeiros_sa/widgets/app_drawer.dart';
import 'package:peladeiros_sa/widgets/profile_sports_rail_menu.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/pelada_filter.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/date_input_field.dart';
import 'cadastro_pelada_screen.dart';
import 'campos_arenas_screen.dart';
import 'home_screen.dart';
import '../utils/profile_navigation_helper.dart';
import '../widgets/estado_cidade_fields.dart';

class FiltersScreen extends StatefulWidget {
  final VoidCallback? onAplicar;
  const FiltersScreen({super.key, this.onAplicar});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late PeladaFilter _filtro;
  final _estadoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _localArenaCtrl = TextEditingController();
  final _dataInicioCtrl = TextEditingController();
  final _dataFimCtrl = TextEditingController();
  final _horaInicioCtrl = TextEditingController();
  final _horaFimCtrl = TextEditingController();

  Key? get _scaffoldKey => null;

  @override
  void initState() {
    super.initState();
    _filtro = Provider.of<DataService>(context, listen: false).currentFilter;
    _estadoCtrl.text = _filtro.estado ?? '';
    _cidadeCtrl.text = _filtro.cidade ?? '';
    _bairroCtrl.text = _filtro.bairro ?? '';
    _localArenaCtrl.text = _filtro.localArena ?? '';
    _horaInicioCtrl.text = _filtro.horarioInicio != null
        ? '${_filtro.horarioInicio!.hour.toString().padLeft(2, '0')}:${_filtro.horarioInicio!.minute.toString().padLeft(2, '0')}'
        : '';
    _horaFimCtrl.text = _filtro.horarioFim != null
        ? '${_filtro.horarioFim!.hour.toString().padLeft(2, '0')}:${_filtro.horarioFim!.minute.toString().padLeft(2, '0')}'
        : '';
  }

  @override
  void dispose() {
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _localArenaCtrl.dispose();
    _dataInicioCtrl.dispose();
    _dataFimCtrl.dispose();
    _horaInicioCtrl.dispose();
    _horaFimCtrl.dispose();
    super.dispose();
  }

  void _aplicar() {
    final cidade = _cidadeCtrl.text.trim();
    final bairro = _bairroCtrl.text.trim();
    final localArena = _localArenaCtrl.text.trim();
    final f = _filtro.copyWith(
      estado: _filtro.estado,
      cidade: cidade.isEmpty ? null : cidade,
      bairro: bairro.isEmpty ? null : bairro,
      localArena: localArena.isEmpty ? null : localArena,
    );
    Provider.of<DataService>(context, listen: false).setFilter(f);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Filtros aplicados!')));
    widget.onAplicar?.call();
  }

  void _limpar() {
    setState(() {
      _filtro = const PeladaFilter();
      _estadoCtrl.clear();
      _cidadeCtrl.clear();
      _bairroCtrl.clear();
      _localArenaCtrl.clear();
      _dataInicioCtrl.clear();
      _dataFimCtrl.clear();
      _horaInicioCtrl.clear();
      _horaFimCtrl.clear();
    });
    Provider.of<DataService>(context, listen: false).clearFilter();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Filtros limpos')));
  }

  Future<void> _pickTime(bool inicio) async {
    final t = await showTimePicker(
      context: context,
      initialTime: inicio
          ? (_filtro.horarioInicio ?? const TimeOfDay(hour: 8, minute: 0))
          : (_filtro.horarioFim ?? const TimeOfDay(hour: 22, minute: 0)),
      builder: (ctx, w) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: w!,
      ),
    );
    if (t == null) return;
    setState(() {
      if (inicio) {
        _filtro = _filtro.copyWith(horarioInicio: t, clearHorario: false);
        _horaInicioCtrl.text =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      } else {
        _filtro = _filtro.copyWith(horarioFim: t, clearHorario: false);
        _horaFimCtrl.text =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Filtros'),
        leading: Semantics(
          button: true,
          label: 'Voltar para a tela inicial',
          hint: 'Toque duas vezes para retornar a home',
          child: Tooltip(
            message: 'Voltar',
            preferBelow: false,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
              onPressed: () {
                unawaited(HapticFeedback.selectionClick());
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _limpar,
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              CustomBottomNavBar.barHeight +
                  MediaQuery.paddingOf(context).bottom +
                  48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Localização', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 520;
                            final ufField = EstadoUfDropdown(
                              controller: _estadoCtrl,
                              cidadeController: _cidadeCtrl,
                              label: 'Estado',
                              allowNone: true,
                              noneLabel: 'Todos',
                              onChanged: (v) => setState(() {
                                _filtro = _filtro.copyWith(
                                  estado: v,
                                  clearEstado: v == null,
                                );
                              }),
                            );
                            final cidadeField =
                                CidadeMunicipioAutocompleteField(
                                  uf: _estadoCtrl.text,
                                  controller: _cidadeCtrl,
                                );
                            final bairroField = TextField(
                              controller: _bairroCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Bairro',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            );
                            final localArenaField = TextField(
                              controller: _localArenaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Local / Arena',
                                prefixIcon: Icon(Icons.sports_soccer_outlined),
                                hintText: 'Ex: Arena Center',
                              ),
                            );
                            if (compact) {
                              return Column(
                                children: [
                                  ufField,
                                  const SizedBox(height: 12),
                                  cidadeField,
                                  const SizedBox(height: 12),
                                  bairroField,
                                  const SizedBox(height: 12),
                                  localArenaField,
                                ],
                              );
                            }
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(width: 140, child: ufField),
                                    const SizedBox(width: 12),
                                    Expanded(child: cidadeField),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                bairroField,
                                const SizedBox(height: 12),
                                localArenaField,
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DateInputField(
                                controller: _dataInicioCtrl,
                                value: _filtro.dataInicio,
                                labelText: 'De',
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 2),
                                ),
                                onChanged: (d) => setState(() {
                                  _filtro = _filtro.copyWith(
                                    dataInicio: d,
                                    clearData: false,
                                  );
                                }),
                                format: DateFormat('yyyy-MM-dd'),
                                decoration: const InputDecoration(),
                                dateLabel: 'Data inicial',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DateInputField(
                                controller: _dataFimCtrl,
                                value: _filtro.dataFim,
                                labelText: 'Até',
                                firstDate: _filtro.dataInicio ?? DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 2),
                                ),
                                onChanged: (d) => setState(() {
                                  _filtro = _filtro.copyWith(
                                    dataFim: d,
                                    clearData: false,
                                  );
                                }),
                                format: DateFormat('yyyy-MM-dd'),
                                decoration: const InputDecoration(),
                                dateLabel: 'Data final',
                              ),
                            ),
                            if (_filtro.dataInicio != null ||
                                _filtro.dataFim != null)
                              IconButton(
                                onPressed: () => setState(() {
                                  _filtro = _filtro.copyWith(clearData: true);
                                  _dataInicioCtrl.clear();
                                  _dataFimCtrl.clear();
                                }),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('Horário', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _horaInicioCtrl,
                                readOnly: true,
                                onTap: () => _pickTime(true),
                                decoration: const InputDecoration(
                                  labelText: 'A partir de',
                                  prefixIcon: Icon(Icons.access_time_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _horaFimCtrl,
                                readOnly: true,
                                onTap: () => _pickTime(false),
                                decoration: const InputDecoration(
                                  labelText: 'Até às',
                                  prefixIcon: Icon(Icons.access_time_outlined),
                                ),
                              ),
                            ),
                            if (_filtro.horarioInicio != null ||
                                _filtro.horarioFim != null)
                              IconButton(
                                onPressed: () => setState(() {
                                  _filtro = _filtro.copyWith(
                                    clearHorario: true,
                                  );
                                  _horaInicioCtrl.clear();
                                  _horaFimCtrl.clear();
                                }),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dias da Semana',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Todos'),
                              selected: _filtro.diasSemana.isEmpty,
                              onSelected: (_) => setState(() {
                                _filtro = _filtro.copyWith(
                                  clearDiasSemana: true,
                                );
                              }),
                            ),
                            ...const [
                              MapEntry(1, 'Seg'),
                              MapEntry(2, 'Ter'),
                              MapEntry(3, 'Qua'),
                              MapEntry(4, 'Qui'),
                              MapEntry(5, 'Sex'),
                              MapEntry(6, 'Sáb'),
                              MapEntry(7, 'Dom'),
                            ].map(
                              (e) => FilterChip(
                                label: Text(e.value),
                                selected: _filtro.diasSemana.contains(e.key),
                                onSelected: (sel) => setState(() {
                                  final next = Set<int>.from(
                                    _filtro.diasSemana,
                                  );
                                  if (sel) {
                                    next.add(e.key);
                                  } else {
                                    next.remove(e.key);
                                  }
                                  _filtro = _filtro.copyWith(
                                    diasSemana: next,
                                    clearDiasSemana: false,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Categoria', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Todas'),
                              selected: _filtro.categoriasGenero.isEmpty,
                              onSelected: (_) => setState(() {
                                _filtro = _filtro.copyWith(
                                  clearCategoriasGenero: true,
                                );
                              }),
                            ),
                            ...CategoriaGenero.values.map(
                              (g) => FilterChip(
                                showCheckmark: false,
                                avatar: Icon(
                                  g == CategoriaGenero.fem
                                      ? Icons.female
                                      : Icons.male,
                                  size: 18,
                                ),
                                label: Text(g.label),
                                selected: _filtro.categoriasGenero.contains(g),
                                onSelected: (sel) => setState(() {
                                  final next = Set<CategoriaGenero>.from(
                                    _filtro.categoriasGenero,
                                  );
                                  if (sel) {
                                    next.add(g);
                                  } else {
                                    next.remove(g);
                                  }
                                  _filtro = _filtro.copyWith(
                                    categoriasGenero: next,
                                    clearCategoriasGenero: false,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Faixa Etária (Sub-Categoria)',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Todas'),
                              selected: _filtro.faixaEtaria == null,
                              onSelected: (_) => setState(() {
                                _filtro = _filtro.copyWith(
                                  clearFaixaEtaria: true,
                                );
                              }),
                            ),
                            ...CategoriaPelada.values.map(
                              (c) => FilterChip(
                                label: Text(c.label),
                                selected: _filtro.faixaEtaria == c,
                                onSelected: (sel) => setState(() {
                                  _filtro = _filtro.copyWith(
                                    faixaEtaria: sel ? c : null,
                                    clearFaixaEtaria: false,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo de Campo',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Todos'),
                              selected: _filtro.tipoCampo == null,
                              onSelected: (_) => setState(() {
                                _filtro = _filtro.copyWith(
                                  clearTipoCampo: true,
                                );
                              }),
                            ),
                            ...TipoGrama.values.map(
                              (c) => FilterChip(
                                label: Text(c.label),
                                selected: _filtro.tipoCampo == c,
                                onSelected: (sel) => setState(() {
                                  _filtro = _filtro.copyWith(
                                    tipoCampo: sel ? c : null,
                                    clearTipoCampo: false,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo de Chuteira',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Todos'),
                              selected: _filtro.tiposChuteira.isEmpty,
                              onSelected: (_) => setState(() {
                                _filtro = _filtro.copyWith(
                                  clearTipoChuteira: true,
                                );
                              }),
                            ),
                            ...TipoChuteira.values.map(
                              (c) => FilterChip(
                                label: Text(c.label),
                                selected: _filtro.tiposChuteira.contains(c),
                                onSelected: (sel) => setState(() {
                                  final next = Set<TipoChuteira>.from(
                                    _filtro.tiposChuteira,
                                  );
                                  if (sel) {
                                    next.add(c);
                                  } else {
                                    next.remove(c);
                                  }
                                  _filtro = _filtro.copyWith(
                                    tiposChuteira: next,
                                    clearTipoChuteira: false,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Modalidade', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: const Text('Todas'),
                              selected: _filtro.modalidades.isEmpty,
                              onSelected: (_) => setState(() {
                                _filtro = _filtro.copyWith(
                                  clearModalidades: true,
                                );
                              }),
                            ),
                            ...Modalidade.values.map(
                              (m) => FilterChip(
                                label: Text(m.label),
                                selected: _filtro.modalidades.contains(m),
                                onSelected: (sel) => setState(() {
                                  final next = Set<Modalidade>.from(
                                    _filtro.modalidades,
                                  );
                                  if (sel) {
                                    next.add(m);
                                  } else {
                                    next.remove(m);
                                  }
                                  _filtro = _filtro.copyWith(
                                    modalidades: next,
                                    clearModalidades: false,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _filtro.apenasAtivas == true,
                          onChanged: (v) => setState(() {
                            _filtro = _filtro.copyWith(apenasAtivas: v);
                          }),
                          title: const Text('Apenas peladas ativas'),
                          secondary: Icon(
                            Icons.check_circle_outline,
                            color: primary,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _filtro.apenasComVagas == true,
                          onChanged: (v) => setState(() {
                            _filtro = _filtro.copyWith(apenasComVagas: v);
                          }),
                          title: const Text('Apenas com vagas'),
                          subtitle: const Text('Não atingiram o quórum máximo'),
                          secondary: Icon(
                            Icons.event_seat_outlined,
                            color: primary,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _filtro.mostrarPassadas,
                          onChanged: (v) => setState(() {
                            _filtro = _filtro.copyWith(mostrarPassadas: v);
                          }),
                          title: const Text('Mostrar peladas passadas'),
                          subtitle: const Text(
                            'Disponíveis por até 15 dias após o término',
                          ),
                          secondary: Icon(Icons.history, color: primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Limpar todos os filtros aplicados',
                        hint: 'Toque duas vezes para limpar',
                        child: Tooltip(
                          message: 'Limpar filtros',
                          preferBelow: false,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              unawaited(HapticFeedback.selectionClick());
                              _limpar();
                            },
                            icon: const Icon(Icons.restore_outlined, size: 16),
                            label: const Text(
                              'LIMPAR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                              softWrap: false,
                              maxLines: 1,
                            ),
                            style: OutlinedButton.styleFrom(
                              fixedSize: const Size.fromHeight(52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Semantics(
                        button: true,
                        label: _filtro.activeFiltersCount > 0
                            ? 'Aplicar ${_filtro.activeFiltersCount} filtros selecionados'
                            : 'Aplicar os filtros selecionados',
                        hint: 'Toque duas vezes para confirmar',
                        child: Tooltip(
                          message: _filtro.activeFiltersCount > 0
                              ? 'Aplicar (${_filtro.activeFiltersCount})'
                              : 'Aplicar Filtros',
                          preferBelow: false,
                          child: FilledButton.icon(
                            onPressed: () {
                              unawaited(HapticFeedback.selectionClick());
                              _aplicar();
                            },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                            label: Text(
                              _filtro.activeFiltersCount > 0
                                  ? 'APLICAR (${_filtro.activeFiltersCount})'
                                  : 'APLICAR FILTROS',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              fixedSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: null,
      bottomNavigationBar: Builder(
        builder: (context) {
          final auth = context.watch<AuthService>();
          Widget? centerMenu;
          if (auth.isAuthenticated) {
            const buttonDiameter = CustomBottomNavBar.fabDiameter;
            const labelColumnWidth = 92.0;
            const labelGutter = 10.0;
            centerMenu = ProfileSportsRailMenu(
              buttonDiameter: buttonDiameter,
              verticalSpacing: 6,
              labelColumnWidth: labelColumnWidth,
              labelGutter: labelGutter,
              labelOffsetAdjust: const EdgeInsets.only(right: 6),
              notchDockedOffset: 0,
              activeButtonId: 'peladas',
              navBarHeight: CustomBottomNavBar.barHeight,
            );
          }
          return CustomBottomNavBar(
            selectedIndex: 2,
            customCenterMenu: centerMenu,
            showCenterHomeButton: !auth.isAuthenticated,
            onTabSelected: (i) async {
              switch (i) {
                case 0:
                  final a = context.read<AuthService>();
                  if (a.isAuthenticated) {
                    try {
                      unawaited(HapticFeedback.selectionClick());
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CadastroPeladaScreen(),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Não foi possível abrir cadastro: $e'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Faça login para cadastrar uma pelada.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  break;
                case 1:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialTab: 1),
                      ),
                      (r) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível navegar: $e'),
                      ),
                    );
                  }
                  break;
                case 2:
                  try {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CamposArenasScreen(),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Não foi possível abrir Campos: $e'),
                      ),
                    );
                  }
                  break;
                case 3:
                  await navigateToProfile(context);
                  break;
              }
            },
            tipoFavoritoBadge: TipoFavoritoBadge.peladas,
          );
        },
      ),
    );
  }
}
