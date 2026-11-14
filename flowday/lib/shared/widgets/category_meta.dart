import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../models/models.dart';

/// Icône d'une catégorie selon son id — utilisé par les cartes de
/// l'accueil et par l'en-tête de la page « tâches de la catégorie ».
/// Les ids viennent de l'API (`GET /api/categories/`).
const Map<String, IconData> categoryIcons = {
  'personal': Icons.person_outline,
  'work': Icons.work_outline,
  'health': Icons.favorite_outline,
  'education': Icons.school_outlined,
};

/// Icône d'une catégorie (repli : étiquette).
IconData categoryIcon(String id) => categoryIcons[id] ?? Icons.label_outline;

/// Nom affiché de la catégorie, traduit pour les catégories connues.
String categoryDisplayName(BuildContext context, Category category) =>
    AppLocalizations.of(context).categoryName(category.id, category.name);

/// Description affichée de la catégorie (repli : nom de la catégorie).
String categoryDisplayDescription(BuildContext context, Category category) =>
    AppLocalizations.of(context)
        .categoryDescription(category.id, category.name);
