import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langue de l'application, conservée localement sur l'appareil.
///
/// Français par défaut (langue de référence du produit) ; l'utilisateur
/// peut basculer sur l'anglais depuis les paramètres.
class LocaleProvider extends ChangeNotifier {
  static const _preferenceKey = 'flowday.locale';
  static const Locale french = Locale('fr');
  static const Locale english = Locale('en');

  Locale _locale = french;
  Locale get locale => _locale;

  bool get isEnglish => _locale.languageCode == english.languageCode;

  /// Libellé natif de la langue courante.
  String get languageName => isEnglish ? 'English' : 'Français';

  Future<void> restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_preferenceKey);
      final restored = stored == english.languageCode ? english : french;
      if (_locale == restored) return;
      _locale = restored;
      notifyListeners();
    } catch (_) {
      // Stockage indisponible : la langue reste en mémoire.
    }
  }

  Future<void> setLocale(Locale locale) async {
    final next = locale.languageCode == english.languageCode ? english : french;
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, next.languageCode);
    } catch (_) {
      // Le changement courant reste appliqué jusqu'à la fermeture de l'app.
    }
  }

  Future<void> setLanguageCode(String code) =>
      setLocale(code == english.languageCode ? english : french);
}
