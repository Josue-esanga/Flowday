import '../fixtures/mock_data.dart';

import 'package:flowday/shared/data/task_repository.dart';
import 'package:flowday/shared/models/models.dart';
import 'package:flowday/shared/utils/date_utils.dart';

/// Faux repository : simule l'API Flowday sans réseau (tests de rendu et
/// tests de logique). Les tâches sont datées de la date demandée (comme
/// l'API qui filtre par `?date=`), et les mutations sont enregistrées pour
/// les assertions.
class FakeTaskRepository implements TaskRepository {
  final createdTasks = <TaskItem>[];
  final updatedIds = <String>[];
  final deletedIds = <String>[];
  final toggledIds = <String>[];

  /// Dernière version connue de chaque tâche (par id), avec la bonne date.
  final Map<String, TaskItem> _store = {};

  String get _today => FlowDates.apiDate(DateTime.now());
  String get _yesterday =>
      FlowDates.apiDate(DateTime.now().subtract(const Duration(days: 1)));

  @override
  Future<List<Category>> fetchCategories() async => MockData.categories;

  @override
  Future<List<TaskItem>> fetchTasks({
    String? date,
    String? start,
    String? end,
    String? category,
  }) async {
    if (category != null) {
      // Filtre catégorie (page « tâches de la catégorie ») : toutes les
      // dates, avec la date d'origine des fixtures.
      final tasks = [
        for (final t in [...MockData.todayTasks, ...MockData.yesterdayTasks])
          if (t.category.id == category)
            TaskItem(
              id: t.id,
              title: t.title,
              description: t.description,
              date: t.date,
              time: t.time,
              category: t.category,
              completed: _store[t.id]?.completed ?? t.completed,
            ),
      ];
      for (final t in tasks) {
        _store[t.id] = t;
      }
      return tasks;
    }

    final day = date ?? _today;
    final source = day == _yesterday
        ? MockData.yesterdayTasks
        : MockData.todayTasks;
    final tasks = [
      for (final t in source)
        TaskItem(
          id: t.id,
          title: t.title,
          description: t.description,
          date: day,
          time: t.time,
          category: t.category,
          completed: _store[t.id]?.completed ?? t.completed,
        ),
    ];
    for (final t in tasks) {
      _store[t.id] = t;
    }
    return tasks;
  }

  @override
  Future<TaskItem> createTask({
    required String title,
    String description = '',
    required String date,
    required String time,
    required String categoryId,
  }) async {
    final task = TaskItem(
      id: 'new-${createdTasks.length + 1}',
      title: title,
      description: description,
      date: date,
      time: time,
      category: _category(categoryId),
      completed: false,
    );
    createdTasks.add(task);
    _store[task.id] = task;
    return task;
  }

  @override
  Future<TaskItem> updateTask(
    String id, {
    String? title,
    String? description,
    String? date,
    String? time,
    String? categoryId,
  }) async {
    updatedIds.add(id);
    final task = _byId(id);
    final updated = TaskItem(
      id: id,
      title: title ?? task.title,
      description: description ?? task.description,
      date: date ?? task.date,
      time: time ?? task.time,
      category: categoryId != null ? _category(categoryId) : task.category,
      completed: task.completed,
    );
    _store[id] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    deletedIds.add(id);
    _store.remove(id);
  }

  @override
  Future<TaskItem> toggleTask(String id) async {
    toggledIds.add(id);
    final task = _byId(id);
    final updated = TaskItem(
      id: task.id,
      title: task.title,
      description: task.description,
      date: task.date,
      time: task.time,
      category: task.category,
      completed: !task.completed,
    );
    _store[id] = updated;
    return updated;
  }

  @override
  Future<TaskItem> setTaskCompleted(String id, bool completed) async {
    toggledIds.add(id);
    final task = _byId(id);
    final updated = TaskItem(
      id: task.id,
      title: task.title,
      description: task.description,
      date: task.date,
      time: task.time,
      category: task.category,
      completed: completed,
    );
    _store[id] = updated;
    return updated;
  }

  @override
  Future<ProfileStats> fetchStats() async =>
      const ProfileStats(totalTasks: 30, completedTasks: 12, tasksThisWeek: 24);

  Category _category(String id) => MockData.categories.firstWhere(
    (c) => c.id == id,
    orElse: () => MockData.work,
  );

  TaskItem _byId(String id) {
    final cached = _store[id];
    if (cached != null) return cached;
    final all = [...MockData.todayTasks, ...MockData.yesterdayTasks];
    return all.firstWhere((t) => t.id == id);
  }
}
