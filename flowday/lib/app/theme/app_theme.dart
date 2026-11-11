import 'package:flutter/material.dart';

/// Charte graphique de Flowday (README §6) — thème sombre.
///
/// Toutes les couleurs de l'application sont centralisées ici pour
/// garantir la cohérence entre les écrans.
class AppColors {
  AppColors._();

  /// Fond général : gris très foncé.
  static const Color background = Color(0xFF0B0B0C);

  /// Cartes et surfaces secondaires : gris anthracite.
  static const Color surface = Color(0xFF1B1B1D);

  /// Surfaces plus claires (chips, éléments inactifs).
  static const Color surfaceStrong = Color(0xFF232326);

  /// Barre de navigation inférieure.
  static const Color navBar = Color(0xFF161618);

  /// Couleur d'accent : orange vif (jour actif, FAB, timeline, badges).
  static const Color accent = Color(0xFFF4761F);

  /// Texte principal.
  static const Color textPrimary = Color(0xFFF4F4F5);

  /// Texte secondaire (descriptions, heures, labels inactifs).
  static const Color textSecondary = Color(0xFF9A9A9E);

  /// Bordures et séparateurs discrets.
  static const Color divider = Color(0xFF2A2A2D);

  /// Couleurs des catégories (README §5).
  static const Color work = Color(0xFFF4761F); // orange
  static const Color health = Color(0xFFF5C542); // jaune
  static const Color personal = Color(0xFFF05B52); // rouge
  static const Color education = Color(0xFF4E8CFF); // bleu (maquette)
}

/// Thème sombre initial du produit.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      splashColor: AppColors.accent.withValues(alpha: 0.12),
      highlightColor: AppColors.accent.withValues(alpha: 0.08),
    );
  }
}
