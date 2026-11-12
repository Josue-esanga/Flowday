import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/ui/states/error_state.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/category_meta.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/task_list_item.dart';
import '../../../shared/widgets/wave_painter.dart';

/// Accueil : en-tête sombre avec vagues, recherche dynamique (titres,
/// descriptions et noms de catégories), cartes de catégories cliquables
/// (F7 → page « tâches de la catégorie ») et tâches d'aujourd'hui /
/// d'hier (F1, triées par heure).
///
/// « See all » ouvre la timeline **sur la date de la section** (aujourd'hui
/// / hier), et le clic sur une tâche la coche / la décoche (F6).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onSeeAll,
    required this.onToggleTask,
    required this.onOpenCategory,
  });

  /// Ouvre la timeline sur la date indiquée (section « See all »).
  final ValueChanged<DateTime> onSeeAll;

  /// Coche / décoche la tâche cliquée (F6).
  final void Function(TaskItem task) onToggleTask;

  /// Ouvre la page « tâches de la catégorie » (flèche des cartes).
  final void Function(Category category) onOpenCategory;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Texte courant de la recherche.
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Recherche insensible à la casse sur titre et description.
  static bool _matches(TaskItem task, String query) =>
      task.title.toLowerCase().contains(query) ||
      task.description.toLowerCase().contains(query);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, state, _) {
        if (state.loading) {
          // Chargement « skeleton » : l'en-tête reste visible et le
          // contenu à venir est esquimmé (perception de démarrage rapide).
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const _DashboardHeader(),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 150, height: 15, radius: 8),
                    SizedBox(height: 16),
                    SkeletonTaskTile(),
                    SkeletonTaskTile(),
                    SkeletonTaskTile(),
                  ],
                ),
              ),
            ],
          );
        }
        if (state.error != null) {
          return ErrorState(message: state.error!, onRetry: state.retry);
        }

        // Filtre de recherche : appliqué en direct à l'affichage.
        final query = _query.trim().toLowerCase();
        final searching = query.isNotEmpty;
        final today = searching
            ? state.todayTasks.where((t) => _matches(t, query)).toList()
            : state.todayTasks;
        final yesterday = searching
            ? state.yesterdayTasks.where((t) => _matches(t, query)).toList()
            : state.yesterdayTasks;
        final categories = searching
            ? state.categories
                  .where((c) => c.name.toLowerCase().contains(query))
                  .toList()
            : state.categories;
        final noResults =
            searching &&
            categories.isEmpty &&
            today.isEmpty &&
            yesterday.isEmpty;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const _DashboardHeader(),

            // ------------------------------------------------------------
            // Recherche dynamique + bouton filtre / effacer
            // ------------------------------------------------------------
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
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        cursorColor: AppColors.dark,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: AppColors.placeholderText,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      // Pendant une recherche : bouton « effacer » (×),
                      // sinon le bouton de filtre du design.
                      onTap: searching ? _clearSearch : null,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.dark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          searching ? Icons.close : Icons.tune,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (noResults) ...[
              // ------------------------------------------------------------
              // Aucun résultat pour la recherche
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 40, 22, 60),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 46,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun résultat pour « ${_query.trim()} »',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ------------------------------------------------------------
              // Catégories (F7) : cartes horizontales, flèche → page de la
              // catégorie (carte entière cliquable)
              // ------------------------------------------------------------
              if (categories.isNotEmpty || !searching) ...[
                const SectionTitle(title: 'Categories', action: 'All'),
                const SizedBox(height: 18),
                if (categories.isEmpty)
                  const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'Aucune catégorie',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 295,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final info = categoryInfo[category.id];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == categories.length - 1 ? 0 : 14,
                          ),
                          child: _CategoryCard(
                            title: category.name,
                            description: info?.$1 ?? category.name,
                            icon: info?.$2 ?? Icons.label_outline,
                            dark: index == 0,
                            onTap: () => widget.onOpenCategory(category),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 25),
              ],

              // ------------------------------------------------------------
              // Tâches du jour (F1)
              // ------------------------------------------------------------
              if (today.isNotEmpty || !searching) ...[
                SectionTitle(
                  title: "Today's task",
                  action: 'See all',
                  onAction: () => widget.onSeeAll(DateTime.now()),
                ),
                const SizedBox(height: 15),
                if (today.isEmpty)
                  const _EmptyLine(text: 'Aucune tâche pour ce jour')
                else
                  for (final task in today)
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
                      // Clic sur la carte : coche / décoche la tâche (F6).
                      onTap: () => widget.onToggleTask(task),
                    ),
                const SizedBox(height: 20),
              ],

              // ------------------------------------------------------------
              // Tâches d'hier
              // ------------------------------------------------------------
              if (yesterday.isNotEmpty || !searching) ...[
                SectionTitle(
                  title: "Yesterday's task",
                  action: 'See all',
                  onAction: () => widget.onSeeAll(
                    DateTime.now().subtract(const Duration(days: 1)),
                  ),
                ),
                const SizedBox(height: 15),
                if (yesterday.isEmpty)
                  const _EmptyLine(text: 'Aucune tâche hier')
                else
                  for (final task in yesterday)
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
                      // Clic sur la carte : coche / décoche la tâche (F6).
                      onTap: () => widget.onToggleTask(task),
                    ),
                const SizedBox(height: 25),
              ],
            ],
          ],
        );
      },
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
    final firstName = _firstName(context.watch<AuthProvider>());

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
                  Expanded(
                    child: Text(
                      'Hey $firstName !',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Avatar(
                    initials: firstName.isEmpty
                        ? 'M'
                        : firstName[0].toUpperCase(),
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

  /// Prénom affiché : `full_name` du compte, à défaut « Mobina »
  /// (placeholder du design — aucune donnée réelle codée en dur).
  static String _firstName(AuthProvider auth) {
    final full = auth.fullName;
    if (full.isEmpty) return 'Mobina';
    final words = full.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.isEmpty ? 'Mobina' : words.first;
  }
}

// ======================================================================
// ÉTAT VIDE
// ======================================================================
class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.muted, fontSize: 14),
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
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool dark;

  /// Ouvre la page « tâches de la catégorie » (carte + flèche).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = dark ? Colors.white : AppColors.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
            // Flèche sur TOUTES les cartes (fond blanc sur carte sombre,
            // fond sombre sur carte claire).
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : AppColors.dark,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: dark ? AppColors.dark : Colors.white,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
