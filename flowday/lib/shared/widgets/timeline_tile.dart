import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
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
                        color: (featured || completed)
                            ? AppColors.dark
                            : Colors.white,
                        border: Border.all(color: AppColors.dark, width: 2),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.dark,
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
                    ? const EdgeInsets.all(20)
                    : const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: featured ? AppColors.dark : Colors.transparent,
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
                            style: TextStyle(
                              color: featured ? Colors.white : AppColors.text,
                              fontSize: featured ? 25 : 22,
                              fontWeight: FontWeight.bold,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: featured ? Colors.white : AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      description,
                      style: TextStyle(
                        color: featured ? Colors.white70 : AppColors.muted,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    if (category != null) ...[
                      const SizedBox(height: 10),
                      CategoryLabel(
                        category: category!,
                        color: featured ? Colors.white70 : null,
                      ),
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
                            completed ? 'Terminée' : 'À faire',
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
        Text(
          category.name,
          style: TextStyle(
            color: color ?? AppColors.muted,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
