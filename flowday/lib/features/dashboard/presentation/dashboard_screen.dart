import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/task_list_item.dart';
import '../../../shared/widgets/wave_painter.dart';

/// Accueil (maquette 2) au style du design de référence :
/// en-tête sombre avec vagues, recherche + filtre, cartes de catégories
/// en scroll horizontal, puis les tâches d'aujourd'hui et d'hier.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onSeeAll});

  /// Ouvre la timeline « Today's task ».
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _DashboardHeader(),

        // ----------------------------------------------------------------
        // Recherche + bouton de filtre
        // ----------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: AppColors.placeholderIcon,
                  size: 26,
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    'Search',
                    style: TextStyle(
                      color: AppColors.placeholderText,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // ----------------------------------------------------------------
        // Catégories : cartes en scroll horizontal
        // ----------------------------------------------------------------
        const SectionTitle(title: 'Categories', action: 'All'),
        const SizedBox(height: 18),
        SizedBox(
          height: 295,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: const [
              _CategoryCard(
                title: 'Personal',
                description: 'Home, family\n& daily life',
                icon: Icons.person_outline,
                dark: true,
              ),
              SizedBox(width: 14),
              _CategoryCard(
                title: 'Work',
                description: 'Meetings, deadlines\n& office tasks',
                icon: Icons.work_outline,
                dark: false,
              ),
              SizedBox(width: 14),
              _CategoryCard(
                title: 'Health',
                description: 'Sport, food\n& well-being',
                icon: Icons.favorite_outline,
                dark: false,
              ),
              SizedBox(width: 14),
              _CategoryCard(
                title: 'Education',
                description: 'Courses, reading\n& learning',
                icon: Icons.school_outlined,
                dark: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),

        // ----------------------------------------------------------------
        // Tâches du jour
        // ----------------------------------------------------------------
        SectionTitle(
          title: "Today's task",
          action: 'See all',
          onAction: onSeeAll,
        ),
        const SizedBox(height: 15),
        for (final task in MockData.todayTasks)
          TaskListItem(
            title: task.title,
            subtitle: task.description,
            completed: task.completed,
            trailing: Text(
              task.timeLabel.toLowerCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onSeeAll,
          ),
        const SizedBox(height: 20),

        // ----------------------------------------------------------------
        // Tâches d'hier
        // ----------------------------------------------------------------
        SectionTitle(
          title: "Yesterday's task",
          action: 'See all',
          onAction: onSeeAll,
        ),
        const SizedBox(height: 15),
        for (final task in MockData.yesterdayTasks)
          TaskListItem(
            title: task.title,
            subtitle: task.description,
            completed: task.completed,
            trailing: Text(
              task.timeLabel.toLowerCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onSeeAll,
          ),
        const SizedBox(height: 25),
      ],
    );
  }
}

// ======================================================================
// EN-TÊTE SOMBRE AVEC VAGUES
// ======================================================================
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: 225 + topPadding,
      padding: EdgeInsets.fromLTRB(22, topPadding + 35, 22, 25),
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: WavePainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hey Mobina !',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Avatar(
                    initials: 'M',
                    color: AppColors.avatarSkin,
                    size: 48,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "Let's find your\nbest day!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// CARTE DE CATÉGORIE (style carte projet du design)
// ======================================================================
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.dark,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color foreground = dark ? Colors.white : AppColors.dark;

    return Container(
      width: 245,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dark ? AppColors.dark : AppColors.lightCard,
        borderRadius: BorderRadius.circular(38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.dark, size: 31),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dark ? Colors.white70 : AppColors.muted,
              fontSize: 17,
              height: 1.4,
            ),
          ),
          const Spacer(),
          if (dark)
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.dark,
                  size: 25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
