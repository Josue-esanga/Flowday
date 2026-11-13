import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Carte de tâche de la liste (style du design de référence) :
/// case carrée sombre, titre + sous-titre, pastille ou heure à droite.
class TaskListItem extends StatelessWidget {
  const TaskListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.completed = false,
    this.trailing,
    this.onTap,
    this.onToggle,
  });

  final String title;
  final String subtitle;
  final bool completed;

  /// Élément à droite (heure, pastille…).
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.cardColor
              : AppColors.itemBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Case à cocher.
            Semantics(
              button: true,
              label: completed
                  ? 'Tâche terminée : $title'
                  : 'Terminer : $title',
              child: InkWell(
                onTap: onToggle ?? onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: completed
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: theme.colorScheme.onSurface,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: completed
                        ? const Icon(Icons.check, color: Colors.white, size: 21)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.onSurface
                          : AppColors.itemText,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.75)
                          : AppColors.itemText,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else
              const Icon(Icons.circle, color: AppColors.dark, size: 11),
          ],
        ),
      ),
    );
  }
}
