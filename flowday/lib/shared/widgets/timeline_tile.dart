import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../models/models.dart';

/// Une ligne de la timeline : point relié par un trait vertical, puis le
/// contenu de la tâche (heure à droite). La première tâche de la journée
/// est mise en avant (carte sombre « featured »), comme sur le design.
class TimelineTask extends StatelessWidget {
  const TimelineTask({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    this.category,
    this.completed = false,
    this.featured = false,
    this.isLast = false,
    this.onTap,
    this.onToggle,
  });

  final String title;
  final String description;
  final String time;
  final Category? category;
  final bool completed;
  final bool featured;
  final bool isLast;
  final VoidCallback? onTap;

  /// F6 : appuyer sur le point (ou le bouton check) inverse l'état.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final featuredColor = Theme.of(context).brightness == Brightness.dark
        ? colors.surface
        : AppColors.dark;
    final lineColor = Theme.of(context).brightness == Brightness.dark
        ? colors.outlineVariant
        : AppColors.dark;
    final titleColor = featured ? Colors.white : colors.onSurface;
    final secondaryColor = featured
        ? Colors.white70
        : colors.onSurface.withValues(alpha: 0.62);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----------------------------------------------------------------
          // Point + trait de liaison
          // ----------------------------------------------------------------
          SizedBox(
            width: 35,
            child: Column(
              children: [
                // F6 : le point de la timeline inverse l'état de la tâche.
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: featured
                            ? Colors.white
                            : completed
                            ? colors.primary
                            : Colors.transparent,
                        border: Border.all(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ----------------------------------------------------------------
          // Contenu de la tâche
          // ----------------------------------------------------------------
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: featured
                    ? EdgeInsets.all(compact ? 14 : 18)
                    : const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: featured ? featuredColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: featured
                                  ? (compact ? 21 : 23)
                                  : (compact ? 18 : 20),
                              fontWeight: FontWeight.bold,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            time,
                            maxLines: 1,
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: compact ? 12 : 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: compact ? 13 : 14,
                          height: 1.4,
                        ),
                      ),
                    ],

                    if (category != null) ...[
                      const SizedBox(height: 10),
                      CategoryLabel(category: category!, color: secondaryColor),
                    ],

                    if (featured) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // F6 : action « terminée ».
                          GestureDetector(
                            onTap: onToggle,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppColors.dark,
                                size: 25,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            completed
                                ? context.tr('Terminée')
                                : context.tr('À faire'),
                            style: TextStyle(
                              color: completed ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille de catégorie colorée (point + nom), réutilisée dans les
/// listes de tâches et la timeline.
class CategoryLabel extends StatelessWidget {
  const CategoryLabel({
    super.key,
    required this.category,
    this.fontSize = 13,
    this.color,
  });

  final Category category;
  final double fontSize;

  /// Couleur du texte (défaut : gris secondaire).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppLocalizations.of(context)
                .categoryName(category.id, category.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  color ??
                  Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.62),
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
