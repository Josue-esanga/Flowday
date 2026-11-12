import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/avatar.dart';
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
  List<DateTime> get _week => FlowDates.weekOf(DateTime.now());

  int _selectedIndex(DateTime selected) {
    final monday = FlowDates.mondayOf(DateTime.now());
    return selected.difference(monday).inDays.clamp(0, 6);
  }

  Future<void> _toggle(TaskItem task) async {
    final state = context.read<TasksProvider>();
    final ok = await state.toggle(task);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action impossible (serveur injoignable).'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TasksProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
    );
    final isToday = selected == today;
    final topPadding = MediaQuery.of(context).padding.top;
    final week = _week;

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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppColors.dark,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FlowDates.displayDate(state.selectedDate),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isToday ? 'Today' : FlowDates.weekdayName(selected),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 39,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Avatar(
                initials: 'M',
                color: AppColors.avatarSkin,
                size: 50,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ----------------------------------------------------------------
        // Sélecteur de dates (pilules verticales)
        // ----------------------------------------------------------------
        SizedBox(
          height: 105,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < week.length; i++)
                _DatePill(
                  dayNumber: '${week[i].day}',
                  dayLabel: FlowDates.shortWeekday(week[i]),
                  selected: i == _selectedIndex(state.selectedDate),
                  onTap: () =>
                      context.read<TasksProvider>().selectDate(week[i]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),

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

    if (state.dayLoading) {
      // Liste en skeleton (timeline groupée par heure).
      return const SkeletonTaskList(itemCount: 5);
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
                child: const Text('Réessayer'),
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

    return ListView.builder(
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
    );
  }

  void _openEdit(BuildContext context, TaskItem task) {
    // Ouverture du formulaire en modification (F4) : déléguée à la coque
    // via un pop-up d'actions simple.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.dark),
              title: const Text('Modifier la tâche'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pushEdit(context, task);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.personal),
              title: Text(
                'Supprimer',
                style: TextStyle(color: AppColors.personal),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, task);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pushEdit(BuildContext context, TaskItem task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)));
  }

  Future<void> _confirmDelete(BuildContext context, TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Supprimer la tâche ?'),
        content: Text(
          '« ${task.title} » sera définitivement supprimée.',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Supprimer',
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
          const SnackBar(content: Text('Suppression impossible.')),
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
    required this.onTap,
  });

  final String dayNumber;
  final String dayLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: selected ? 100 : 70,
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              dayLabel,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 14,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 9),
              const CircleAvatar(radius: 3, backgroundColor: Colors.white),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 46,
            color: AppColors.muted,
          ),
          SizedBox(height: 12),
          Text(
            'Aucune tâche pour ce jour',
            style: TextStyle(
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
