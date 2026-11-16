import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/sheet_action_surface.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/timeline_tile.dart';
import 'task_form_screen.dart';

/// « Today's task » : retour + date + grand titre, sélecteur de dates en
/// pilules verticales (semaine réelle) et timeline des tâches chargées
/// depuis l'API (F1, F2, F6).
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _selectedIndex(DateTime selected, List<DateTime> week) {
    return week.indexWhere(
      (day) =>
          day.year == selected.year &&
          day.month == selected.month &&
          day.day == selected.day,
    );
  }

  Future<void> _toggle(TaskItem task) async {
    final state = context.read<TasksProvider>();
    final ok = await state.toggle(task);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Action impossible (serveur injoignable).')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TasksProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
    );
    final isToday = selected == today;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 360;
    final week = FlowDates.weekOf(state.selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ----------------------------------------------------------------
        // En-tête : retour + date + grand titre + avatar
        // ----------------------------------------------------------------
        Padding(
          padding: EdgeInsets.fromLTRB(10, topPadding + 18, 22, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FlowDates.displayDate(state.selectedDate),
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.65),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isToday
                          ? context.tr('Today')
                          : FlowDates.weekdayName(selected),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: compact
                            ? 31
                            : screenWidth < 600
                            ? 35
                            : 39,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Photo de profil dynamique (initiales à défaut).
              Avatar(
                initials: auth.fullName.trim().isEmpty
                    ? 'M'
                    : auth.fullName.trim()[0].toUpperCase(),
                color: AppColors.avatarSkin,
                size: 50,
                image: auth.avatar,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ----------------------------------------------------------------
        // Sélecteur de dates (pilules verticales)
        // ----------------------------------------------------------------
        LayoutBuilder(
          builder: (context, constraints) {
            final pillWidth = constraints.maxWidth / week.length;
            return SizedBox(
              height: compact ? 88 : 98,
              child: Row(
                children: [
                  for (var i = 0; i < week.length; i++)
                    SizedBox(
                      width: pillWidth,
                      child: _DatePill(
                        dayNumber: '${week[i].day}',
                        dayLabel: FlowDates.shortWeekday(week[i]),
                        selected: i == _selectedIndex(state.selectedDate, week),
                        compact: compact,
                        onTap: () =>
                            context.read<TasksProvider>().selectDate(week[i]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: compact ? 12 : 18),

        // ----------------------------------------------------------------
        // Timeline des tâches du jour sélectionné (F1)
        // ----------------------------------------------------------------
        Expanded(child: _TimelineBody(onToggle: _toggle)),
      ],
    );
  }
}

// ======================================================================
// CORPS DE LA TIMELINE : chargement / erreur / vide / liste
// ======================================================================
class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.onToggle});

  final Future<void> Function(TaskItem task) onToggle;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TasksProvider>();

    if (state.dayLoading && state.dayTasks.isEmpty) {
      // Cartouches en skeleton (mêmes formes que les cartes réelles).
      return const SkeletonTimelineList(itemCount: 4);
    }

    if (state.dayError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 46,
                color: AppColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                state.dayError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.reloadDay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(context.tr('Réessayer')),
              ),
            ],
          ),
        ),
      );
    }

    final tasks = state.dayTasks;
    if (tasks.isEmpty) {
      return const _EmptyState();
    }

    // Changement de jour : la liste précédente reste affichée (atténuée)
    // pendant le chargement, au lieu de clignoter en skeleton.
    return IgnorePointer(
      ignoring: state.dayLoading,
      child: AnimatedOpacity(
        opacity: state.dayLoading ? 0.45 : 1,
        duration: const Duration(milliseconds: 150),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TimelineTask(
              title: task.title,
              description: task.description,
              time: task.timeLabel,
              category: task.category,
              completed: task.completed,
              featured: index == 0,
              isLast: index == tasks.length - 1,
              onTap: () => _openEdit(context, task),
              onToggle: () => onToggle(task),
            );
          },
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, TaskItem task) {
    // Ouverture du formulaire en modification (F4) : déléguée à la coque
    // via un pop-up d'actions simple.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SheetActionSurface(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.dark,
                  ),
                  title: Text(l10n.t('Modifier la tâche')),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pushEdit(context, task);
                  },
                ),
              ),
              SheetActionSurface(
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: AppColors.personal,
                  ),
                  title: Text(
                    l10n.t('Supprimer'),
                    style: TextStyle(color: AppColors.personal),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmDelete(context, task);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pushEdit(BuildContext context, TaskItem task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)));
  }

  Future<void> _confirmDelete(BuildContext context, TaskItem task) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.t('Supprimer la tâche ?')),
        content: Text(
          l10n.deleteTaskBody(task.title),
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.t('Annuler'),
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.t('Supprimer'),
              style: TextStyle(color: AppColors.personal),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final state = context.read<TasksProvider>();
    try {
      await state.deleteTask(task);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Suppression impossible.'))),
        );
      }
    }
  }
}

// ======================================================================
// PILULE DE DATE
// ======================================================================
class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.dayNumber,
    required this.dayLabel,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String dayNumber;
  final String dayLabel;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: selected ? (compact ? 82 : 90) : (compact ? 58 : 64),
        decoration: BoxDecoration(
          color: selected
              ? (darkMode ? colors.primary : AppColors.dark)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber,
              style: TextStyle(
                color: selected
                    ? (darkMode ? colors.surface : Colors.white)
                    : colors.onSurface.withValues(alpha: 0.58),
                fontSize: compact ? 13 : 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(height: compact ? 5 : 7),
            Text(
              dayLabel,
              style: TextStyle(
                color: selected
                    ? (darkMode ? colors.surface : Colors.white)
                    : colors.onSurface.withValues(alpha: 0.58),
                fontSize: compact ? 12 : 14,
              ),
            ),
            if (selected) ...[
              SizedBox(height: compact ? 5 : 7),
              CircleAvatar(
                radius: 2.5,
                backgroundColor: darkMode ? colors.surface : Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// ÉTAT VIDE
// ======================================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 46,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('Aucune tâche pour ce jour'),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
