import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('La langue choisie est conservée après un redémarrage', () async {
    SharedPreferences.setMockInitialValues({});

    final first = LocaleProvider();
    await first.restore();
    expect(first.locale.languageCode, 'fr');

    await first.setLanguageCode('en');

    // Nouvelle instance = redémarrage de l'application.
    final second = LocaleProvider();
    await second.restore();
    expect(second.locale.languageCode, 'en');
  });
}
