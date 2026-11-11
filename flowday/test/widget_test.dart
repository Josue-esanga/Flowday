import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/app.dart';

void main() {
  testWidgets('L accueil affiche la maquette de départ', (tester) async {
    await tester.pumpWidget(const FlowdayApp());

    // Maquette 2 : en-tête, recherche, catégories, sections.
    expect(find.text('Hello Mobina!'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text("Today's task"), findsOneWidget);

    // « See all » ouvre la timeline (maquette 1).
    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();

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
