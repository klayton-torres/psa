import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService extends ChangeNotifier {
  static const _kThemeIndex = 'psa_theme_index_v1';
  static const _kDarkMode = 'psa_dark_mode_v1';
  static const _kTextScale = 'psa_text_scale_v1';

  static const double minTextScale = 0.80;
  static const double maxTextScale = 1.20;
  static const double defaultTextScale = 1.00;
  static const double textStep = 0.10;

  SharedPreferences? _prefs;
  bool _initialized = false;

  int _themeIndex = 0;
  bool _darkMode = false;
  double _textScale = defaultTextScale;

  int get themeIndex => _themeIndex;
  bool get darkMode => _darkMode;
  double get textScaleFactor => _textScale;
  double get textScalePctDouble => _textScale;
  int get textScalePctInt => (_textScale * 100).round();

  bool get initialized => _initialized;

  static double clampScale(double v) =>
      v.clamp(minTextScale, maxTextScale).toDouble();

  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _themeIndex = _prefs!.getInt(_kThemeIndex) ?? 0;
      _darkMode = _prefs!.getBool(_kDarkMode) ?? false;
      final rawScale = _prefs!.getDouble(_kTextScale) ?? defaultTextScale;
      _textScale = clampScale(rawScale);
    } catch (e) {
      debugPrint('AppPreferences.init falhou: $e');
      _themeIndex = 0;
      _darkMode = false;
      _textScale = defaultTextScale;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeIndex(int value, {int maxLen = 8}) async {
    final idx = value.clamp(0, maxLen - 1);
    if (idx == _themeIndex) return;
    _themeIndex = idx;
    await _prefs?.setInt(_kThemeIndex, _themeIndex);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    if (v == _darkMode) return;
    _darkMode = v;
    await _prefs?.setBool(_kDarkMode, _darkMode);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!_darkMode);
  }

  Future<bool> aumentarFonte() async {
    final next = clampScale(_textScale + textStep);
    if ((next - _textScale).abs() < 0.001) return false;
    _textScale = next;
    await _prefs?.setDouble(_kTextScale, _textScale);
    notifyListeners();
    return true;
  }

  Future<bool> diminuirFonte() async {
    final next = clampScale(_textScale - textStep);
    if ((next - _textScale).abs() < 0.001) return false;
    _textScale = next;
    await _prefs?.setDouble(_kTextScale, _textScale);
    notifyListeners();
    return true;
  }

  Future<void> resetFonte() async {
    await _setScale(defaultTextScale);
  }

  Future<void> _setScale(double v) async {
    final next = clampScale(v);
    if ((next - _textScale).abs() < 0.001) return;
    _textScale = next;
    await _prefs?.setDouble(_kTextScale, _textScale);
    notifyListeners();
  }

  Future<void> setString(String s, String base64encode) async {}

  void getAvatarCache(String trim) {}
}
