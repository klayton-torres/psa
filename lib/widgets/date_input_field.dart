import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/src/intl/date_format.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class DateInputField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final String? Function(DateTime?)? validator;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDatePicker;
  final bool enabled;
  final AutovalidateMode autovalidateMode;
  final bool showCalendarIcon;
  final bool Function(DateTime)? selectableDayPredicate;

  static bool _isSameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.value,
    this.onChanged,
    this.validator,
    this.labelText,
    this.hintText = 'dd/mm/aaaa',
    this.prefixIcon,
    this.suffix,
    DateTime? firstDate,
    DateTime? lastDate,
    this.initialDatePicker,
    this.enabled = true,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.showCalendarIcon = true,
    this.selectableDayPredicate,
    required DateFormat format,
    required InputDecoration decoration,
    required String dateLabel,
  }) : firstDate = firstDate ?? DateTime(1900),
       lastDate = lastDate ?? DateTime(2100);

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late final MaskTextInputFormatter _mask;
  DateTime? _lastValidValue;

  @override
  void initState() {
    super.initState();
    _mask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {'#': RegExp(r'[0-9]')},
    );
    final initialFromText = _parseDate(widget.controller.text);
    if (widget.value != null) {
      _lastValidValue = widget.value;
      if (widget.controller.text.isEmpty || initialFromText == null) {
        _applyMaskedDataFromDateTime(widget.value!);
      } else if (!DateInputField._isSameDate(initialFromText, widget.value)) {
        _applyMaskedDataFromDateTime(widget.value!);
      }
    } else if (initialFromText != null) {
      _lastValidValue = initialFromText;
    }
  }

  @override
  void didUpdateWidget(DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final valueChanged = !DateInputField._isSameDate(
      oldWidget.value,
      widget.value,
    );
    if (valueChanged &&
        !DateInputField._isSameDate(widget.value, _lastValidValue)) {
      _lastValidValue = widget.value;
      if (widget.value != null) {
        _applyMaskedDataFromDateTime(widget.value!);
      } else {
        widget.controller.clear();
      }
    }
  }

  DateTime? _parseDate(String text) {
    final unmasked = _mask.unmaskText(text);
    if (unmasked.length != 8) return null;
    final dia = int.tryParse(unmasked.substring(0, 2));
    final mes = int.tryParse(unmasked.substring(2, 4));
    final ano = int.tryParse(unmasked.substring(4, 8));
    if (dia == null || mes == null || ano == null) return null;
    try {
      final candidate = DateTime(ano, mes, dia);
      if (candidate.day != dia || candidate.month != mes) return null;
      if (ano < 1900) return null;
      final lastDateOnly = DateTime(
        widget.lastDate.year,
        widget.lastDate.month,
        widget.lastDate.day,
        23,
        59,
        59,
      );
      final firstDateOnly = DateTime(
        widget.firstDate.year,
        widget.firstDate.month,
        widget.firstDate.day,
      );
      if (candidate.isAfter(lastDateOnly)) return null;
      if (candidate.isBefore(firstDateOnly)) return null;
      return candidate;
    } catch (_) {
      return null;
    }
  }

  void _applyMaskedData(
    TextEditingController ctrl,
    MaskTextInputFormatter mask,
    String plainText,
  ) {
    final newValue = mask.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: plainText),
    );
    final len = newValue.text.length;
    ctrl.value = newValue.copyWith(
      selection: TextSelection.collapsed(offset: len),
      composing: TextRange.collapsed(len),
    );
  }

  void _applyMaskedDataFromDateTime(DateTime d) {
    final plain =
        '${d.day.toString().padLeft(2, '0')}${d.month.toString().padLeft(2, '0')}${d.year}';
    _applyMaskedData(widget.controller, _mask, plain);
  }

  void _onChangedHandler(String text) {
    final parsed = _parseDate(text);
    if (parsed != null) {
      _lastValidValue = parsed;
    }
    widget.onChanged?.call(parsed);
  }

  Future<void> _pickDate() async {
    final fallbackInitial =
        widget.lastDate.isBefore(
          DateTime.now().subtract(const Duration(days: 365 * 25)),
        )
        ? widget.lastDate
        : (widget.firstDate.isAfter(
                DateTime.now().subtract(const Duration(days: 365 * 25)),
              )
              ? widget.firstDate
              : DateTime.now().subtract(const Duration(days: 365 * 25)));
    final DateTime rawInitial =
        widget.value ?? widget.initialDatePicker ?? fallbackInitial;
    final DateTime firstDateOnly = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final DateTime lastDateOnly = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
      23,
      59,
      59,
    );
    final DateTime effectiveInitial;
    final DateTime rawInitialOnly = DateTime(
      rawInitial.year,
      rawInitial.month,
      rawInitial.day,
    );
    if (rawInitialOnly.isBefore(firstDateOnly)) {
      effectiveInitial = firstDateOnly;
    } else if (rawInitialOnly.isAfter(lastDateOnly)) {
      effectiveInitial = lastDateOnly;
    } else {
      effectiveInitial = rawInitialOnly;
    }
    final d = await showDatePicker(
      context: context,
      firstDate: firstDateOnly,
      lastDate: lastDateOnly,
      initialDate: effectiveInitial,
      locale: const Locale('pt', 'BR'),
      fieldHintText: 'dd/mm/aaaa',
      fieldLabelText: widget.labelText ?? 'Data',
      selectableDayPredicate: widget.selectableDayPredicate,
    );
    if (d == null) return;
    _lastValidValue = d;
    _applyMaskedDataFromDateTime(d);
    widget.onChanged?.call(d);
  }

  String? _validateHandler(String? v) {
    if (widget.validator == null) return null;
    final parsed = _parseDate(v ?? '');
    return widget.validator!(parsed);
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffix;
    Widget? effectiveSuffixIcon;
    if (widget.showCalendarIcon) {
      final calendarBtn = IconButton(
        tooltip: 'Selecionar data no calendário',
        icon: const Icon(Icons.calendar_month_outlined),
        onPressed: widget.enabled ? _pickDate : null,
      );
      if (widget.suffix != null) {
        effectiveSuffix = Row(
          mainAxisSize: MainAxisSize.min,
          children: [widget.suffix!, calendarBtn],
        );
      } else {
        effectiveSuffixIcon = calendarBtn;
      }
    } else {
      effectiveSuffix = widget.suffix;
    }
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _mask,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: _onChangedHandler,
      autovalidateMode: widget.autovalidateMode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: effectiveSuffixIcon,
        suffix: effectiveSuffix,
      ),
      validator: widget.validator != null ? _validateHandler : null,
    );
  }
}
