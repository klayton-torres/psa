import 'package:flutter/services.dart';

class UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = newValue.text.toUpperCase();
    return TextEditingValue(
      text: formatted,
      selection: newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset.clamp(0, formatted.length),
        extentOffset: newValue.selection.extentOffset.clamp(
          0,
          formatted.length,
        ),
      ),
      composing: TextRange.empty,
    );
  }
}

class TitleCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ' || char == '-' || char == "'" || char == '.') {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset.clamp(0, formatted.length),
        extentOffset: newValue.selection.extentOffset.clamp(
          0,
          formatted.length,
        ),
      ),
      composing: TextRange.empty,
    );
  }
}
