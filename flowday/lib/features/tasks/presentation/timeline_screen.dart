import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/timeline_tile.dart';

/// « Today's task » (maquette 1) au style du design de référence :
/// grand titre du jour, sélecteur de dates en pilules verticales et
/// timeline avec la première tâche mise en avant (carte sombre).
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _selectedDayIndex = MockData.defaultWeekDayIndex;

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get _dateLabel {
    final day = MockData.weekDays[_selectedDayIndex];
    return 'June ${day.dayNumber}, 2026';
  }

  String get _bigTitle => _selectedDayIndex == MockData.defaultWeekDayIndex
      ? 'Today'
      : _dayNames[_selectedDayIndex];

  @override
  Widget build(BuildContext context) {
    // Tâches affichées : même maquette quel que soit le jour sélectionné
    // (la logique de chargement arrivera en phase 2).
    final tasks = MockData.todayTasks;
    final topPadding = MediaQuery.of(context).padding.top;

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
                      _dateLabel,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _bigTitle,
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
              for (var i = 0; i < MockData.weekDays.length; i++)
                _DatePill(
                  dayNumber: '${MockData.weekDays[i].dayNumber}',
                  dayLabel: MockData.weekDays[i].label,
                  selected: i == _selectedDayIndex,
                  onTap: () => setState(() => _selectedDayIndex = i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ----------------------------------------------------------------
        // Timeline des tâches
        // ----------------------------------------------------------------
        Expanded(
          child: tasks.isEmpty
              ? const _EmptyState()
              : ListView.builder(
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
                    );
                  },
                ),
        ),
      ],
    );
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
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
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
              const CircleAvatar(
                radius: 3,
                backgroundColor: Colors.white,
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
