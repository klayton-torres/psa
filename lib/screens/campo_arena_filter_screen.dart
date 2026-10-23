import 'package:flutter/material.dart';

import '../models/campo_arena.dart';
import '../models/enums.dart';
import '../widgets/estado_cidade_fields.dart';
import '../widgets/horarios_disponiveis_table.dart';

@immutable
class CampoArenaFilter {
  final String cidade;
  final String bairro;
  final String uf;
  final int? quantidadePorLinha;
  final TipoGrama? tipoGrama;
  final Set<TipoChuteira> calcados;
  final Set<DependenciaCampo> dependencias;
  final Set<String> horarios;

  const CampoArenaFilter({
    this.cidade = '',
    this.bairro = '',
    this.uf = '',
    this.quantidadePorLinha,
    this.tipoGrama,
    this.calcados = const {},
    this.dependencias = const {},
    this.horarios = const {},
  });

  int get activeFiltersCount =>
      (cidade.trim().isNotEmpty ? 1 : 0) +
      (bairro.trim().isNotEmpty ? 1 : 0) +
      (uf.trim().isNotEmpty ? 1 : 0) +
      (quantidadePorLinha != null ? 1 : 0) +
      (tipoGrama != null ? 1 : 0) +
      (calcados.isNotEmpty ? 1 : 0) +
      (dependencias.isNotEmpty ? 1 : 0) +
      (horarios.isNotEmpty ? 1 : 0);

  bool matches(CampoArena campo) {
    final cidadeBusca = cidade.trim().toLowerCase();
    final bairroBusca = bairro.trim().toLowerCase();
    return (cidadeBusca.isEmpty || campo.cidade.toLowerCase().contains(cidadeBusca)) &&
        (bairroBusca.isEmpty || campo.bairro.toLowerCase().contains(bairroBusca)) &&
        (uf.trim().isEmpty || campo.estado.toUpperCase() == uf.trim().toUpperCase()) &&
        (quantidadePorLinha == null || campo.quantidadePorLinha == quantidadePorLinha) &&
        (tipoGrama == null || campo.tipoGrama == tipoGrama) &&
        (calcados.isEmpty || campo.calcadosPermitidos.containsAll(calcados)) &&
        (dependencias.isEmpty || campo.dependencias.containsAll(dependencias)) &&
        (horarios.isEmpty || campo.horariosDisponiveis.containsAll(horarios));
  }
}

class CampoArenaFilterScreen extends StatefulWidget {
  final CampoArenaFilter initialFilter;

  const CampoArenaFilterScreen({
    super.key,
    this.initialFilter = const CampoArenaFilter(),
  });

  @override
  State<CampoArenaFilterScreen> createState() => _CampoArenaFilterScreenState();
}

class _CampoArenaFilterScreenState extends State<CampoArenaFilterScreen> {
  late final TextEditingController _cidadeController;
  late final TextEditingController _bairroController;
  late final TextEditingController _ufController;
  int? _quantidadePorLinha;
  TipoGrama? _tipoGrama;
  late Set<DependenciaCampo> _dependencias;
  late Set<TipoChuteira> _calcados;
  late Set<String> _horarios;

  @override
  void initState() {
    super.initState();
    _cidadeController = TextEditingController(text: widget.initialFilter.cidade);
    _bairroController = TextEditingController(text: widget.initialFilter.bairro);
    _ufController = TextEditingController(text: widget.initialFilter.uf);
    _quantidadePorLinha = widget.initialFilter.quantidadePorLinha;
    _tipoGrama = widget.initialFilter.tipoGrama;
    _dependencias = {...widget.initialFilter.dependencias};
    _calcados = {...widget.initialFilter.calcados};
    _horarios = {...widget.initialFilter.horarios};
  }

  @override
  void dispose() {
    _cidadeController.dispose();
    _bairroController.dispose();
    _ufController.dispose();
    super.dispose();
  }

  void _limpar() {
    setState(() {
      _cidadeController.clear();
      _bairroController.clear();
      _ufController.clear();
      _quantidadePorLinha = null;
      _tipoGrama = null;
      _dependencias.clear();
      _calcados.clear();
      _horarios.clear();
    });
  }

  void _aplicar() {
    Navigator.pop(
      context,
      CampoArenaFilter(
        cidade: _cidadeController.text,
        bairro: _bairroController.text,
        uf: _ufController.text,
        quantidadePorLinha: _quantidadePorLinha,
        tipoGrama: _tipoGrama,
        dependencias: Set.unmodifiable(_dependencias),
        calcados: Set.unmodifiable(_calcados),
        horarios: Set.unmodifiable(_horarios),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrar campos e arenas'),
        actions: [TextButton(onPressed: _limpar, child: const Text('Limpar'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            EstadoUfDropdown(
              controller: _ufController,
              cidadeController: _cidadeController,
              label: 'UF',
              allowNone: true,
              noneLabel: 'Todos os estados',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            CidadeMunicipioAutocompleteField(
              key: ValueKey('cidade-${_ufController.text}'),
              uf: _ufController.text,
              controller: _cidadeController,
              decoration: const InputDecoration(
                labelText: 'Cidade',
                prefixIcon: Icon(Icons.location_city_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bairroController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Bairro',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Tamanho do campo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [3, 4, 5, 6, 7, 8, 9, 10].map((qtd) {
                return ChoiceChip(
                  label: Text('${qtd}x$qtd'),
                  selected: _quantidadePorLinha == qtd,
                  onSelected: (selected) => setState(
                    () => _quantidadePorLinha = selected ? qtd : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<TipoGrama?>(
              value: _tipoGrama,
              decoration: const InputDecoration(
                labelText: 'Tipo de grama / piso',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<TipoGrama?>(
                  value: null,
                  child: Text('Todos os tipos'),
                ),
                ...TipoGrama.values.map(
                  (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo.label)),
                ),
              ],
              onChanged: (value) => setState(() => _tipoGrama = value),
            ),
            const SizedBox(height: 20),
            Text('Tipo de calçado permitido', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: TipoChuteira.values.map((tipo) => FilterChip(
                label: Text(tipo.label),
                selected: _calcados.contains(tipo),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _calcados.add(tipo);
                  } else {
                    _calcados.remove(tipo);
                  }
                }),
              )).toList(),
            ),
            const SizedBox(height: 20),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Dependências', style: theme.textTheme.titleMedium),
              subtitle: Text(_dependencias.isEmpty
                  ? 'Todas'
                  : '${_dependencias.length} selecionada(s)'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: DependenciaCampo.values.map((dependencia) => FilterChip(
                      label: Text(dependencia.label),
                      selected: _dependencias.contains(dependencia),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _dependencias.add(dependencia);
                        } else {
                          _dependencias.remove(dependencia);
                        }
                      }),
                    )).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Horários disponíveis', style: theme.textTheme.titleMedium),
              subtitle: Text(_horarios.isEmpty
                  ? 'Qualquer horário'
                  : '${_horarios.length} horário(s) selecionado(s)'),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HorariosDisponiveisTable(
                    horariosSelecionados: _horarios,
                    onToggle: (horario) => setState(() {
                      if (!_horarios.add(horario)) {
                        _horarios.remove(horario);
                      }
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _aplicar,
              icon: const Icon(Icons.filter_list_rounded),
              label: const Text('Aplicar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
