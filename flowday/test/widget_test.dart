import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/app.dart';
import 'package:flowday/core/providers/auth_provider.dart';
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
    expect(find.text("Let's find your\nbest day!"), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);

    // Catégories chargées depuis le faux repository (F7).
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);

    // Tâches du jour : on défile jusqu'à la première (F1).
    await tester.scrollUntilVisible(
      find.text('Meeting with Shakib'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("Today's task"), findsOneWidget);
    expect(find.text('Meeting with Shakib'), findsOneWidget);

    // « See all » ouvre la timeline (sélecteur de dates + timeline).
    await tester.ensureVisible(find.text('See all').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all').first);
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
      find.text("Yesterday's task"),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("Yesterday's task"), findsOneWidget);

    // Onglet Profil : statistiques de l'API (faux repository : 12/30).
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Tâches terminées'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Cette semaine'), findsOneWidget);
  });
}
