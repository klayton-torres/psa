import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../services/location_service.dart';
import '../utils/title_case_input_formatter.dart';

/// Seletor de UF que invalida a cidade quando o estado é alterado.
class EstadoUfDropdown extends StatelessWidget {
  const EstadoUfDropdown({
    required this.controller,
    required this.cidadeController,
    this.onChanged,
    this.label = 'Estado (UF)',
    this.prefixIcon = Icons.map_outlined,
    this.focusNode,
    this.validator,
    this.decoration,
    this.allowNone = false,
    this.noneLabel = 'Todos',
    super.key,
  });

  final TextEditingController controller;
  final TextEditingController cidadeController;
  final ValueChanged<String?>? onChanged;
  final String label;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;
  final bool allowNone;
  final String noneLabel;

  @override
  Widget build(BuildContext context) {
    final uf = controller.text.trim().toUpperCase();
    return DropdownButtonFormField<String>(
      key: ValueKey('estado-uf-$uf'),
      initialValue: AppConstants.estadosBrasil.contains(uf) ? uf : null,
      focusNode: focusNode,
      isExpanded: true,
      decoration:
          decoration ??
          InputDecoration(
            labelText: label,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          ),
      items: [
        if (allowNone)
          DropdownMenuItem<String>(value: null, child: Text(noneLabel)),
        ...AppConstants.estadosBrasil.map(
          (item) => DropdownMenuItem(value: item, child: Text(item)),
        ),
      ],
      validator: validator,
      onChanged: (value) {
        controller.text = value ?? '';
        cidadeController.clear();
        onChanged?.call(value);
      },
    );
  }
}

/// Campo pesquisável com municípios oficiais do IBGE para a UF selecionada.
class CidadeMunicipioAutocompleteField extends StatefulWidget {
  const CidadeMunicipioAutocompleteField({
    required this.uf,
    required this.controller,
    this.label = 'Cidade',
    this.hintText,
    this.prefixIcon = Icons.location_city_outlined,
    this.focusNode,
    this.validator,
    this.decoration,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final String uf;
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;
  final TextInputAction textInputAction;

  @override
  State<CidadeMunicipioAutocompleteField> createState() =>
      _CidadeMunicipioAutocompleteFieldState();
}

class _CidadeMunicipioAutocompleteFieldState
    extends State<CidadeMunicipioAutocompleteField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  List<String> _municipios = const [];
  late final TextEditingController _textController;
  late final FocusNode _ownedFocusNode;
  bool _carregando = false;
  String? _erro;
  int _requestId = 0;

  String get _uf => widget.uf.trim().toUpperCase();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.text);
    _ownedFocusNode = FocusNode();
    widget.controller.addListener(_sincronizarCampo);
    _carregarMunicipios();
  }

  @override
  void didUpdateWidget(covariant CidadeMunicipioAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sincronizarCampo);
      widget.controller.addListener(_sincronizarCampo);
      _sincronizarCampo();
    }
    if (oldWidget.uf.trim().toUpperCase() != _uf) {
      _municipios = const [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _carregarMunicipios();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sincronizarCampo);
    _textController.dispose();
    _ownedFocusNode.dispose();
    super.dispose();
  }

  void _sincronizarCampo() {
    final texto = widget.controller.text;
    if (_textController.text != texto) {
      _textController.value = TextEditingValue(
        text: texto,
        selection: TextSelection.collapsed(offset: texto.length),
      );
    }
    _fieldKey.currentState?.didChange(texto);
  }

  Future<void> _carregarMunicipios() async {
    final requestId = ++_requestId;
    if (_uf.isEmpty) {
      setState(() {
        _municipios = const [];
        _carregando = false;
        _erro = null;
      });
      return;
    }
    setState(() {
      _municipios = const [];
      _carregando = true;
      _erro = null;
    });
    try {
      final municipios = await LocationService.buscarMunicipiosPorUf(_uf);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _municipios = municipios;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _carregando = false;
        _erro = 'Falha ao carregar as cidades.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (field) => RawAutocomplete<String>(
        key: ValueKey('cidade-municipios-$_uf'),
        textEditingController: _textController,
        focusNode: widget.focusNode ?? _ownedFocusNode,
        optionsViewBuilder: (context, onSelected, options) {
          final highlightedIndex = AutocompleteHighlightedOption.of(context);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final cidade = options.elementAt(index);
                    return ListTile(
                      key: ValueKey(cidade),
                      title: Text(cidade),
                      selected: index == highlightedIndex,
                      onTap: () => onSelected(cidade),
                    );
                  },
                ),
              ),
            ),
          );
        },
        optionsBuilder: (value) {
          if (_uf.isEmpty || _municipios.isEmpty) {
            return const Iterable<String>.empty();
          }
          final consulta = value.text.trim().toLowerCase();
          final resultados = consulta.isEmpty
              ? _municipios
              : _municipios.where(
                  (cidade) => cidade.toLowerCase().contains(consulta),
                );
          return resultados.take(20);
        },
        onSelected: (cidade) {
          widget.controller.text = cidade;
          field.didChange(cidade);
        },
        fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
          final defaultDecoration = InputDecoration(
            labelText: widget.label,
            hintText:
                widget.hintText ??
                (_uf.isEmpty
                    ? 'Selecione o estado primeiro'
                    : 'Digite para buscar'),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon),
          );
          final decoration = (widget.decoration ?? defaultDecoration).copyWith(
            errorText: field.errorText,
            helperText: field.errorText == null
                ? (_carregando ? 'Carregando cidades...' : _erro)
                : null,
            suffixIcon: _carregando
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _erro != null
                ? IconButton(
                    tooltip: 'Tentar carregar cidades novamente',
                    onPressed: _carregarMunicipios,
                    icon: const Icon(Icons.refresh),
                  )
                : widget.decoration?.suffixIcon,
          );
          return TextField(
            controller: textController,
            focusNode: focusNode,
            enabled: _uf.isNotEmpty,
            textInputAction: widget.textInputAction,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseInputFormatter()],
            onChanged: (cidade) {
              widget.controller.text = cidade;
              field.didChange(cidade);
            },
            onSubmitted: (_) => onSubmitted(),
            decoration: decoration,
          );
        },
      ),
    );
  }
}
