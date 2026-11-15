import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Cache local des données Flowday — **F8 : stockage local / hors ligne**.
///
/// Conserve, **par compte**, la dernière photographie connue des tâches,
/// des catégories et des statistiques, ainsi que la file des opérations
/// en attente de synchronisation. Le tout est sérialisé en JSON dans
/// `SharedPreferences` sous la clé `flowday.cache.v1.<user id>` : les
/// données d'un compte ne fuient donc jamais vers un autre.
///
/// Le cache est **best-effort** : une erreur de stockage (plugin absent
/// en test, JSON corrompu…) désactive simplement le cache local sans
/// jamais faire échouer un appel réseau. Les lectures/écritures mémoire
/// restent synchrones ; seule la persistance disque est asynchrone.
class LocalStore {
  LocalStore({Future<SharedPreferences>? prefs, DateTime Function()? clock})
    : _prefsFuture = prefs ?? SharedPreferences.getInstance(),
      _clock = clock ?? DateTime.now;

  final Future<SharedPreferences> _prefsFuture;
  final DateTime Function() _clock;

  static const String _prefix = 'flowday.cache.v1.';
  static const int _formatVersion = 1;

  final Map<String, TaskItem> _tasks = {};
  final List<Category> _categories = [];
  final List<Map<String, dynamic>> _pending = [];
  ProfileStats? _stats;
  DateTime? _savedAt;

  String? _user;
  bool _loaded = false;
  bool _hasSnapshot = false;
  bool _available = true;

  /// `false` si le stockage local est inutilisable (plugin absent, erreur
  /// d'E/S) : toutes les opérations deviennent alors des no-ops.
  bool get isAvailable => _available;

  /// Vrai si une photographie locale existe pour le compte courant.
  bool get hasSnapshot => _hasSnapshot;

  /// Date de la dernière écriture du cache.
  DateTime? get savedAt => _savedAt;

  /// Nombre d'opérations locales restant à pousser vers le serveur.
  int get pendingCount => _pending.length;

  /// Opérations en attente, dans l'ordre où elles ont été faites.
  List<Map<String, dynamic>> get pending => List.unmodifiable(_pending);

  // ---------------------------------------------------------------------
  // Cycle de vie
  // ---------------------------------------------------------------------

