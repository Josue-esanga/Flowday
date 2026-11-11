import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Vue calendrier mensuelle (README §3.3) — jour sélectionné en cercle
/// sombre.
///
/// Responsive : la taille des cellules est calculée à partir de la largeur
/// disponible (téléphone étroit comme tablette / web), et le contenu défile
/// verticalement pour éviter tout débordement sur les petits écrans.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static const List<String> _weekLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    // Juin 2026 : le 1er tombe un lundi → 30 cases, jour 28 sélectionné.
    const daysInMonth = 30;
    const selectedDay = 28;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

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
                  color: AppColors.text,
                  fontSize: isCompact ? 26 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // Navigation de mois
              // ----------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.dark,
                    ),
                  ),
                  Text(
                    'June 2026',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppColors.dark,
                    ),
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
                              color: AppColors.muted,
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
              // Grille des jours
              // ----------------------------------------------------------
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                childAspectRatio: cellWidth / rowHeight,
                children: [
                  for (var day = 1; day <= daysInMonth; day++)
                    Center(
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: day == selectedDay
                              ? AppColors.dark
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: day == selectedDay
                                ? Colors.white
                                : AppColors.text,
                            fontSize: math.min(
                              circleSize * 0.34,
                              isCompact ? 13.0 : 15.0,
                            ),
                            fontWeight: day == selectedDay
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ----------------------------------------------------------
              // Résumé du jour sélectionné
              // ----------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lightCard,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Friday, June 28',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: isCompact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '4 tâches prévues',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
