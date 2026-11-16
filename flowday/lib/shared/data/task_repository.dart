import 'dart:math';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart' show Color;

import '../../core/errors/api_exception.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/network/supabase_auth_client.dart';
import '../../core/network/supabase_rest_client.dart';
import '../models/models.dart';
import 'local_store.dart';

/// Accès aux données en **accès direct Supabase** (PostgREST) : la couche
/// data du README §7, sans serveur intermédiaire (voir SUIVI « Phase 4 »).
///
/// Tables exposées par l'API REST :
/// - `planning_category` : `id`, `name`, `color`
/// - `planning_task` : `id`, `title`, `description`, `date`, `time`,
///   `completed`, `created_at`, `category_id` (+ `reminder` nullable,
///   `user_id` géré par les politiques RLS)
///
/// La catégorie est **embarquée** via la clé étrangère
/// (`select=…,planning_category(id,name,color)`) : une seule requête par
/// liste de tâches. Les erreurs HTTP sont levées sous forme d'`ApiException`.
///
/// **F8 — stockage local / hors ligne** : chaque lecture réussie alimente
/// un cache local par compte ([LocalStore]). Si le réseau est indisponible,
/// les lectures sont servies depuis ce cache et les mutations sont
/// appliquées localement puis rejouées au retour de la connexion
/// ([syncPending]).
class TaskRepository {
  TaskRepository({
    SupabaseRestClient? client,
    TokenSource? auth,
    LocalStore? store,
  }) : _client = client ?? SupabaseRestClient(tokens: auth),
       _auth = auth,
       _store = store ?? LocalStore();

  final SupabaseRestClient _client;
  final TokenSource? _auth;
  final LocalStore _store;

  /// Vrai quand la dernière opération a été servie **hors ligne**
  /// (cache local ou file d'attente).
  bool _offline = false;

  /// Instant de la dernière panne réseau constatée.
  DateTime? _lastFailureAt;

  /// Après une panne, on reste quelques secondes « hors ligne » : les
  /// actions de l'utilisateur (cocher, créer, changer de jour…) répondent
  /// **immédiatement** depuis le cache au lieu d'attendre le délai
  /// d'expiration réseau (10 s) à chaque clic. Passé ce délai, le réseau
  /// est retenté automatiquement (retour en ligne détecté tout seul).
  static const Duration _offlineWindow = Duration(seconds: 15);

  /// Une panne récente est connue → inutile de rappeler le réseau.
  bool get _networkSkipped {
    if (!_offline) return false;
    final last = _lastFailureAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < _offlineWindow;
  }

  /// Erreur synthétique levée quand le réseau est sauté : les opérations
  /// basculent alors directement sur le cache local. Instance unique pour
  /// pouvoir la reconnaître (`identical`) et ne pas relancer le délai de
  /// calme à chaque clic hors ligne.
  static final ApiException _offlineSentinel = ApiException(
    statusCode: 0,
    message: 'Hors ligne.',
  );

  ApiException get _offlineException => _offlineSentinel;

  /// Mémorise une panne réseau (le délai de calme repart de zéro, sauf
  /// quand le réseau a volontairement été sauté).
  void _markOffline({bool refresh = true}) {
    _offline = true;
    if (refresh) _lastFailureAt = DateTime.now();
  }

  /// Connexion rétablie (une requête a abouti).
  void _markOnline() {
    _offline = false;
    _lastFailureAt = null;
  }

  /// Compte dont le cache est chargé (évite de recharger à chaque appel).
  String? _boundUser;
  bool _bound = false;

  bool get isOffline => _offline;

  /// Nombre de modifications locales restant à synchroniser.
  int get pendingWrites => _store.pendingCount;

  /// 404 : la mutation n'a touché aucune ligne (déjà supprimée / inexistante).
  ApiException get _notFound => ApiException(
    statusCode: 404,
    message: AppLocalizations.instance.t('Tâche introuvable.'),
  );

  /// Colonnes d'une tâche + catégorie embarquée.
  static const String _taskSelect =
      'id,title,description,date,time,completed,category_id,'
      'planning_category(id,name,color)';

  // ---------------------------------------------------------------------
  // Cache local (F8)
  // ---------------------------------------------------------------------

