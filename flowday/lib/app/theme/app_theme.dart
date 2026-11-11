import 'package:flutter/material.dart';

/// Charte graphique de Flowday — thème clair (nouveau design).
///
/// Palette reprise du design de référence : fond bleu-gris très clair,
/// en-têtes et éléments d'action en gris anthracite, cartes arrondies.
class AppColors {
  AppColors._();

  /// Fond général (bleu-gris clair).
  static const Color bgColor = Color(0xFFE7E9F4);

  /// Blanc des écrans et cartes.
  static const Color white = Colors.white;

  /// En-têtes, boutons et éléments sombres.
  static const Color dark = Color(0xFF202020);

  /// Texte principal.
  static const Color text = Color(0xFF151515);

  /// Texte secondaire (dates, descriptions, labels inactifs).
  static const Color muted = Color(0xFF9295A3);

  /// Cartes claires (variante claire des cartes de projet).
  static const Color lightCard = Color(0xFFF0F1FF);

  /// Champs de recherche et de formulaire.
  static const Color field = Color(0xFFF7F7FA);

  /// Cartes de tâches de la liste.
  static const Color itemBg = Color(0xFFFAFAFC);

  /// Texte des cartes de tâches.
  static const Color itemText = Color(0xFF777987);

  /// Barre de navigation inférieure.
  static const Color navBg = Color(0xFFFAFAFC);
  static const Color navIconInactive = Color(0xFFC8CAD3);
  static const Color navBorder = Color(0xFF9CB7C0);

  /// Séparateurs discrets.
  static const Color divider = Color(0xFFE4E5EF);

  /// Icône grise de la loupe.
  static const Color placeholderIcon = Color(0xFFB9BBC4);
  static const Color placeholderText = Color(0xFF9B9DA8);

  /// Couleurs des avatars.
  static const Color avatarSkin = Color(0xFFD5B5A1);

  /// Couleurs des catégories (README §5).
  static const Color work = Color(0xFFF4761F); // orange
  static const Color health = Color(0xFFF5C542); // jaune
  static const Color personal = Color(0xFFF05B52); // rouge
  static const Color education = Color(0xFF4E8CFF); // bleu
}

/// Thème clair de l'application.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.dark,
        secondary: AppColors.dark,
        surface: AppColors.white,
        onSurface: AppColors.text,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      splashColor: AppColors.dark.withValues(alpha: 0.06),
      highlightColor: AppColors.dark.withValues(alpha: 0.04),
    );
  }
}
