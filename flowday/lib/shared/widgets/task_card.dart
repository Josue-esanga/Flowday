import 'package:flutter/material.dart';

import '../models/models.dart';
import '../../app/theme/app_theme.dart';

/// Pastille de catégorie colorée (point + nom).
class CategoryLabel extends StatelessWidget {
  const CategoryLabel({super.key, required this.category, this.fontSize = 12});

  final Category category;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          category.name,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Badge horaire orange (« 02:00 pm ») utilisé sur les cartes de l'accueil.
class TimeBadge extends StatelessWidget {
  const TimeBadge({super.key, required this.timeLabel});

  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        timeLabel.toLowerCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Case à cocher carrée : cochée (orange) ou vide (contour gris).
class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        color: checked ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: checked
            ? null
            : Border.all(color: AppColors.textSecondary, width: 1.6),
      ),
      child: checked
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : null,
    );
  }
}

/// Carte de tâche de l'accueil : case, titre, description, heure et
/// catégorie. Le titre et la description sont barrés si terminée.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: task.completed ? AppColors.textSecondary : AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      decoration: task.completed ? TextDecoration.lineThrough : null,
    );
    final descStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      decoration: task.completed ? TextDecoration.lineThrough : null,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskCheckbox(checked: task.completed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: titleStyle),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(task.description, style: descStyle),
                  ],
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      TimeBadge(timeLabel: task.timeLabel),
                      const SizedBox(width: 10),
                      CategoryLabel(category: task.category),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
