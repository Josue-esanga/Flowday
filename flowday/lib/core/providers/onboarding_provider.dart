import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// État d'accueil de Flowday : l'onboarding n'est proposé qu'une seule fois.
///
/// `null` pendant la lecture du stockage (un splash blanc reste affiché),
/// `false` tant qu'il n'a pas été terminé, puis `true` définitivement.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({bool? initialValue}) : _completed = initialValue;

  static const _completedKey = 'flowday.onboarding.completed';

  bool? _completed;

  bool get isLoading => _completed == null;

  bool get needsOnboarding => _completed == false;

  bool get isCompleted => _completed == true;

  Future<void> restore() async {
    if (_completed != null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      _completed = preferences.getBool(_completedKey) ?? false;
    } catch (_) {
      // Stockage indisponible : ne pas bloquer l'application derrière un
      // onboarding qui ne pourrait pas mémoriser son achèvement.
      _completed = true;
    }
    notifyListeners();
  }

  Future<void> complete() async {
    if (_completed == true) return;
    _completed = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_completedKey, true);
    } catch (_) {
      // L'onboarding restera terminé pour la session courante.
    }
  }
}
