import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themePreferenceKey = 'app_theme_mode_preference';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // výchozí

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemePreference(); // Načtení uloženého nastavení při startu
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? savedThemeIndex = prefs.getInt(_themePreferenceKey);

      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      } else {
        _themeMode = ThemeMode.light;
      }
    } catch (e) {
      print("Error loading theme preference: $e");
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePreferenceKey, mode.index);
    } catch (e) {
      print("Error saving theme preference: $e");
    }
  }

  Future<void> toggleTheme(bool isDarkModeOn) async {
    await setThemeMode(isDarkModeOn ? ThemeMode.dark : ThemeMode.light);
  }
}
