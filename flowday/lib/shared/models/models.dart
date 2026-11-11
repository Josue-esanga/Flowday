import 'package:flutter/material.dart';

/// Catégorie d'une tâche (README §5).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;
}

/// Tâche affichée dans l'interface (maquette : les champs sont statiques
/// pour le moment, la logique métier arrivera dans une phase ultérieure).
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.timeLabel,
    required this.category,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;

  /// Heure affichée, ex. « 02:00 PM ».
  final String timeLabel;

  final Category category;
  final bool completed;
}

/// Jour du sélecteur de semaine (README §3.1).
class WeekDay {
  const WeekDay({required this.label, required this.dayNumber});

  /// Nom abrégé : « Mon », « Tues », « Fri »…
  final String label;
  final int dayNumber;
}
