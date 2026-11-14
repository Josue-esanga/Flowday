import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Surface d'action des feuilles du bas (bottom sheets) : blanche, arrondie
/// et légèrement bordée pour rester lisible sur le fond de la feuille.
///
/// Le fond reste blanc en thème clair ; en thème sombre il reprend la
/// couleur des cartes pour conserver un contraste confortable.
class SheetActionSurface extends StatelessWidget {
  const SheetActionSurface({
    super.key,
    required this.child,
    this.selected = false,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;

  /// Met en évidence l'action sélectionnée (bordure plus marquée).
  final bool selected;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? theme.cardColor : Colors.white;
    final borderColor = selected
        ? (isDark ? theme.colorScheme.primary : AppColors.dark)
        : (isDark ? theme.dividerColor : AppColors.divider);

    return Padding(
      padding: margin,
      child: Material(
        color: background,
        // Surface volontairement plate : pas d'élévation, donc aucun voile
        // `surfaceTint` ni ombre grise. Le blanc reste net, la bordure
        // suffit à détacher l'action du fond de la feuille.
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: selected ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