  /// Charge (une seule fois) le cache de [userId]. Un identifiant `null`
  /// (déconnexion) vide la mémoire sans effacer le disque : le compte
  /// retrouve ses données hors ligne à la prochaine connexion.
  Future<void> bind(String? userId) async {
    if (_loaded && _user == userId) return;
    _user = userId;
    _loaded = true;
    _tasks.clear();
    _categories.clear();
    _pending.clear();
    _stats = null;
    _savedAt = null;
    _hasSnapshot = false;
    if (userId == null || !_available) return;
    await _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString('$_prefix$_user');
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      final tasks = decoded['tasks'];
      if (tasks is List) {
        for (final row in tasks) {
          if (row is! Map<String, dynamic>) continue;
          try {
            final task = TaskItem.fromJson(row);
            _tasks[task.id] = task;
          } catch (error) {
            debugPrint('LocalStore : tâche ignorée ($error)');
          }
        }
      }

      final categories = decoded['categories'];
      if (categories is List) {
        for (final row in categories) {
          if (row is! Map<String, dynamic>) continue;
          try {
            _categories.add(Category.fromJson(row));
          } catch (error) {
            debugPrint('LocalStore : catégorie ignorée ($error)');
          }
        }
      }

      final stats = decoded['stats'];
      if (stats is Map<String, dynamic>) {
        _stats = ProfileStats.fromJson(stats);
      }

      final pending = decoded['pending'];
      if (pending is List) {
        for (final operation in pending) {
          if (operation is Map<String, dynamic>) _pending.add(operation);
        }
      }

      final savedAt = decoded['saved_at'];
      if (savedAt is String) _savedAt = DateTime.tryParse(savedAt);
      _hasSnapshot = true;
    } on Object catch (error) {
      debugPrint('LocalStore : cache illisible ($error)');
      if (error is MissingPluginException) {
        _available = false;
      } else {
        await _clearStorage();
      }
    }
  }

  Future<void> _persist() async {
    if (!_available || _user == null) return;
    _hasSnapshot = true;
    _savedAt = _clock();
    try {
      final prefs = await _prefsFuture;
      await prefs.setString('$_prefix$_user', jsonEncode(_encode()));
    } on Object catch (error) {
      debugPrint('LocalStore : écriture impossible ($error)');
      if (error is MissingPluginException) _available = false;
    }
  }

  Map<String, dynamic> _encode() => {
    'v': _formatVersion,
    'saved_at': (_savedAt ?? _clock()).toUtc().toIso8601String(),
    'tasks': [for (final task in _tasks.values) task.toJson()],
    'categories': [for (final category in _categories) category.toJson()],
    'stats': _stats?.toJson(),
    'pending': _pending,
  };

  Future<void> _clearStorage() async {
    _tasks.clear();
    _categories.clear();
    _pending.clear();
    _stats = null;
    _savedAt = null;
    _hasSnapshot = false;
    if (!_available || _user == null) return;
    try {
      final prefs = await _prefsFuture;
      await prefs.remove('$_prefix$_user');
    } on Object catch (error) {
      debugPrint('LocalStore : purge impossible ($error)');
      if (error is MissingPluginException) _available = false;
    }
  }

  /// Efface la photographie et la file d'attente du compte courant.
  Future<void> clear() => _clearStorage();

  // ---------------------------------------------------------------------
  // Lectures
  // ---------------------------------------------------------------------

  /// Toutes les tâches connues (non triées).
  List<TaskItem> get tasks => List.unmodifiable(_tasks.values);

  /// Tâches filtrées comme le fait l'API (`?date=`, plage, catégorie),
  /// triées par (date, heure).
  List<TaskItem> tasksFor({
    String? date,
    String? start,
    String? end,
    String? category,
  }) {
    final result = <TaskItem>[
      for (final task in _tasks.values)
        if ((date == null || task.date == date) &&
            (start == null || task.date.compareTo(start) >= 0) &&
            (end == null || task.date.compareTo(end) <= 0) &&
            (category == null || task.category.id == category))
          task,
    ];
    result.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.time.compareTo(b.time);
    });
    return result;
  }

  /// Catégories connues, triées par nom (ordre de l'API).
  List<Category> get categories => List.unmodifiable(_categories);

  /// Catégorie par identifiant, ou `null` si inconnue du cache.
  Category? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Dernières statistiques connues du profil.
  ProfileStats? get stats => _stats;

  // ---------------------------------------------------------------------
  // Écritures
  // ---------------------------------------------------------------------

  /// Insère ou remplace une tâche dans le cache.
  Future<void> putTask(TaskItem task) async {
    _tasks[task.id] = task;
    await _persist();
  }

  /// Insère ou remplace plusieurs tâches en une seule écriture disque.
  Future<void> putTasks(Iterable<TaskItem> tasks) async {
    var changed = false;
    for (final task in tasks) {
      _tasks[task.id] = task;
      changed = true;
    }
    if (changed) await _persist();
  }

  /// Retire une tâche du cache (suppression locale ou distante).
  Future<void> removeTask(String id) async {
    if (_tasks.remove(id) == null) return;
    await _persist();
  }

  /// Remplace la liste des catégories.
  Future<void> putCategories(List<Category> categories) async {
    _categories
      ..clear()
      ..addAll(categories);
    await _persist();
  }

  /// Enregistre les statistiques du profil.
  Future<void> putStats(ProfileStats stats) async {
    _stats = stats;
    await _persist();
  }

  // ---------------------------------------------------------------------
  // File d'attente (hors ligne)
  // ---------------------------------------------------------------------

  /// Ajoute une opération à pousser au retour du réseau.
  Future<void> enqueue(Map<String, dynamic> operation) async {
    _pending.add(operation);
    await _persist();
  }

  /// Retire les [count] premières opérations (après succès côté serveur).
  Future<void> dropPending(int count) async {
    if (count <= 0) return;
    final removed = count >= _pending.length ? _pending.length : count;
    _pending.removeRange(0, removed);
    await _persist();
  }

  /// Vide la file d'attente (après une synchronisation complète).
  Future<void> clearPending() => dropPending(_pending.length);
}
