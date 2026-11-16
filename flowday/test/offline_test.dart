import 'dart:convert';

import 'package:flowday/core/errors/api_exception.dart';
import 'package:flowday/core/network/supabase_auth_client.dart';
import 'package:flowday/core/network/supabase_rest_client.dart';
import 'package:flowday/core/providers/tasks_provider.dart';
import 'package:flowday/shared/data/local_store.dart';
import 'package:flowday/shared/data/task_repository.dart';
import 'package:flowday/shared/utils/date_utils.dart';
import 'package:flowday/shared/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F8 — stockage local / hors ligne.
///
/// Vérifie le cycle complet : mise en cache des lectures, relecture depuis
/// le cache quand le réseau tombe (par compte), mise en file des mutations
/// puis rejeu au retour de la connexion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStore', () {
    test(
      'la déconnexion vide la mémoire mais conserve le cache disque',
      () async {
        final backend = _Backend();
        final store = LocalStore(prefs: SharedPreferences.getInstance());
        final repo = _repository(backend, 'u1', store: store);

        await repo.fetchTasks(date: '2026-11-15');
        expect(store.tasks, hasLength(1));

        // Déconnexion : plus rien en mémoire…
        await store.bind(null);
        expect(store.hasSnapshot, isFalse);
        expect(store.tasks, isEmpty);

        // …mais le compte retrouve ses données hors ligne à la reconnexion.
        backend.online = false;
        await store.bind('u1');
        expect(store.hasSnapshot, isTrue);
        expect(store.tasks.single.title, 'Réviser le projet');
      },
    );

    test('les tâches sont filtrées et triées comme l’API', () async {
      final backend = _Backend(seed: false)
        ..tasks.add(
          _task(id: 't2', title: 'B', date: '2026-11-16', time: '09:00'),
        )
        ..tasks.add(
          _task(id: 't1', title: 'A', date: '2026-11-15', time: '14:00'),
        )
        ..tasks.add(
          _task(id: 't3', title: 'C', date: '2026-11-15', time: '08:00'),
        );
      final store = LocalStore(prefs: SharedPreferences.getInstance());
      await _repository(backend, 'u1', store: store).fetchTasks();

      expect(store.tasksFor(date: '2026-11-15').map((t) => t.title), [
        'C',
        'A',
      ]);
      expect(
        store
            .tasksFor(start: '2026-11-15', end: '2026-11-16')
            .map((t) => t.title),
        ['C', 'A', 'B'],
      );
      expect(store.tasksFor(category: 'personal'), isEmpty);
    });
  });

  group('Bandeau hors ligne', () {
    testWidgets('affiche le nombre de modifications et relance la synchro', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(pending: 2, onRetry: () => retried++),
          ),
        ),
      );

      expect(
        find.text('Hors ligne — 2 modifications en attente.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Réessayer'));
      expect(retried, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(pending: 0, onRetry: () => retried++),
          ),
        ),
      );
      expect(
        find.text('Hors ligne — données enregistrées sur cet appareil.'),
        findsOneWidget,
      );
    });
  });

  group('TaskRepository hors ligne', () {
    test('les lectures sont servies par le cache, par compte', () async {
      final backend = _Backend();
      final online = _repository(backend, 'u1');

      final tasks = await online.fetchTasks(date: '2026-11-15');
      expect(tasks.single.title, 'Réviser le projet');
      expect(await online.fetchCategories(), hasLength(2));
      expect((await online.fetchStats()).totalTasks, 1);
      expect(online.isOffline, isFalse);
      expect(online.pendingWrites, 0);

      backend.online = false;
      final offline = _repository(backend, 'u1');
      final cached = await offline.fetchTasks(date: '2026-11-15');
      expect(cached.single.id, 't1');
      expect(offline.isOffline, isTrue);

      // Catégories et statistiques suivent le même chemin.
      expect(await offline.fetchCategories(), hasLength(2));
      expect((await offline.fetchStats()).totalTasks, 1);

      // Un autre compte ne voit jamais le cache du premier.
      final other = _repository(backend, 'u2');
      await expectLater(
        other.fetchTasks(date: '2026-11-15'),
        throwsA(isA<ApiException>()),
      );
    });

    test('une création hors ligne est rejouée au retour du réseau', () async {
      final backend = _Backend(seed: false);
      final repo = _repository(backend, 'u1');

      // Les catégories sont chargées à la connexion puis mises en cache.
      expect(await repo.fetchCategories(), hasLength(2));
      backend.online = false;

      final created = await repo.createTask(
        title: 'Acheter du pain',
        date: '2026-11-15',
        time: '09:30',
        categoryId: 'work',
      );
      expect(repo.isOffline, isTrue);
      expect(repo.pendingWrites, 1);
      expect(created.title, 'Acheter du pain');
      expect(created.category.name, 'Travail');

      // Toujours hors ligne : la tâche locale est bien visible.
      final local = await repo.fetchTasks(date: '2026-11-15');
      expect(local.map((t) => t.title), contains('Acheter du pain'));
      expect(repo.pendingWrites, 1);
      expect(backend.tasks, isEmpty);

      // Retour du réseau : la file est poussée puis vidée.
      backend.online = true;
      await repo.syncPending();
      expect(repo.pendingWrites, 0);
      expect(repo.isOffline, isFalse);
      expect(backend.tasks.single['id'], created.id);
      expect(backend.tasks.single['title'], 'Acheter du pain');

      final server = await repo.fetchTasks(date: '2026-11-15');
      expect(server.single.id, created.id);
    });

    test('modifications et suppression hors ligne sont rejouées', () async {
      final backend = _Backend();
      final repo = _repository(backend, 'u1');
      await repo.fetchTasks(date: '2026-11-15'); // alimente le cache

      backend.online = false;
      final updated = await repo.updateTask('t1', title: 'Sport (matin)');
      expect(updated.title, 'Sport (matin)');

      final done = await repo.setTaskCompleted('t1', true);
      expect(done.completed, isTrue);
      expect(repo.pendingWrites, 2);

      backend.online = true;
      await repo.syncPending();
      expect(repo.pendingWrites, 0);
      expect(backend.tasks.single['title'], 'Sport (matin)');
      expect(backend.tasks.single['completed'], isTrue);

      // Suppression hors ligne → disparaît du cache, rejouée ensuite.
      backend.online = false;
      await repo.deleteTask(done.id);
      expect(repo.pendingWrites, 1);
      expect(await repo.fetchTasks(date: '2026-11-15'), isEmpty);

      backend.online = true;
      await repo.syncPending();
      expect(repo.pendingWrites, 0);
      expect(backend.tasks, isEmpty);
    });

    test(
      'le provider expose l’état hors ligne sans erreur bloquante',
      () async {        final backend = _Backend(seed: false);
        final today = FlowDates.apiDate(DateTime.now());
        backend.tasks.add(_task(id: 'today', title: 'Du jour', date: today));

        // Premier chargement en ligne : le cache se remplit.
        final warmup = _repository(backend, 'u1');
        await warmup.fetchCategories();
        await warmup.fetchTasks(date: today);
        await warmup.fetchStats();

        backend.online = false;
        final provider = TasksProvider(repository: _repository(backend, 'u1'));
        await provider.loadInitial();

        expect(provider.error, isNull);
        expect(provider.isOffline, isTrue);
        expect(provider.todayTasks.single.title, 'Du jour');
        expect(provider.pendingWrites, 0);

        // Toujours hors ligne : le bouton « Réessayer » ne casse rien.
        await provider.retrySync();
        expect(provider.isOffline, isTrue);
        expect(provider.todayTasks.single.title, 'Du jour');

        provider.dispose();
      },
    );

    test(
      'hors ligne : plus aucun appel réseau (clics instantanés)',
      () async {
        final backend = _Backend();
        final repo = _repository(backend, 'u1');
        await repo.fetchTasks(date: '2026-11-15'); // cache chaud

        backend.online = false;
        // Premier échec : le réseau est constaté indisponible.
        await repo.fetchTasks(date: '2026-11-15');
        expect(repo.isOffline, isTrue);
        final attempts = backend.requests;

        // Les actions suivantes répondent depuis le cache/file locale,
        // sans rappeler le réseau (donc sans attendre le délai 10 s).
        await repo.fetchTasks(date: '2026-11-15');
        await repo.setTaskCompleted('t1', true);
        await repo.createTask(
          title: 'Acheter du pain',
          date: '2026-11-15',
          time: '09:30',
          categoryId: 'work',
        );
        expect(backend.requests, attempts);
        expect(repo.pendingWrites, 2);

        // « Réessayer » force une vraie tentative et vide la file.
        backend.online = true;
        await repo.retryNow();
        expect(repo.isOffline, isFalse);
        expect(repo.pendingWrites, 0);
        expect(backend.tasks, hasLength(2));
      },
    );

    test('deux appuis rapides sur une tâche ne sont pas ignorés', () async {
      final backend = _Backend(seed: false);
      final today = FlowDates.apiDate(DateTime.now());
      backend.tasks.add(_task(id: 'today', title: 'Du jour', date: today));

      final provider = TasksProvider(repository: _repository(backend, 'u1'));
      await provider.loadInitial();
      final task = provider.todayTasks.single;
      expect(task.completed, isFalse);

      // Envoi ralenti : le 2e appui arrive pendant le 1er aller-retour.
      backend.delay = const Duration(milliseconds: 40);
      final first = provider.toggle(task);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = provider.toggle(task);
      await Future.wait([first, second]);

      // État final = celui du dernier appui, côté écran **et** côté serveur.
      expect(provider.todayTasks.single.completed, isFalse);
      expect(backend.tasks.single['completed'], isFalse);
      provider.dispose();
    });
  });
}

