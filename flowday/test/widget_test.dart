import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/app.dart';
import 'package:flowday/core/providers/auth_provider.dart';
import 'package:flowday/shared/widgets/sheet_action_surface.dart';
import 'package:flowday/shared/widgets/theme_mode_switch.dart';
import 'package:flowday/shared/utils/date_utils.dart';

import 'fakes/fake_task_repository.dart';

void main() {
  testWidgets("L'accueil affiche le design et charge l'API", (tester) async {
    final repo = FakeTaskRepository();
    await tester.pumpWidget(
      FlowdayApp(repository: repo, auth: AuthProvider.authenticated()),
    );
    await tester.pumpAndSettle();

    // En-tête sombre + recherche + sections.
    expect(find.text('Hey Mobina !'), findsOneWidget);
    expect(find.text('Trouvons\nvotre meilleure journée !'), findsOneWidget);
    expect(find.text('Rechercher'), findsOneWidget);
    expect(find.text('Catégories'), findsOneWidget);

    // Catégories chargées depuis le faux repository (F7).
    expect(find.text('Personnel'), findsOneWidget);
    expect(find.text('Travail'), findsOneWidget);

    // Tâches du jour : on défile jusqu'à la première (F1).
    await tester.scrollUntilVisible(
      find.text('Meeting with Shakib'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tâche du jour'), findsOneWidget);
    expect(find.text('Meeting with Shakib'), findsOneWidget);

    // « See all » ouvre la timeline (sélecteur de dates + timeline).
    await tester.ensureVisible(find.text('Tout voir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout voir').first);
    await tester.pumpAndSettle();

    expect(find.text(FlowDates.displayDate(DateTime.now())), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('02:00 PM'), findsWidgets);
    expect(find.text('Prepare workplace'), findsOneWidget);

    // Retour au tableau de bord.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    // La section « Yesterday's task » est plus bas : on fait défiler.
    await tester.scrollUntilVisible(
      find.text('Tâche d’hier'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tâche d’hier'), findsOneWidget);

    // Onglet Profil : statistiques de l'API (faux repository : 12/30).
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Terminées'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);
  });

  testWidgets('Le changement de langue traduit toute l’interface', (
    tester,
  ) async {
    final repo = FakeTaskRepository();
    await tester.pumpWidget(
      FlowdayApp(repository: repo, auth: AuthProvider.authenticated()),
    );
    await tester.pumpAndSettle();

    // Onglet Paramètres → sélecteur de langue.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsOneWidget);

    await tester.tap(find.text('Langue de l’application'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Toute l'interface bascule en anglais.
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);

    // Le tableau de bord suit lui aussi la langue choisie.
    await tester.tap(find.byIcon(Icons.home_filled));
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Retour au français (l'application reste utilisable dans les 2 langues).
    await tester.tap(find.text('App language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsOneWidget);
  });

  testWidgets('Le sélecteur de rappel reste compact', (tester) async {
    final repo = FakeTaskRepository();
    await tester.pumpWidget(
      FlowdayApp(repository: repo, auth: AuthProvider.authenticated()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Rappel par défaut'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Rappel par défaut'));
    await tester.pumpAndSettle();

    expect(find.text('Personnaliser le délai'), findsOneWidget);

    // Les actions de la feuille sont de vraies surfaces blanches, sans
    // voile Material 3 ni ombre colorée.
    final surfaces = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(SheetActionSurface),
            matching: find.byType(Material),
          ),
        )
        .toList();
    expect(surfaces, isNotEmpty);
    for (final surface in surfaces) {
      expect(surface.color, Colors.white);
      expect(surface.surfaceTintColor, Colors.transparent);
      expect(surface.elevation, 0);
    }

    final sheet = tester.getSize(find.byType(BottomSheet));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    // La feuille est dimensionnée par son contenu (pas plein écran).
    expect(sheet.height, lessThan(screenHeight * 0.6));
  });

  testWidgets('Le thème sombre utilise le switch néomorphique', (tester) async {
    final repo = FakeTaskRepository();
    await tester.pumpWidget(
      FlowdayApp(repository: repo, auth: AuthProvider.authenticated()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(ThemeModeSwitch);
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<ThemeModeSwitch>(switchFinder).isDark, isFalse);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<ThemeModeSwitch>(switchFinder).isDark, isTrue);
    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
  });
}
