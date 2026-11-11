import 'dart:math';

import '../../core/errors/api_exception.dart';
import '../../core/network/supabase_rest_client.dart';
import '../models/models.dart';

/// Accès aux données en **accès direct Supabase** (PostgREST) : la couche
/// data du README §7, sans serveur intermédiaire (voir SUIVI « Phase 4 »).
///
/// Tables exposées par l'API REST :
/// - `planning_category` : `id`, `name`, `color`
/// - `planning_task` : `id`, `title`, `description`, `date`, `time`,
///   `completed`, `created_at`, `category_id` (+ `reminder` nullable)
///
/// La catégorie est **embarquée** via la clé étrangère
/// (`select=…,planning_category(id,name,color)`) : une seule requête par
/// liste de tâches. Les erreurs HTTP sont levées sous forme d'`ApiException`.
class TaskRepository {
  TaskRepository({SupabaseRestClient? client})
      : _client = client ?? SupabaseRestClient();

  final SupabaseRestClient _client;

  /// 404 : la mutation n'a touché aucune ligne (déjà supprimée / inexistante).
  static const ApiException _notFound = ApiException(
    statusCode: 404,
    message: 'Tâche introuvable.',
  );

  /// Colonnes d'une tâche + catégorie embarquée.
  static const String _taskSelect =
      'id,title,description,date,time,completed,category_id,'
      'planning_category(id,name,color)';

  // ---------------------------------------------------------------------
  // F7 — catégories
  // ---------------------------------------------------------------------
  Future<List<Category>> fetchCategories() async {
    final rows = await _client.get(
      'planning_category',
      query: {'select': 'id,name,color', 'order': 'name.asc'},
    );
    return rows.map(Category.fromJson).toList();
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

    final rows = await _client.get('planning_task', query: query);
    return rows.map(_taskFromRow).toList();
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
    final rows = await _client.post(
      'planning_task',
      query: {'select': _taskSelect},
      body: {
        // `id` et `created_at` sont NOT NULL **sans défaut** en base
        // (Django les génère côté Python) : on fait pareil côté client.
        'id': _newUuid(),
        'title': title,
        'description': description,
        'date': date,
        'time': time,
        'completed': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'category_id': categoryId,
      },
    );
    if (rows.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: "La tâche n'a pas pu être créée.",
      );
    }
    return _taskFromRow(rows.first);
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
    final body = <String, dynamic>{
      'title': ?title,
      'description': ?description,
      'date': ?date,
      'time': ?time,
      'category_id': ?categoryId,
    };
    if (body.isEmpty) return _fetchOne(id); // rien à changer : état actuel

    final rows = await _client.patch(
      'planning_task',
      query: {'id': 'eq.$id', 'select': _taskSelect},
      body: body,
    );
    if (rows.isEmpty) throw _notFound;
    return _taskFromRow(rows.first);
  }

  // ---------------------------------------------------------------------
  // F5 — suppression
  // ---------------------------------------------------------------------
  Future<void> deleteTask(String id) async {
    final rows = await _client.delete(
      'planning_task',
      query: {'id': 'eq.$id'},
    );
    if (rows.isEmpty) throw _notFound; // déjà absente → 404
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

    final rows = await _client.patch(
      'planning_task',
      query: {'id': 'eq.$id', 'select': _taskSelect},
      body: {'completed': !completed},
    );
    if (rows.isEmpty) throw _notFound;
    return _taskFromRow(rows.first);
  }

  // ---------------------------------------------------------------------
  // §3.5 — statistiques du profil
  // ---------------------------------------------------------------------
  /// Recalculées côté client (une seule requête `select=completed,date`),
  /// avec la même règle que le backend : tâches du lundi à aujourd'hui.
  Future<ProfileStats> fetchStats() async {
    final rows = await _client.get(
      'planning_task',
      query: {'select': 'completed,date'},
    );

    final today = DateTime.now();
    final day0 = DateTime(today.year, today.month, today.day);
    final weekStart = day0.subtract(Duration(days: day0.weekday - 1)); // lundi

    var completed = 0;
    var thisWeek = 0;
    for (final row in rows) {
      if (row['completed'] == true) completed++;
      final parsed = DateTime.tryParse('${row['date']}');
      if (parsed == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      if (!day.isBefore(weekStart) && !day.isAfter(day0)) thisWeek++;
    }

    return ProfileStats(
      totalTasks: rows.length,
      completedTasks: completed,
      tasksThisWeek: thisWeek,
    );
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
    final catMap = cat is Map<String, dynamic> ? cat : const <String, dynamic>{};
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
