import 'package:flutter/material.dart';

/// Description et icône d'une catégorie selon son id — utilisé par les
/// cartes de l'accueil et par l'en-tête de la page « tâches de la
/// catégorie ». Les ids viennent de l'API (`GET /api/categories/`).
const Map<String, (String, IconData)> categoryInfo = {
  'personal': ('Home, family\n& daily life', Icons.person_outline),
  'work': ('Meetings, deadlines\n& office tasks', Icons.work_outline),
  'health': ('Sport, food\n& well-being', Icons.favorite_outline),
  'education': ('Courses, reading\n& learning', Icons.school_outlined),
};

/// Icône d'une catégorie (repli : étiquette).
IconData categoryIcon(String id) => categoryInfo[id]?.$2 ?? Icons.label_outline;
