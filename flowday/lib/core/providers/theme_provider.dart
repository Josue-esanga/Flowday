import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférence d'apparence, conservée localement sur l'appareil.
class ThemeProvider extends ChangeNotifier {
  static const _preferenceKey = 'flowday.theme.dark';

  bool _isDark = false;
  bool get isDark => _isDark;

  Future<void> restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedValue = preferences.getBool(_preferenceKey) ?? false;
      if (_isDark == storedValue) return;
      _isDark = storedValue;
      notifyListeners();
    } catch (_) {
      // En cas d'indisponibilité du stockage, l'apparence reste en mémoire.
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_preferenceKey, value);
    } catch (_) {
      // Le changement courant reste appliqué jusqu'à la fermeture de l'app.
    }
  }
}
