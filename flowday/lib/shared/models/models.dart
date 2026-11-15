import 'package:flutter/material.dart';

/// Catégorie d'une tâche (README §5).
class Category {
  const Category({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;

  /// Depuis l'API : `{"id": "work", "name": "Work", "color": "#F4761F"}`.
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    color: _hexToColor(json['color'] as String? ?? '#000000'),
  );

  /// Vers l'API / le cache local (F8).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': colorToHex(color),
  };
}

/// Convertit une couleur hexadécimale « #RRGGBB » en [Color].
Color _hexToColor(String hex) {
  final value = hex.replaceFirst('#', '');
  return Color(int.parse('FF$value', radix: 16));
}

/// Convertit une [Color] en « #RRGGBB » (format de l'API et du cache local).
String colorToHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Tâche planifiée (README §5), adaptée aux formats de l'API :
/// - `date` : « AAAA-MM-JJ »
/// - `time` : « HH:MM » (24 h) ; `timeLabel` affiche « 02:00 PM ».
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    required this.category,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;

  /// Jour planifié au format API (« AAAA-MM-JJ »).
  final String date;

  /// Heure prévue au format API (« HH:MM », 24 h) — tri lexicographique OK.
  final String time;

  final Category category;
  final bool completed;

  /// Heure affichée : « 14:00 » → « 02:00 PM ».
  String get timeLabel {
    final parts = time.split(':');
    var hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? parts[1] : '00';
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour %= 12;
    if (hour == 0) hour = 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  /// Depuis l'API (voir `TaskSerializer`).
  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id'] as String,
    title: json['title'] as String,
    description: (json['description'] ?? '') as String,
    date: json['date'] as String,
    time: _normalizeTime(json['time'] as String),
    category: Category(
      id: json['category'] as String,
      name: (json['category_name'] ?? '') as String,
      color: _hexToColor((json['category_color'] ?? '#000000') as String),
    ),
    completed: (json['completed'] ?? false) as bool,
  );

  /// « 14:00:00 » ou « 14:00 » → « 14:00 ».
  static String _normalizeTime(String raw) {
    final parts = raw.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts.length > 1 ? parts[1] : '00'}';
  }

  /// Vers l'API / le cache local (F8) : mêmes clés que [TaskItem.fromJson].
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'time': time,
    'completed': completed,
    'category': category.id,
    'category_name': category.name,
    'category_color': colorToHex(category.color),
  };

  /// Copie avec les champs fournis remplacés (mutations hors ligne).
  TaskItem copyWith({
    String? title,
    String? description,
    String? date,
    String? time,
    Category? category,
    bool? completed,
  }) => TaskItem(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    date: date ?? this.date,
    time: time ?? this.time,
    category: category ?? this.category,
    completed: completed ?? this.completed,
  );
}

/// Jour du sélecteur de semaine (README §3.1).
class WeekDay {
  const WeekDay({
    required this.label,
    required this.dayNumber,
    required this.date,
  });

  /// Nom abrégé : « Mon », « Tues », « Fri »…
  final String label;
  final int dayNumber;

  /// Date complète du jour (utile pour interroger l'API).
  final DateTime date;
}

/// Statistiques du profil (README §3.5).
class ProfileStats {
  const ProfileStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.tasksThisWeek,
  });

  final int totalTasks;
  final int completedTasks;
  final int tasksThisWeek;

  /// Taux de réussite en % (recalculé côté client pour rester cohérent
  /// après création / suppression / toggle).
  double get successRate => totalTasks == 0
      ? 0.0
      : (completedTasks * 1000 / totalTasks).roundToDouble() / 10;

  factory ProfileStats.fromJson(Map<String, dynamic> json) => ProfileStats(
    totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
    completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
    tasksThisWeek: (json['tasks_this_week'] as num?)?.toInt() ?? 0,
  );

  /// Vers le cache local (F8).
  Map<String, dynamic> toJson() => {
    'total_tasks': totalTasks,
    'completed_tasks': completedTasks,
    'tasks_this_week': tasksThisWeek,
  };
}
