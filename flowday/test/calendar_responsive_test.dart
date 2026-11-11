import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/core/providers/tasks_provider.dart';
import 'package:flowday/features/calendar/presentation/calendar_screen.dart';
import 'package:flowday/shared/utils/date_utils.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_task_repository.dart';

void _noop() {}

void main() {
  final now = DateTime.now();
  final monthLabel = '${FlowDates.months[now.month - 1]} ${now.year}';
  final summaryLabel =
      '${FlowDates.weekdayName(now)}, ${FlowDates.months[now.month - 1]} ${now.day}';

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
        ChangeNotifierProvider<TasksProvider>(
          create: (_) =>
              TasksProvider(repository: FakeTaskRepository())..loadInitial(),
          child: const MaterialApp(
            home: Scaffold(
              body: CalendarScreen(onOpenTimeline: _noop),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aucun débordement (RenderFlex overflow) ni autre exception.
      expect(tester.takeException(), isNull);

      // La grille (mois réel) et le jour sélectionné sont bien présents.
      expect(find.text('Calendrier'), findsOneWidget);
      expect(find.text(monthLabel), findsOneWidget);
      expect(find.text('${now.day}'), findsOneWidget);

      // Défilement jusqu'au résumé du jour (données API).
      await tester.scrollUntilVisible(
        find.text(summaryLabel),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(summaryLabel), findsOneWidget);
      expect(find.text('Voir les tâches du jour'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
