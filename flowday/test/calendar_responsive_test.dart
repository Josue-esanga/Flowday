import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/features/calendar/presentation/calendar_screen.dart';

void main() {
  // Vérifie que la page calendrier ne déborde sur aucune taille d'écran.
  const sizes = <String, Size>{
    'petit téléphone (320x568)': Size(320, 568),
    'téléphone standard (390x844)': Size(390, 844),
    'tablette (768x1024)': Size(768, 1024),
    'desktop (1280x800)': Size(1280, 800),
  };

  for (final entry in sizes.entries) {
    testWidgets('Calendrier responsive — ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CalendarScreen()),
        ),
      );

      // Aucun débordement (RenderFlex overflow) ni autre exception.
      expect(tester.takeException(), isNull);

      // La grille et le résumé sont bien présents.
      expect(find.text('Calendrier'), findsOneWidget);
      expect(find.text('June 2026'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('Friday, June 28'), findsOneWidget);

      // Défilement jusqu'au résumé du jour.
      await tester.scrollUntilVisible(
        find.text('Friday, June 28'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
