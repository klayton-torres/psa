import 'package:flutter/material.dart';
import 'package:peladeiros_sa/core/constants/app_colors.dart';
import 'package:peladeiros_sa/core/theme/app_themes.dart';
import 'package:peladeiros_sa/services/app_preferences_service.dart';

class ThemeProvider with ChangeNotifier {
  final AppPreferencesService? prefs;
  bool _applyingPrefs = false;

  ThemeProvider({this.prefs}) {
    if (prefs != null) {
      prefs!.addListener(_onPrefsChanged);
      _applyPrefsInitial();
    }
  }

  int _themeIndex = 0;
  bool _isDarkMode = false;

  int get themeIndex => _themeIndex;
  bool get isDarkMode => _isDarkMode;

  int _safeThemeIndex(int candidate) {
    final colors = AppColors.themeColors;
    final names = AppColors.themeNames;
    final len = colors.isEmpty ? 0 : colors.length;
    final maxNames = names.isEmpty ? 0 : names.length;
    final maxIdx = len < maxNames ? len : maxNames;
    if (maxIdx <= 0) return 0;
    if (candidate < 0) return 0;
    if (candidate >= maxIdx) return 0;
    return candidate;
  }

  Color get currentPrimary {
    final idx = _safeThemeIndex(_themeIndex);
    if (AppColors.themeColors.isEmpty) return const Color(0xFF00BFA6);
    return AppColors.themeColors[idx];
  }

  String get currentThemeName {
    final idx = _safeThemeIndex(_themeIndex);
    if (AppColors.themeNames.isEmpty) return 'Turquesa';
    return AppColors.themeNames[idx];
  }
  List<Color> get paletteColors => AppColors.themeColors;
  List<String> get paletteNames => AppColors.themeNames;

  double get textScaleFactor =>
      prefs?.textScaleFactor ?? AppPreferencesService.defaultTextScale;
  int get textScalePctInt =>
      prefs?.textScalePctInt ??
      (AppPreferencesService.defaultTextScale * 100).round();

  ThemeData get currentTheme {
    return AppThemes.buildTheme(
      primaryColor: currentPrimary,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    );
  }

  int _clampIndex(int idx) {
    final len = AppColors.themeColors.length;
    if (len <= 0) return 0;
    return idx.clamp(0, len - 1);
  }

  void _applyPrefsInitial() {
    _themeIndex = _clampIndex(prefs?.themeIndex ?? 0);
    _isDarkMode = prefs?.darkMode ?? false;
    notifyListeners();
  }

  void _onPrefsChanged() {
    if (_applyingPrefs) return;
    var changed = false;
    final newIdx = _clampIndex(prefs?.themeIndex ?? 0);
    if (newIdx != _themeIndex) {
      _themeIndex = newIdx;
      changed = true;
    }
    final newDark = prefs?.darkMode ?? false;
    if (newDark != _isDarkMode) {
      _isDarkMode = newDark;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> setThemeIndex(int index) async {
    final clamped = _clampIndex(index);
    if (clamped == _themeIndex) return;
    _themeIndex = clamped;
    notifyListeners();
    if (prefs == null) return;
    _applyingPrefs = true;
    try {
      await prefs!.setThemeIndex(clamped, maxLen: AppColors.themeColors.length);
    } finally {
      _applyingPrefs = false;
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    if (prefs == null) return;
    _applyingPrefs = true;
    try {
      await prefs!.setDarkMode(_isDarkMode);
    } finally {
      _applyingPrefs = false;
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    if (prefs == null) return;
    _applyingPrefs = true;
    try {
      await prefs!.setDarkMode(value);
    } finally {
      _applyingPrefs = false;
    }
  }

  Future<bool> aumentarFonte() async {
    final ok = await prefs?.aumentarFonte() ?? false;
    if (ok) notifyListeners();
    return ok;
  }

  Future<bool> diminuirFonte() async {
    final ok = await prefs?.diminuirFonte() ?? false;
    if (ok) notifyListeners();
    return ok;
  }

  Future<bool> resetFonte() async {
    final before = textScaleFactor;
    await prefs?.resetFonte();
    final after = textScaleFactor;
    if ((after - before).abs() > 0.001) {
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    prefs?.removeListener(_onPrefsChanged);
    super.dispose();
  }
}
