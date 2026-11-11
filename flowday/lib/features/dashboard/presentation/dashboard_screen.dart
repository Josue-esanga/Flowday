import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/data/mock_data.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/task_card.dart';

/// Accueil (« Hello Mobina! ») : en-tête, recherche, catégories,
/// tâches d'aujourd'hui et d'hier — maquette 2.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onSeeAll});

  /// Ouvre la timeline « Today's task ».
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        110,
      ),
      children: [
        const _Header(),
        const SizedBox(height: 22),
        const _SearchBar(),
        const SizedBox(height: 26),
        const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        const _CategoryChips(),
        const SizedBox(height: 26),
        _SectionHeader(title: "Today's task", onSeeAll: onSeeAll),
        const SizedBox(height: 14),
        for (final task in MockData.todayTasks) ...[
          TaskCard(task: task),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 12),
        _SectionHeader(title: "Yesterday's task", onSeeAll: onSeeAll),
        const SizedBox(height: 14),
        for (final task in MockData.yesterdayTasks) ...[
          TaskCard(task: task),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Avatar + salutation + date.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.surfaceStrong,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 28,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello Mobina!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Fri, Jun 28',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Champ de recherche + bouton loupe.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.search,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }
}

/// Rangée horizontale de chips de catégories.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < MockData.categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _CategoryChip(category: MockData.categories[i]),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Titre de section + lien « See all ».
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              'See all',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
