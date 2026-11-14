import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/theme/app_theme.dart';
import 'package:flowday/core/l10n/app_localizations.dart';
import 'package:flowday/core/providers/onboarding_provider.dart';
import 'package:flowday/features/onboarding/presentation/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('L’onboarding est mémorisé une seule fois', () async {
    final onboarding = OnboardingProvider();
    await onboarding.restore();
    expect(onboarding.needsOnboarding, isTrue);

    await onboarding.complete();
    expect(onboarding.isCompleted, isTrue);

    final stored = OnboardingProvider();
    await stored.restore();
    expect(stored.isCompleted, isTrue);
  });

  testWidgets('Onboarding compact jusqu’au choix des notifications', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final onboarding = OnboardingProvider(initialValue: false);
    await tester.pumpWidget(
      ChangeNotifierProvider<OnboardingProvider>.value(
        value: onboarding,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur Flowday'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Trois pages de contenu puis la proposition de notifications.
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Ne manquez plus rien'), findsOneWidget);
    expect(
      find.byKey(const Key('onboarding-enable-notifications')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('onboarding-later')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('onboarding-later')));
    await tester.pumpAndSettle();
    expect(onboarding.isCompleted, isTrue);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('flowday.onboarding.completed'), isTrue);
  });
}
