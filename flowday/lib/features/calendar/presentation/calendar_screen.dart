import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/skeleton.dart';

/// Vue calendrier mensuelle (README §3.3) — navigation de mois réelle,
/// jour sélectionné en cercle sombre, résumé du jour alimenté par l'API.
///
/// Le jour choisi est partagé avec la timeline (`TasksProvider.selectedDate`) :
/// le résumé affiche le nombre réel de tâches, et « Voir les tâches » ouvre
/// la timeline sur cette date.
///
/// Responsive : la taille des cellules est calculée à partir de la largeur
/// disponible (téléphone étroit comme tablette / web), et le contenu défile
/// verticalement pour éviter tout débordement sur les petits écrans.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.onOpenTimeline});

  /// Ouvre la timeline sur la date du jour sélectionné (onglet Accueil).
  final ValueChanged<DateTime> onOpenTimeline;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const List<String> _weekLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = context.watch<TasksProvider>();
    final selected = state.selectedDate;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    // Grille du mois : 1er jour (lundi = 0) + nombre de jours.
    final firstDay = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Géométrie de la grille : 7 colonnes égales dans la largeur utile.
        const horizontalPadding = 20.0;
        final contentWidth = constraints.maxWidth - horizontalPadding * 2;
        final cellWidth = contentWidth / 7;
        final rowHeight = math.min(cellWidth, 54.0);
        final circleSize = math.min(cellWidth - 6, 46.0);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding + 24,
            horizontalPadding,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------
              // Titre
              // ----------------------------------------------------------
              Text(
                'Calendrier',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: isCompact ? 26 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // Navigation de mois
              // ----------------------------------------------------------
              Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: Icon(Icons.chevron_left, color: colors.primary),
                  ),
                  Expanded(
                    child: Text(
                      '${FlowDates.months[_month - 1]} $_year',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: isCompact ? 15 : 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: Icon(Icons.chevron_right, color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ----------------------------------------------------------
              // Jours de la semaine (alignés sur les colonnes de la grille)
              // ----------------------------------------------------------
              Row(
                children: [
                  for (final label in _weekLabels)
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.65),
                              fontSize: isCompact ? 11 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ----------------------------------------------------------
              // Grille des jours (cases vides + jours cliquables)
              // ----------------------------------------------------------
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                childAspectRatio: cellWidth / rowHeight,
                children: [
                  for (var i = 0; i < leadingBlanks; i++)
                    const SizedBox.shrink(),
                  for (var day = 1; day <= daysInMonth; day++)
                    _DayCell(
                      day: day,
                      size: circleSize,
                      fontSize: math.min(
                        circleSize * 0.34,
                        isCompact ? 13.0 : 15.0,
                      ),
                      selected:
                          selected.year == _year &&
                          selected.month == _month &&
                          selected.day == day,
                      onTap: () => context.read<TasksProvider>().selectDate(
                        DateTime(_year, _month, day),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ----------------------------------------------------------
              // Résumé du jour sélectionné (données API)
              // ----------------------------------------------------------
              _SelectedDaySummary(
                selected: selected,
                isCompact: isCompact,
                count: state.dayTasks.length,
                loading: state.dayLoading,
                error: state.dayError,
                onOpenTimeline: () => widget.onOpenTimeline(selected),
                onRetry: state.reloadDay,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================================
// CASE DE JOUR
// ======================================================================
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.size,
    required this.fontSize,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final double size;
  final double fontSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              color: selected ? colors.onPrimary : colors.onSurface,
              fontSize: fontSize,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// RÉSUMÉ DU JOUR SÉLECTIONNÉ
// ======================================================================
class _SelectedDaySummary extends StatelessWidget {
  const _SelectedDaySummary({
    required this.selected,
    required this.isCompact,
    required this.count,
    required this.loading,
    required this.error,
    required this.onOpenTimeline,
    required this.onRetry,
  });

  final DateTime selected;
  final bool isCompact;
  final int count;
  final bool loading;
  final String? error;
  final VoidCallback onOpenTimeline;
  final VoidCallback onRetry;

  String get _weekday => FlowDates.weekdayName(selected);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String subtitle;
    if (loading) {
      subtitle = 'Chargement…';
    } else if (error != null) {
      subtitle = error!;
    } else if (count == 0) {
      subtitle = 'Aucune tâche prévue';
    } else if (count == 1) {
      subtitle = '1 tâche prévue';
    } else {
      subtitle = '$count tâches prévues';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.cardColor
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_weekday, ${FlowDates.months[selected.month - 1]} ${selected.day}',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isCompact ? 15 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          // Chargement : petite barre skeleton plutôt que « Chargement… ».
          if (loading)
            const Skeleton(width: 150, height: 14, radius: 7)
          else
            Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: error == null ? onOpenTimeline : onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                error == null ? 'Voir les tâches du jour' : 'Réessayer',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
