import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/app.dart';

void main() {
  testWidgets("L'accueil affiche le nouveau design", (tester) async {
    await tester.pumpWidget(const FlowdayApp());

    // En-tête sombre + recherche + sections.
    expect(find.text('Hey Mobina !'), findsOneWidget);
    expect(find.text("Let's find your\nbest day!"), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);

    // La section « Today's task » est plus bas : on fait défiler.
    await tester.scrollUntilVisible(
      find.text("Today's task"),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("Today's task"), findsOneWidget);

    // « See all » ouvre la timeline (sélecteur de dates + timeline).
    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();

    expect(find.text('June 28, 2026'), findsOneWidget);
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
  });
}