/// Petit back-end PostgREST simulé : bascule en panne réseau à la demande.
class _Backend {
  _Backend({bool seed = true}) {
    if (seed) {
      tasks.add(_task(id: 't1', title: 'Réviser le projet'));
    }
  }

  bool online = true;

  /// Nombre de requêtes reçues (permet de vérifier qu'un clic hors ligne
  /// ne rappelle pas le réseau).
  int requests = 0;

  /// Délai artificiel de réponse (simule un réseau lent).
  Duration delay = Duration.zero;

  final List<Map<String, dynamic>> tasks = [];

  static const List<Map<String, dynamic>> categories = [
    {'id': 'work', 'name': 'Travail', 'color': '#F4761F'},
    {'id': 'personal', 'name': 'Personnel', 'color': '#F05B52'},
  ];

  http.Client get client => MockClient((request) async {
    requests++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (!online) throw http.ClientException('hors ligne');
    final table = request.url.path.split('/').last;

    if (table == 'planning_category') {
      return _json(categories);
    }
    if (table != 'planning_task') return _json(const []);

    switch (request.method) {
      case 'GET':
        final filter = request.url.queryParameters['date'];
        final day = filter != null && filter.startsWith('eq.')
            ? filter.substring(3)
            : null;
        return _json([
          for (final task in tasks)
            if (day == null || task['date'] == day) _row(task),
        ]);
      case 'POST':
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        tasks.add(body);
        return _json([_row(body)], status: 201);
      case 'PATCH':
        final id = _id(request);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final index = tasks.indexWhere((task) => task['id'] == id);
        if (index < 0) return _json(const []);
        tasks[index] = {...tasks[index], ...body};
        return _json([_row(tasks[index])]);
      case 'DELETE':
        final id = _id(request);
        final before = tasks.length;
        tasks.removeWhere((task) => task['id'] == id);
        return _json(
          tasks.length == before
              ? const []
              : [
                  {'id': id},
                ],
        );
    }
    return _json(const []);
  });

