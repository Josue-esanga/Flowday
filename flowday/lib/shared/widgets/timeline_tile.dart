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
    final featuredColor = AppColors.contrast(context);
    final lineColor = Theme.of(context).brightness == Brightness.dark
        ? colors.outlineVariant
        : AppColors.dark;
    // Toutes les tâches partagent le même cadre contrasté (anthracite en
    // clair, blanc en sombre) ; la première est simplement mise en avant.
    final titleColor = AppColors.onContrast(context);
    final secondaryColor = AppColors.onContrastMuted(context);

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
                padding: EdgeInsets.all(compact ? 14 : 18),
                decoration: BoxDecoration(
                  color: featuredColor,
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

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // F6 : action « terminée » — la case reflète l'état
                        // réel de la tâche (cochée uniquement si terminée).
                        GestureDetector(
                          onTap: onToggle,
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: completed
                                  ? AppColors.onContrast(context)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.onContrast(context),
                                width: 2,
                              ),
                            ),
                            child: completed
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.contrast(context),
                                    size: 25,
                                  )
                                : null,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          completed
                              ? context.tr('Terminée')
                              : context.tr('À faire'),
                          style: TextStyle(
                            color: completed
                                ? AppColors.onContrast(context)
                                : AppColors.onContrastMuted(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
