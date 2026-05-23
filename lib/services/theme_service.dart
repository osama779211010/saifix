import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('ar');
  Color _accentColor = const Color(0xFF173BA2); // Default secondaryBlue

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  Color get accentColor => _accentColor;

  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'app_locale';
  static const String _accentKey = 'accent_color';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    } else {
      _locale = const Locale('ar');
    }

    final savedAccent = prefs.getInt(_accentKey);
    if (savedAccent != null) {
      _accentColor = Color(savedAccent);
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await prefs.setString(_themeKey, modeStr);
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, color.toARGB32());
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool isDarkModeActive(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}

final themeService = ThemeService();
