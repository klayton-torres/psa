import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00BFA6);
  static const Color primaryLight = Color(0xFF4DD7C2);
  static const Color primaryDark = Color(0xFF009C88);

  static const Color secondary = Color(0xFFFF8A65);
  static const Color secondaryLight = Color(0xFFFFB199);
  static const Color secondaryDark = Color(0xFFE66A43);

  static const Color graphite0 = Color(0xFF212529);
  static const Color graphite1 = Color(0xFF343A40);
  static const Color graphite2 = Color(0xFF495057);
  static const Color graphite3 = Color(0xFF6C757D);
  static const Color graphite4 = Color(0xFFADB5BD);
  static const Color graphite5 = Color(0xFFCED4DA);
  static const Color graphite6 = Color(0xFFDEE2E6);
  static const Color graphite7 = Color(0xFFE9ECEF);
  static const Color graphite8 = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);

  // Neutral surfaces shared by every screen and both appearance modes.
  static const Color canvasLight = Color(0xFFF3F7F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color fieldLight = Color(0xFFF7F9F8);
  static const Color outlineLight = Color(0xFFDCE5E2);
  static const Color textLight = Color(0xFF182421);
  static const Color mutedTextLight = Color(0xFF64736E);
  static const Color canvasDark = Color(0xFF101816);
  static const Color surfaceDark = Color(0xFF1A2421);
  static const Color fieldDark = Color(0xFF121B18);
  static const Color outlineDark = Color(0xFF34423D);
  static const Color textDark = Color(0xFFEAF2EE);
  static const Color mutedTextDark = Color(0xFFA6B3AD);

  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  static const List<Color> vestColors = [
    Color(0xFF28A745),
    Color(0xFF7ED321),
    Color(0xFFFFC107),
    Color(0xFF1976D2),
    Color(0xFF64B5F6),
    Color(0xFFFFFFFF),
    Color(0xFFDC3545),
    Color(0xFFFF80AB),
    Color(0xFF000000),
    Color(0xFF9E9E9E),
  ];

  static const List<String> vestColorNames = [
    'Verde',
    'Verde Claro',
    'Amarelo',
    'Azul',
    'Azul Claro',
    'Branco',
    'Vermelho',
    'Rosa',
    'Preto',
    'Cinza',
    'Personalizado',
    'Camisa/Sem Camisa',
    'Listrado Vermelho e Preto',
  ];

  static const List<Color> themeColors = [
    primary,
    Color(0xFF6C5CE7),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF2196F3),
    Color(0xFFE53935),
    Color(0xFFFFB300),
    Color(0xFF37474F),
  ];

  static const List<String> themeNames = [
    'Turquesa',
    'Roxo',
    'Coral',
    'Verde Água',
    'Azul',
    'Vermelho',
    'Amarelo',
    'Grafite',
  ];

  static Color get grafiteDarkBg => canvasDark;

  static Color get grafiteDarkCard => surfaceDark;

  static Color get secondaryColor => secondary;

  static Color get primaryColor => primary;
}

extension ColorSchemeCompat on ColorScheme {
  Color get surfaceContainerHighestSafe {
    try {
      return surfaceContainerHighest;
    } catch (_) {
      return brightness == Brightness.dark
          ? const Color(0xFF363B3E)
          : const Color(0xFFE7E0EC);
    }
  }
}

extension ColorCompat on Color {
  Color withAlphaSafe({required double alpha}) {
    final clamped = alpha.clamp(0.0, 1.0);
    return withValues(alpha: clamped);
  }

  Color withAlphaValue(int alpha) {
    final clamped = alpha.clamp(0, 255);
    return withAlpha(clamped);
  }
}
