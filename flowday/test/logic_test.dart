import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/app.dart';
import 'package:flowday/features/tasks/presentation/category_tasks_screen.dart';
import 'package:flowday/features/tasks/presentation/task_form_screen.dart';
import 'package:flowday/shared/widgets/timeline_tile.dart';

import 'fakes/fake_task_repository.dart';

/// Tests de logique bout en bout (F3 → F6) avec un faux repository :
/// l'UI appelle bien le provider → repository → API (simulée).
void main() {
  late FakeTaskRepository repo;

  /// Champs du formulaire — l'accueil possède aussi un champ de recherche.
  final formFields = find.descendant(
    of: find.byType(TaskFormScreen),
    matching: find.byType(TextField),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    repo = FakeTaskRepository();
    await tester.pumpWidget(FlowdayApp(repository: repo));
    await tester.pumpAndSettle();
  }

  testWidgets('F3 — création réelle depuis le formulaire', (tester) async {
    await pumpApp(tester);

    // Bouton (+) central de la barre de navigation.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);

    await tester.enterText(formFields.first, 'Réunion équipe');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // La tâche est bien créée via le repository et le formulaire se ferme.
    expect(repo.createdTasks, hasLength(1));
    expect(repo.createdTasks.single.title, 'Réunion équipe');
    expect(find.text('New task'), findsNothing);

    // Revenir en haut puis retrouver la nouvelle tâche sur l'accueil.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Réunion équipe'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Réunion équipe'), findsOneWidget);
  });

  testWidgets('Validation — titre obligatoire (pas d’appel API)',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.text('Le titre est obligatoire.'), findsOneWidget);
    expect(repo.createdTasks, isEmpty);
  });

  testWidgets('F6 — le check de la timeline bascule l’état', (tester) async {
    await pumpApp(tester);

    // « See all » est sous le pli : on défile jusqu'aux tâches du jour.
    await tester.scrollUntilVisible(
      find.text('Meeting with Shakib'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('See all').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();

    // Première tâche (mise en avant) : initialement terminée.
    expect(find.text('Terminée'), findsOneWidget);

    final featuredCheck = find.descendant(
      of: find.byType(TimelineTask).first,
      matching: find.byIcon(Icons.check),
    );
    await tester.tap(featuredCheck);
    await tester.pumpAndSettle();

    expect(repo.toggledIds, contains('t1'));
    expect(find.text('À faire'), findsOneWidget);
    expect(find.text('Terminée'), findsNothing);
  });

  testWidgets('F4 — modification depuis la timeline', (tester) async {
    await pumpApp(tester);

    // « See all » est sous le pli : on défile jusqu'aux tâches du jour.
    await tester.scrollUntilVisible(
      find.text('Meeting with Shakib'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('See all').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();

    // Tap sur la carte → feuille d'actions → modification.
    await tester.tap(find.byType(TimelineTask).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier la tâche'));
    await tester.pumpAndSettle();

    expect(find.text('Edit task'), findsOneWidget);

    await tester.enterText(
      formFields.first,
      'Meeting modifié',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(repo.updatedIds, contains('t1'));
    expect(find.text('Edit task'), findsNothing);
    expect(find.text('Meeting modifié'), findsOneWidget);
  });

  testWidgets('Recherche dynamique sur l’accueil', (tester) async {
    await pumpApp(tester);

    final search = find.byType(TextField).first;

    // Rien ne correspond → message + sections masquées.
    await tester.enterText(search, 'introuvable');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.textContaining('Aucun résultat'), findsOneWidget);

    // Après défilement, les sections sont bien masquées (pas de contenu).
    await tester.drag(find.byIcon(Icons.search_off), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsNothing);
    expect(find.text("Today's task"), findsNothing);

    // Une recherche réelle filtre les tâches affichées (titre/description).
    await tester.enterText(search, 'yoga');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Yoga'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Yoga'), findsOneWidget);
    expect(find.text('Meeting with Shakib'), findsNothing);

    // Bouton (×) : on efface et les sections reviennent.
    await tester.ensureVisible(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Meeting with Shakib'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Meeting with Shakib'), findsOneWidget);
  });

  testWidgets('Carte de catégorie → page des tâches de la catégorie',
      (tester) async {
    await pumpApp(tester);

    // Toutes les cartes visibles ont leur flèche (carte entière cliquable).
    expect(find.byIcon(Icons.arrow_forward), findsAtLeastNWidgets(3));
    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();

    // En-tête de la page + compteur (fixtures personal : 2 tâches).
    final screen = find.byType(CategoryTasksScreen);
    expect(
      find.descendant(of: screen, matching: find.text('Personal')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: screen, matching: find.text('2 tâches')),
      findsOneWidget,
    );

    // Tâches de la catégorie groupées par date, autres catégories absentes.
    expect(find.text('June 27, 2026'), findsOneWidget);
    expect(find.text('Clean the garage'), findsOneWidget);
    expect(find.text('Go laundering'), findsOneWidget);
    expect(find.text('Meeting with Shakib'), findsNothing);

    // Tap sur une tâche → formulaire de modification (F4), puis retour.
    await tester.tap(find.text('Go laundering'));
    await tester.pumpAndSettle();
    expect(find.text('Edit task'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(TaskFormScreen),
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );
    await tester.pumpAndSettle();

    // Retour à l'accueil.
    await tester.tap(
      find.descendant(
        of: screen,
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CategoryTasksScreen), findsNothing);
  });
}
