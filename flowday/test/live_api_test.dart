import 'dart:io';

import 'package:flowday/core/errors/api_exception.dart';
import 'package:flowday/shared/data/task_repository.dart';
import 'package:flowday/shared/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// Intégration **réelle** avec la base Supabase (accès direct PostgREST) :
/// vérifie le contrat exact des données (formats de date/heure, catégories,
/// CRUD, toggle, stats) tel que consommé par `TaskRepository`.
///
/// Lancement (la clé et l'URL du projet sont embarquées dans
/// `SupabaseConfig`, aucune surcharge nécessaire) :
/// ```sh
/// FLOWDAY_LIVE=1 flutter test test/live_api_test.dart
/// ```
void main() {
  final enabled = const bool.fromEnvironment('FLOWDAY_LIVE') ||
      (Platform.environment['FLOWDAY_LIVE'] ?? '') == '1';

  group('API réelle (Supabase PostgREST)', () {
    test('catégories, CRUD, toggle et stats', () async {
      final repo = TaskRepository();
      final now = DateTime.now();
      final today = FlowDates.apiDate(now);

      // F7 — catégories seedées par la migration.
      final categories = await repo.fetchCategories();
      expect(categories, hasLength(4));
      expect(categories.map((c) => c.id), containsAll(['personal', 'work']));
      for (final c in categories) {
        expect(c.color.a, greaterThan(0), reason: '${c.id} couleur valide');
      }

      // F3 — création (format API : date AAAA-MM-JJ, heure HH:MM).
      final created = await repo.createTask(
        title: 'Intégration Flutter',
        description: 'Créé par le test live',
        date: today,
        time: '14:30',
        categoryId: 'work',
      );
      expect(created.time, '14:30');
      expect(created.date, today);
      expect(created.timeLabel, '02:30 PM');
      expect(created.completed, isFalse);

      // F1 — lister le jour.
      final dayTasks = await repo.fetchTasks(date: today);
      expect(
        dayTasks.map((t) => t.id),
        contains(created.id),
        reason: 'la tâche créée doit apparaître dans ?date=',
      );

      // F7 — filtre par catégorie (page « tâches de la catégorie »).
      final workTasks = await repo.fetchTasks(category: 'work');
      expect(workTasks.map((t) => t.id), contains(created.id));
      expect(
        workTasks.map((t) => t.category.id).toSet(),
        {'work'},
        reason: '?category=work ne retourne que des tâches work',
      );

      // F4 — modification.
      final updated = await repo.updateTask(
        created.id,
        title: 'Intégration Flutter (modifié)',
        time: '15:45',
      );
      expect(updated.title, 'Intégration Flutter (modifié)');
      expect(updated.time, '15:45');
      expect(updated.completed, isFalse);

      // F6 — toggle.
      final toggled = await repo.toggleTask(created.id);
      expect(toggled.completed, isTrue);
      final toggledBack = await repo.toggleTask(created.id);
      expect(toggledBack.completed, isFalse);

      // §3.5 — statistiques.
      final stats = await repo.fetchStats();
      expect(stats.totalTasks, greaterThan(0));
      expect(stats.successRate, inInclusiveRange(0, 100));

      // F5 — suppression.
      await repo.deleteTask(created.id);
      final afterDelete = await repo.fetchTasks(date: today);
      expect(afterDelete.map((t) => t.id), isNot(contains(created.id)));

      // Mutation sans ligne (déjà supprimée) → liste vide → 404.
      await expectLater(
        repo.deleteTask(created.id),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    }, timeout: Timeout(const Duration(seconds: 30)));
  }, skip: enabled ? false : 'Serveur API requis : lancez flowday_api puis FLOWDAY_LIVE=1');
}
