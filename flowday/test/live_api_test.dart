import 'dart:io';

import 'package:flowday/core/errors/api_exception.dart';
import 'package:flowday/core/providers/auth_provider.dart';
import 'package:flowday/shared/data/task_repository.dart';
import 'package:flowday/shared/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// Intégration **réelle** avec la base Supabase (accès direct PostgREST +
/// authentification GoTrue) : vérifie le contrat exact des données
/// (formats de date/heure, catégories, CRUD, toggle, stats) tel que
/// consommé par `TaskRepository`, connecté au compte de test.
///
/// Lancement (clé, URL du projet et compte de test embarqués, aucun
/// serveur ni surcharge nécessaire) :
/// ```sh
/// FLOWDAY_LIVE=1 flutter test test/live_api_test.dart
/// ```
void main() {
  final enabled =
      const bool.fromEnvironment('FLOWDAY_LIVE') ||
      (Platform.environment['FLOWDAY_LIVE'] ?? '') == '1';

  group(
    'API réelle (Supabase PostgREST)',
    () {
      test('connexion, catégories, CRUD, toggle et stats', () async {
        // Authentification : RLS n'autorise que les tâches du compte.
        final auth = AuthProvider(persist: false);
        final signInError = await auth.signIn(
          email: 'flowday.test@gmail.com',
          password: 'Flowday!Test2026',
        );
        expect(signInError, isNull, reason: 'connexion du compte de test');
        expect(auth.isAuthenticated, isTrue);

        final repo = TaskRepository(auth: auth);
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
        expect(workTasks.map((t) => t.category.id).toSet(), {
          'work',
        }, reason: '?category=work ne retourne que des tâches work');

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
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
          ),
        );
      }, timeout: Timeout(const Duration(seconds: 30)));

      test('profil : nom et photo mis à jour via PUT /user', () async {
        // Connexion du compte de test.
        final auth = AuthProvider(persist: false);
        final signInError = await auth.signIn(
          email: 'flowday.test@gmail.com',
          password: 'Flowday!Test2026',
        );
        expect(signInError, isNull, reason: 'connexion du compte de test');

        // Valeurs initiales (remises en place à la fin).
        final originalName = auth.fullName;
        final originalAvatar = auth.avatar;

        // Mise à jour du nom → visible immédiatement dans le provider.
        const newName = 'Live Profile';
        final nameError = await auth.updateProfile(
          metadata: const {'full_name': newName},
        );
        expect(nameError, isNull, reason: 'PUT /user (nom)');
        expect(auth.fullName, newName);

        // Photo de profil : data-URL PNG minuscule puis retrait.
        const tinyAvatar =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGP4UiaPFTEMLQkAmUJiQV5sAqkAAAAASUVORK5CYII=';
        final avatarError = await auth.updateProfile(
          metadata: const {'avatar': tinyAvatar},
        );
        expect(avatarError, isNull, reason: 'PUT /user (photo)');
        expect(auth.avatar, tinyAvatar);

        // Restauration exacte de l'état initial.
        final restoreError = await auth.updateProfile(
          metadata: {'full_name': originalName, 'avatar': originalAvatar},
        );
        expect(restoreError, isNull, reason: 'PUT /user (restauration)');
        expect(auth.fullName, originalName);
        expect(auth.avatar, originalAvatar);
      }, timeout: Timeout(const Duration(seconds: 30)));
    },
    skip: enabled ? false : 'Accès direct requis : lancez FLOWDAY_LIVE=1 flutter test test/live_api_test.dart',
  );
}