  static String _id(http.Request request) =>
      (request.url.queryParameters['id'] ?? '').replaceFirst('eq.', '');

  static http.Response _json(Object body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json'},
  );

  /// Ligne PostgREST : catégorie embarquée via la clé étrangère.
  static Map<String, dynamic> _row(Map<String, dynamic> task) {
    final category = categories.firstWhere(
      (c) => c['id'] == task['category_id'],
      orElse: () => categories.first,
    );
    return {
      'id': task['id'],
      'title': task['title'],
      'description': task['description'] ?? '',
      'date': task['date'],
      'time': task['time'],
      'completed': task['completed'] ?? false,
      'category_id': category['id'],
      'planning_category': category,
    };
  }
}

/// Jeton simulé (aucun rafraîchissement nécessaire).
class _Tokens extends TokenSource {
  _Tokens(this.user);

  final String? user;

  @override
  String? get accessToken => 'jeton-de-test';

  @override
  String? get userId => user;

  @override
  Future<bool> refreshSession() async => false;
}

Map<String, dynamic> _task({
  required String id,
  required String title,
  String date = '2026-11-15',
  String time = '10:00',
  String category = 'work',
  bool completed = false,
}) => {
  'id': id,
  'title': title,
  'description': '',
  'date': date,
  'time': time,
  'completed': completed,
  'category_id': category,
};

TaskRepository _repository(
  _Backend backend,
  String? user, {
  LocalStore? store,
}) {
  final tokens = _Tokens(user);
  return TaskRepository(
    client: SupabaseRestClient(client: backend.client, tokens: tokens),
    auth: tokens,
    store: store ?? LocalStore(prefs: SharedPreferences.getInstance()),
  );
}
