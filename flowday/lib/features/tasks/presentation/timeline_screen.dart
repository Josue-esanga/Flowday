import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/widgets/timeline_tile.dart';

/// « Today's task » : flèche de retour, sélecteur de semaine et timeline
/// verticale des tâches — maquette 1.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _selectedDayIndex = MockData.defaultWeekDayIndex;

  @override
  Widget build(BuildContext context) {
    // Les tâches affichées sont celles du jour sélectionné (maquette :
    // même liste quel que soit le jour, la logique arrivera plus tard).
    final tasks = MockData.todayTasks;

    return Column(
      children: [
        // ----------------------------------------------------------------
        // En-tête : retour + titre
        // ----------------------------------------------------------------
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "Today's task",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ----------------------------------------------------------------
        // Sélecteur de semaine
        // ----------------------------------------------------------------
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: MockData.weekDays.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final day = MockData.weekDays[index];
              final selected = index == _selectedDayIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 45,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent
                        : AppColors.surfaceStrong,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.dayNumber}',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                    return TimelineTile(
                      task: tasks[index],
                      isFirst: index == 0,
                      isLast: index == tasks.length - 1,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Message affiché lorsqu'aucune tâche n'existe pour le jour (README §3.1).
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
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Aucune tâche pour ce jour',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
