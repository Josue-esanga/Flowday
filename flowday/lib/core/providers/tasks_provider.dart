import 'package:flutter/material.dart';

import '../../shared/data/task_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/date_utils.dart';
import '../errors/api_exception.dart';

/// État global des tâches et catégories (couche état, README §7).
///
/// Charge les données depuis l'API (`TaskRepository`), expose les listes
/// des écrans (accueil, timeline, calendrier, profil) et applique les
/// mutations F3 → F6 avec mise à jour optimiste des listes affichées.
class TasksProvider extends ChangeNotifier {
  TasksProvider({required this.repository});

  final TaskRepository repository;

  // Données
  List<Category> categories = [];
  List<TaskItem> todayTasks = [];
  List<TaskItem> yesterdayTasks = [];
  List<TaskItem> dayTasks = [];
  ProfileStats? stats;

  // Jour sélectionné (timeline + calendrier).
  DateTime selectedDate = DateTime.now();

  // États de chargement / erreur
  bool loading = false;
  String? error;
  bool dayLoading = false;
  String? dayError;

  String get _todayApi => FlowDates.apiDate(DateTime.now());
  String get _yesterdayApi =>
      FlowDates.apiDate(DateTime.now().subtract(const Duration(days: 1)));

  // ---------------------------------------------------------------------
  // Chargement initial (accueil + jour sélectionné + stats)
  // ---------------------------------------------------------------------
  Future<void> loadInitial() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      categories = await repository.fetchCategories();
      todayTasks = await repository.fetchTasks(date: _todayApi);
      yesterdayTasks = await repository.fetchTasks(date: _yesterdayApi);
      dayTasks = await repository.fetchTasks(
        date: FlowDates.apiDate(selectedDate),
      );
      stats = await repository.fetchStats();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Impossible de contacter le serveur.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Recharge tout (bouton « Réessayer »).
  Future<void> retry() => loadInitial();

  // ---------------------------------------------------------------------
  // F1 / F2 — changer de jour (timeline et calendrier partagent la date)
  // ---------------------------------------------------------------------
  Future<void> selectDate(DateTime date) async {
    selectedDate = date;
    dayLoading = true;
    dayError = null;
    notifyListeners();
    try {
      dayTasks = await repository.fetchTasks(date: FlowDates.apiDate(date));
    } on ApiException catch (e) {
      dayError = e.message;
      dayTasks = [];
    } catch (_) {
      dayError = 'Impossible de contacter le serveur.';
      dayTasks = [];
    } finally {
      dayLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadDay() => selectDate(selectedDate);

  // ---------------------------------------------------------------------
  // F7 — tâches d'une catégorie (page « tâches de la catégorie »)
  // ---------------------------------------------------------------------
  /// Toutes les tâches de [categoryId] (tous les jours), triées par
  /// (date, heure) pour le groupement par jour de la page catégorie.
  Future<List<TaskItem>> tasksOfCategory(String categoryId) async {
    final tasks = await repository.fetchTasks(category: categoryId);
    final sorted = List<TaskItem>.from(tasks);
    sorted.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.time.compareTo(b.time);
    });
    return sorted;
  }

  // ---------------------------------------------------------------------
  // F3 — création
  // ---------------------------------------------------------------------
  Future<void> createTask({
    required String title,
    String description = '',
    required String date,
    required String time,
    required String categoryId,
  }) async {
    final task = await repository.createTask(
      title: title,
      description: description,
      date: date,
      time: time,
      categoryId: categoryId,
    );
    _insert(task);
    _adjustStats(totalDelta: 1, completedDelta: task.completed ? 1 : 0);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // F4 — modification
  // ---------------------------------------------------------------------
  Future<void> updateTask(
    TaskItem task, {
    required String title,
    required String description,
    required String date,
    required String time,
    required String categoryId,
  }) async {
    final updated = await repository.updateTask(
      task.id,
      title: title,
      description: description,
      date: date,
      time: time,
      categoryId: categoryId,
    );
    _removeById(updated.id);
    _insert(updated);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // F5 — suppression
  // ---------------------------------------------------------------------
  Future<void> deleteTask(TaskItem task) async {
    await repository.deleteTask(task.id);
    _removeById(task.id);
    _adjustStats(totalDelta: -1, completedDelta: task.completed ? -1 : 0);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // F6 — terminer / déterminer (mise à jour optimiste)
  // ---------------------------------------------------------------------
  Future<bool> toggle(TaskItem task) async {
    final previous = task.completed;
    _applyCompleted(task.id, !previous);
    notifyListeners();
    try {
      final updated = await repository.toggleTask(task.id);
      _removeById(updated.id);
      _insert(updated);
      _adjustStats(completedDelta: updated.completed ? 1 : -1);
      notifyListeners();
      return true;
    } catch (_) {
      // Annulation de l'optimisme en cas d'échec (les stats n'ont été
      // ajustées qu'après succès de l'API).
      _applyCompleted(task.id, previous);
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Statistiques
  // ---------------------------------------------------------------------
  Future<void> loadStats() async {
    try {
      stats = await repository.fetchStats();
      notifyListeners();
    } on ApiException {
      // Conserve les valeurs déjà chargées.
    } catch (_) {
      // Réseau indisponible : on garde l'existant.
    }
  }

  // ---------------------------------------------------------------------
  // Déconnexion — aucune donnée du compte précédent ne subsiste
  // ---------------------------------------------------------------------
  void reset() {
    categories = [];
    todayTasks = [];
    yesterdayTasks = [];
    dayTasks = [];
    stats = null;
    selectedDate = DateTime.now();
    loading = false;
    error = null;
    dayLoading = false;
    dayError = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Mises à jour locales des listes
  // ---------------------------------------------------------------------
  void _insert(TaskItem task) {
    if (task.date == _todayApi) todayTasks = _sorted([...todayTasks, task]);
    if (task.date == _yesterdayApi) {
      yesterdayTasks = _sorted([...yesterdayTasks, task]);
    }
    if (task.date == FlowDates.apiDate(selectedDate)) {
      dayTasks = _sorted([...dayTasks, task]);
    }
  }

  void _removeById(String id) {
    todayTasks = todayTasks.where((t) => t.id != id).toList();
    yesterdayTasks = yesterdayTasks.where((t) => t.id != id).toList();
    dayTasks = dayTasks.where((t) => t.id != id).toList();
  }

  void _applyCompleted(String id, bool value) {
    List<TaskItem> apply(List<TaskItem> list) => [
      for (final t in list)
        t.id == id
            ? TaskItem(
                id: t.id,
                title: t.title,
                description: t.description,
                date: t.date,
                time: t.time,
                category: t.category,
                completed: value,
              )
            : t,
    ];
    todayTasks = apply(todayTasks);
    yesterdayTasks = apply(yesterdayTasks);
    dayTasks = apply(dayTasks);
  }

  void _adjustStats({int totalDelta = 0, int completedDelta = 0}) {
    final current = stats;
    if (current == null && totalDelta == 0 && completedDelta == 0) return;
    stats = ProfileStats(
      totalTasks: (current?.totalTasks ?? 0) + totalDelta,
      completedTasks: (current?.completedTasks ?? 0) + completedDelta,
      tasksThisWeek: current?.tasksThisWeek ?? 0,
    );
  }

  List<TaskItem> _sorted(List<TaskItem> list) {
    final sorted = List<TaskItem>.from(list);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
  }
}
