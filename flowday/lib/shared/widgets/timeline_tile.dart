import 'package:flutter/material.dart';

import '../models/models.dart';
import '../../app/theme/app_theme.dart';
import 'task_card.dart';

/// Une ligne de la timeline : heure à gauche, point (état de la tâche)
/// relié par un trait vertical, carte de tâche à droite (README §3.1).
class TimelineTile extends StatelessWidget {
  const TimelineTile({
    super.key,
    required this.task,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  final TaskItem task;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colonne heure + point + trait de liaison.
            SizedBox(
              width: 74,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.timeLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TimelineMarker(completed: task.completed),
                  if (!isLast)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 2,
                          color: AppColors.accent.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Carte de tâche.
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.completed
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          task.description,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 13),
                      CategoryLabel(category: task.category),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Point de la timeline : cochée si la tâche est terminée, sinon cercle
/// vide. C'est ce point qui inversera l'état à la phase « logique ».
class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: completed ? AppColors.accent : AppColors.background,
        shape: BoxShape.circle,
        border: completed
            ? null
            : Border.all(color: AppColors.textSecondary, width: 1.8),
      ),
      child: completed
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}