  /// Charge le cache du compte connecté (no-op s'il est déjà chargé).
  Future<void> _syncCache() async {
    final userId = _auth?.userId;
    if (_bound && _boundUser == userId) return;
    _boundUser = userId;
    _bound = true;
    // Nouveau compte (ou déconnexion) : l'état hors ligne repart de zéro.
    _markOnline();
    try {
      await _store.bind(userId);
    } on Object catch (error) {
      debugPrint('TaskRepository : cache local indisponible ($error)');
    }
  }

  /// Une panne réseau (code 0) ou un serveur indisponible (5xx) peut être
  /// absorbé par le cache ; une erreur métier (4xx) est toujours remontée.
  bool _canFallback(Object error) =>
      error is ApiException && (error.isNetwork || error.statusCode >= 500);

  TaskItem? _cachedTask(String id) {
    for (final task in _store.tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Pousse les modifications faites hors ligne vers le serveur.
  ///
  /// Les opérations sont rejouées dans l'ordre. Une opération définitivement
  /// invalide (4xx) est abandonnée ; une panne réseau interrompt la
  /// synchronisation et la file est conservée pour un prochain essai.
  Future<void> syncPending() async {
    await _syncCache();
    await _flushPending();
  }

  /// Bouton « Réessayer » du bandeau hors ligne : ignore la fenêtre de
  /// calme, pousse la file puis vérifie que le serveur répond vraiment.
  Future<void> retryNow() async {
    await _syncCache();
    _lastFailureAt = null; // force une tentative réseau immédiate
    try {
      await _flushPending();
      if (!_offline) return;
      // File vide : on vérifie explicitement que le serveur répond.
      await _client.get('planning_category', query: {'select': 'id'});
      _markOnline();
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      _markOffline();
    }
  }

  /// Tente le réseau, ou lève immédiatement [_offlineException] quand une
  /// panne récente est connue : l'appelant bascule alors sur le cache sans
  /// attendre le délai d'expiration (fluidité des clics hors ligne).
  Future<void> _requireNetwork() async {
    if (_networkSkipped) {
      _markOffline(refresh: false);
      throw _offlineException;
    }
    await _flushPending();
  }

  Future<void> _flushPending() async {
    var contacted = false;
    while (_store.pendingCount > 0) {
      final operation = _store.pending.first;
      try {
        await _applyPending(operation);
        contacted = true;
      } on ApiException catch (error) {
        if (error.isNetwork || error.statusCode >= 500) rethrow;
        // 4xx : l'opération ne pourra jamais aboutir (tâche supprimée
        // entre-temps, données invalides…) → on l'abandonne.
        debugPrint(
          'TaskRepository : opération hors ligne abandonnée '
          '(${error.statusCode})',
        );
      }
      await _store.dropPending(1);
    }
    // Ne repasse « en ligne » que si le serveur a réellement répondu.
    if (contacted) _markOnline();
  }

  Future<void> _applyPending(Map<String, dynamic> operation) async {
    switch (operation['op']) {
      case 'create':
        final body = operation['body'];
        if (body is! Map<String, dynamic>) return;
        try {
          await _client.post(
            'planning_task',
            query: {'select': 'id'},
            body: body,
          );
        } on ApiException catch (error) {
          // 409 : déjà créée lors d'une synchronisation interrompue.
          if (error.statusCode != 409) rethrow;
        }
      case 'update':
        final id = operation['id'];
        final patch = operation['patch'];
        if (id is! String || patch is! Map<String, dynamic>) return;
        if (patch.isEmpty) return;
        await _client.patch(
          'planning_task',
          query: {'id': 'eq.$id'},
          body: patch,
        );
      case 'complete':
        final id = operation['id'];
        if (id is! String) return;
        await _client.patch(
          'planning_task',
          query: {'id': 'eq.$id'},
          body: {'completed': operation['completed'] == true},
        );
      case 'delete':
        final id = operation['id'];
        if (id is! String) return;
        await _client.delete('planning_task', query: {'id': 'eq.$id'});
    }
  }

  // ---------------------------------------------------------------------
  // F7 — catégories
  // ---------------------------------------------------------------------
  Future<List<Category>> fetchCategories() async {
    await _syncCache();
    try {
      await _requireNetwork();
      final rows = await _client.get(
        'planning_category',
        query: {'select': 'id,name,color', 'order': 'name.asc'},
      );
      final categories = rows.map(Category.fromJson).toList();
      await _store.putCategories(categories);
      _markOnline();
      return categories;
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      final cached = _store.categories;
      if (cached.isEmpty && !_store.hasSnapshot) rethrow;
      _markOffline(refresh: !identical(error, _offlineSentinel));
      return cached;
    }
  }

  // ---------------------------------------------------------------------
  // F1 / F2 / F7 — tâches d'un jour, d'une plage ou d'une catégorie
  // ---------------------------------------------------------------------
  Future<List<TaskItem>> fetchTasks({
    String? date,
    String? start,
    String? end,
    String? category,
  }) async {
    await _syncCache();
    final query = <String, Object>{
      'select': _taskSelect,
      'order': 'date.asc,time.asc',
    };
    if (date != null) {
      query['date'] = 'eq.$date';
    } else if (start != null && end != null) {
      // Paramètre répété : PostgREST combine les deux bornes (ET).
      query['date'] = ['gte.$start', 'lte.$end'];
    }
    if (category != null) query['category_id'] = 'eq.$category';

    try {
      await _requireNetwork();
      final rows = await _client.get('planning_task', query: query);
      final tasks = rows.map(_taskFromRow).toList();
      await _store.putTasks(tasks);
      _markOnline();
      return tasks;
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      if (!_store.hasSnapshot) rethrow;
      _markOffline(refresh: !identical(error, _offlineSentinel));
      return _store.tasksFor(
        date: date,
        start: start,
        end: end,
        category: category,
      );
    }
  }

  // ---------------------------------------------------------------------
  // F3 — création
  // ---------------------------------------------------------------------
  Future<TaskItem> createTask({
    required String title,
    String description = '',
    required String date,
    required String time,
    required String categoryId,
  }) async {
    await _syncCache();
    // `id` et `created_at` sont NOT NULL **sans défaut** en base
    // (Django les génère côté Python) : on fait pareil côté client, ce qui
    // permet aussi de créer la tâche hors ligne avec son identifiant final.
    final id = _newUuid();
    final body = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'completed': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'category_id': categoryId,
    };

    try {
      await _requireNetwork();
      final rows = await _client.post(
        'planning_task',
        query: {'select': _taskSelect},
        body: body,
      );
      if (rows.isEmpty) {
        throw ApiException(
          statusCode: 400,
          message: AppLocalizations.instance.t(
            "La tâche n'a pas pu être créée.",
          ),
        );
      }
      final task = _taskFromRow(rows.first);
      await _store.putTask(task);
      _markOnline();
      return task;
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      final task = TaskItem(
        id: id,
        title: title,
        description: description,
        date: date,
        time: time,
        category:
            _store.categoryById(categoryId) ??
            Category(id: categoryId, name: '', color: const Color(0xFF7C7C8A)),
        completed: false,
      );
      await _store.putTask(task);
      await _store.enqueue({'op': 'create', 'body': body});
      _markOffline(refresh: !identical(error, _offlineSentinel));
      return task;
    }
  }

  // ---------------------------------------------------------------------
  // F4 — modification (seuls les champs non nuls sont envoyés)
  // ---------------------------------------------------------------------
  Future<TaskItem> updateTask(
    String id, {
    String? title,
    String? description,
    String? date,
    String? time,
    String? categoryId,
  }) async {
    await _syncCache();
    final body = <String, dynamic>{
      'title': ?title,
      'description': ?description,
      'date': ?date,
      'time': ?time,
      'category_id': ?categoryId,
    };
    if (body.isEmpty) return _fetchOne(id); // rien à changer : état actuel

    try {
      await _requireNetwork();
      final rows = await _client.patch(
        'planning_task',
        query: {'id': 'eq.$id', 'select': _taskSelect},
        body: body,
      );
      if (rows.isEmpty) throw _notFound;
      final task = _taskFromRow(rows.first);
      await _store.putTask(task);
      _markOnline();
      return task;
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      final cached = _cachedTask(id);
      if (cached == null) rethrow;
      final updated = cached.copyWith(
        title: title,
        description: description,
        date: date,
        time: time,
        category: categoryId == null ? null : _store.categoryById(categoryId),
      );
      await _store.putTask(updated);
      await _store.enqueue({'op': 'update', 'id': id, 'patch': body});
      _markOffline(refresh: !identical(error, _offlineSentinel));
      return updated;
    }
  }

  // ---------------------------------------------------------------------
  // F5 — suppression
  // ---------------------------------------------------------------------
  Future<void> deleteTask(String id) async {
    await _syncCache();
    try {
      await _requireNetwork();
      final rows = await _client.delete(
        'planning_task',
        query: {'id': 'eq.$id'},
      );
      if (rows.isEmpty) throw _notFound; // déjà absente → 404
      await _store.removeTask(id);
      _markOnline();
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      await _store.removeTask(id);
      await _store.enqueue({'op': 'delete', 'id': id});
      _markOffline(refresh: !identical(error, _offlineSentinel));
    }
  }

  // ---------------------------------------------------------------------
  // F6 — terminer / déterminer (2 requêtes : état actuel puis inversion)
  // ---------------------------------------------------------------------
  Future<TaskItem> toggleTask(String id) async {
    final current = await _client.get(
      'planning_task',
      query: {'id': 'eq.$id', 'select': 'completed'},
    );
    if (current.isEmpty) throw _notFound;
    final completed = current.first['completed'] == true;

    return setTaskCompleted(id, !completed);
  }

  /// Définit l'état demandé directement (le provider connaît déjà la
  /// nouvelle valeur), sans relire l'état courant avant le PATCH.
  Future<TaskItem> setTaskCompleted(String id, bool completed) async {
    await _syncCache();
    try {
      await _requireNetwork();
      final rows = await _client.patch(
        'planning_task',
        query: {'id': 'eq.$id', 'select': _taskSelect},
        body: {'completed': completed},
      );
      if (rows.isEmpty) throw _notFound;
      final task = _taskFromRow(rows.first);
      await _store.putTask(task);
      _markOnline();
      return task;
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      final cached = _cachedTask(id);
      if (cached == null) rethrow;
      final updated = cached.copyWith(completed: completed);
      await _store.putTask(updated);
      await _store.enqueue({
        'op': 'complete',
        'id': id,
        'completed': completed,
      });
      _markOffline(refresh: !identical(error, _offlineSentinel));
      return updated;
    }
  }

  // ---------------------------------------------------------------------
  // §3.5 — statistiques du profil
  // ---------------------------------------------------------------------
  /// Recalculées côté client (une seule requête `select=completed,date`),
  /// avec la même règle que le backend : tâches du lundi à aujourd'hui.
  Future<ProfileStats> fetchStats() async {
    await _syncCache();
    try {
      await _requireNetwork();
      final rows = await _client.get(
        'planning_task',
        query: {'select': 'completed,date'},
      );

      final today = DateTime.now();
      final day0 = DateTime(today.year, today.month, today.day);
      final weekStart = day0.subtract(
        Duration(days: day0.weekday - 1),
      ); // lundi

      var completed = 0;
      var thisWeek = 0;
      for (final row in rows) {
        if (row['completed'] == true) completed++;
        final parsed = DateTime.tryParse('${row['date']}');
        if (parsed == null) continue;
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (!day.isBefore(weekStart) && !day.isAfter(day0)) thisWeek++;
      }

      final stats = ProfileStats(
        totalTasks: rows.length,
        completedTasks: completed,
        tasksThisWeek: thisWeek,
      );
      await _store.putStats(stats);
      _markOnline();
      return stats;
    } on Object catch (error) {
      if (!_canFallback(error)) rethrow;
      final cached = _store.stats;
      if (cached == null) rethrow;
      _markOffline(refresh: !identical(error, _offlineSentinel));
      return cached;
    }
  }

  // ---------------------------------------------------------------------
  // Internes
  // ---------------------------------------------------------------------

  /// Une tâche par son id (réutilisé quand rien n'est à modifier).
  Future<TaskItem> _fetchOne(String id) async {
    final rows = await _client.get(
      'planning_task',
      query: {'id': 'eq.$id', 'select': _taskSelect},
    );
    if (rows.isEmpty) throw _notFound;
    return _taskFromRow(rows.first);
  }

  /// Ligne PostgREST → modèle du domaine (via le format API de `fromJson`).
  TaskItem _taskFromRow(Map<String, dynamic> row) {
    final cat = row['planning_category'];
    final catMap = cat is Map<String, dynamic>
        ? cat
        : const <String, dynamic>{};
    return TaskItem.fromJson({
      'id': row['id'],
      'title': row['title'],
      'description': row['description'],
      'date': row['date'],
      'time': row['time'],
      'completed': row['completed'],
      'category': row['category_id'],
      'category_name': catMap['name'] ?? '',
      'category_color': catMap['color'] ?? '#000000',
    });
  }

  /// UUID v4 (la colonne `id` n'a aucun défaut générée en base).
  static String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122
    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
