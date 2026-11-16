import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/data/task_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/date_utils.dart';
import '../errors/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../services/task_reminder_service.dart';

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
  final Set<String> _pendingTaskToggles = {};

  /// Nombre de tâches connues par jour, pour les mois déjà chargés par le
  /// calendrier. La carte est mise à jour après chaque mutation locale.
  final Map<String, Map<String, int>> _calendarTaskCounts = {};
  final Set<String> _calendarLoadingMonths = {};

  // Jour sélectionné (timeline + calendrier).
  DateTime selectedDate = DateTime.now();

  /// Numéro de la dernière demande de jour : les réponses arrivées dans le
  /// désordre (appuis rapides sur plusieurs dates) sont ignorées.
  int _dayRequest = 0;

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
    _calendarTaskCounts.clear();
    _calendarLoadingMonths.clear();
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
      error = AppLocalizations.instance.t(
        'Impossible de contacter le serveur.',
      );
    } finally {
      loading = false;
      notifyListeners();
    }
    unawaited(syncReminders());
  }

  /// Programme les rappels des tâches des 90 prochains jours.
  Future<void> syncReminders() async {
    final reminders = TaskReminderService.instance;
    if (!reminders.isEnabled) return;
    try {
      final today = DateTime.now();
      final tasks = await repository.fetchTasks(
        start: FlowDates.apiDate(today),
        end: FlowDates.apiDate(today.add(const Duration(days: 90))),
      );
      await reminders.replaceScheduledTasks(tasks.take(400).toList());
    } catch (_) {
      // Les rappels seront recalculés au prochain chargement réussi.
    }
  }

  /// Recharge tout (bouton « Réessayer »).
  Future<void> retry() => loadInitial();

  // ---------------------------------------------------------------------
  // F8 — stockage local / hors ligne
  // ---------------------------------------------------------------------
  /// Vrai quand les données affichées proviennent du cache local.
  bool get isOffline => repository.isOffline;

  /// Modifications locales restant à synchroniser avec le serveur.
  int get pendingWrites => repository.pendingWrites;

  /// Bouton « Réessayer » du bandeau hors ligne : pousse d'abord les
  /// modifications en attente, puis recharge les données.
  Future<void> retrySync() async {
    try {
      await repository.retryNow();
    } catch (_) {
      // Toujours hors ligne : le bandeau reste affiché.
    }
    await loadInitial();
  }

  // ---------------------------------------------------------------------
  // Calendrier — repères des jours qui contiennent des tâches
  // ---------------------------------------------------------------------
  String _calendarMonthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  bool isCalendarMonthLoaded(int year, int month) =>
      _calendarTaskCounts.containsKey(_calendarMonthKey(year, month));

  /// Vrai si au moins une tâche est prévue ce jour-là (mois chargé).
  bool hasTasksOn(DateTime date) {
    final counts =
        _calendarTaskCounts[_calendarMonthKey(date.year, date.month)];
    return (counts?[FlowDates.apiDate(date)] ?? 0) > 0;
  }

  /// Charge les tâches du mois affiché, une seule fois (cache local).
  Future<void> ensureCalendarMonth(int year, int month) async {
    final key = _calendarMonthKey(year, month);
    if (_calendarTaskCounts.containsKey(key) ||
        !_calendarLoadingMonths.add(key)) {
      return;
    }

    try {
      final first = DateTime(year, month, 1);
      final last = DateTime(year, month + 1, 0);
      final tasks = await repository.fetchTasks(
        start: FlowDates.apiDate(first),
        end: FlowDates.apiDate(last),
      );
      final counts = <String, int>{};
      for (final task in tasks) {
        counts.update(task.date, (value) => value + 1, ifAbsent: () => 1);
      }
      _calendarTaskCounts[key] = counts;
      notifyListeners();
    } catch (_) {
      // Le calendrier reste utilisable sans repères ; une prochaine
      // ouverture du mois retentera le chargement.
    } finally {
      _calendarLoadingMonths.remove(key);
    }
  }

  void _bumpCalendarDay(String date, int delta) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return;
    final counts =
        _calendarTaskCounts[_calendarMonthKey(parsed.year, parsed.month)];
    if (counts == null) return;
    final next = (counts[date] ?? 0) + delta;
    if (next <= 0) {
      counts.remove(date);
    } else {
      counts[date] = next;
    }
  }

  // ---------------------------------------------------------------------
  // F1 / F2 — changer de jour (timeline et calendrier partagent la date)
  // ---------------------------------------------------------------------
  Future<void> selectDate(DateTime date) async {
    final request = ++_dayRequest;
    selectedDate = date;
    dayLoading = true;
    dayError = null;
    notifyListeners();
    try {
      final tasks = await repository.fetchTasks(
        date: FlowDates.apiDate(date),
      );
      if (request != _dayRequest) return;
      dayTasks = tasks;
    } on ApiException catch (e) {
      if (request != _dayRequest) return;
      dayError = e.message;
      dayTasks = [];
    } catch (_) {
      if (request != _dayRequest) return;
      dayError = AppLocalizations.instance.t(
        'Impossible de contacter le serveur.',
      );
      dayTasks = [];
    } finally {
      if (request == _dayRequest) {
        dayLoading = false;
        notifyListeners();
      }
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
    _bumpCalendarDay(task.date, 1);
    _adjustStats(totalDelta: 1, completedDelta: task.completed ? 1 : 0);
    notifyListeners();
    unawaited(syncReminders());
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
    _bumpCalendarDay(task.date, -1);
    _bumpCalendarDay(updated.date, 1);
    notifyListeners();
    unawaited(syncReminders());
  }

  // ---------------------------------------------------------------------
  // F5 — suppression
  // ---------------------------------------------------------------------
  Future<void> deleteTask(TaskItem task) async {
    await repository.deleteTask(task.id);
    _removeById(task.id);
    _bumpCalendarDay(task.date, -1);
    _adjustStats(totalDelta: -1, completedDelta: task.completed ? -1 : 0);
    notifyListeners();
    unawaited(syncReminders());
  }

  // ---------------------------------------------------------------------
  // F6 — terminer / déterminer (mise à jour optimiste)
  // ---------------------------------------------------------------------
  Future<bool> toggle(TaskItem task) async {
    // Mise à jour optimiste **immédiate** : même si un envoi est déjà en
    // cours pour cette tâche, l'appui suivant s'applique tout de suite (il
    // sera envoyé à la suite). Aucun clic n'est ignoré.
    final current = _completedOf(task.id) ?? task.completed;
    _applyCompleted(task.id, !current);
    _adjustStats(completedDelta: current ? -1 : 1);
    notifyListeners();

    if (!_pendingTaskToggles.add(task.id)) return true;
    var sent = !current;
    try {
      while (true) {
        TaskItem updated;
        try {
          updated = await repository.setTaskCompleted(task.id, sent);
        } catch (_) {
          // Échec : on revient à l'état précédent (si l'utilisateur n'a pas
          // encore changé d'avis entre-temps).
          if (_completedOf(task.id) == sent) {
            _applyCompleted(task.id, !sent);
            _adjustStats(completedDelta: sent ? -1 : 1);
          }
          return false;
        }
        final desired = _completedOf(task.id);
        if (desired == null || desired == sent) {
          // Aucun appui entre-temps : on aligne la liste sur le serveur.
          _removeById(updated.id);
          _insert(updated);
          notifyListeners();
          return true;
        }
        // Un appui a eu lieu pendant l'envoi : l'état optimiste est déjà
        // affiché, on envoie simplement la nouvelle valeur à la suite.
        sent = desired;
      }
    } finally {
      _pendingTaskToggles.remove(task.id);
      unawaited(syncReminders());
    }
  }

  /// État « terminée » actuel d'une tâche dans les listes affichées.
  bool? _completedOf(String id) {
    for (final list in [todayTasks, yesterdayTasks, dayTasks]) {
      for (final task in list) {
        if (task.id == id) return task.completed;
      }
    }
    return null;
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
    _pendingTaskToggles.clear();
    _calendarTaskCounts.clear();
    _calendarLoadingMonths.clear();
    _dayRequest++; // invalide les chargements de jour en cours
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
    if (current == null && totalDelta == 0) return;
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
