import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
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
        final theme = Theme.of(context);
        final l10n = context.l10n;
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
                  .where(
                    (c) => categoryDisplayName(
                      context,
                      c,
                    ).toLowerCase().contains(query),
                  )
                  .toList()
            : state.categories;
        final noResults =
            searching &&
            categories.isEmpty &&
            today.isEmpty &&
            yesterday.isEmpty;

        return RefreshIndicator(
          onRefresh: state.loadInitial,
          color: AppColors.contrast(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              const _DashboardHeader(),

              // ------------------------------------------------------------
              // Recherche dynamique + bouton filtre / effacer
              // ------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? theme.cardColor
                        : AppColors.field,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                        size: 26,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          cursorColor: theme.colorScheme.primary,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 17,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: l10n.t('Rechercher'),
                            hintStyle: const TextStyle(
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
                            color: AppColors.contrast(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            searching ? Icons.close : Icons.tune,
                            color: AppColors.onContrast(context),
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
                        l10n.searchNoResults(_query.trim()),
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
                  SectionTitle(title: l10n.t('Catégories')),
                  const SizedBox(height: 18),
                  if (categories.isEmpty)
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          l10n.t('Aucune catégorie'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
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
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == categories.length - 1 ? 0 : 14,
                            ),
                            child: _CategoryCard(
                              title: categoryDisplayName(context, category),
                              description: categoryDisplayDescription(
                                context,
                                category,
                              ),
                              icon: categoryIcon(category.id),
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
                    title: l10n.t('Tâche du jour'),
                    action: l10n.t('Tout voir'),
                    onAction: () => widget.onSeeAll(DateTime.now()),
                  ),
                  const SizedBox(height: 15),
                  if (today.isEmpty)
                    _EmptyLine(text: l10n.t('Aucune tâche pour ce jour'))
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
                        onToggle: () => widget.onToggleTask(task),
                      ),
                  const SizedBox(height: 20),
                ],

                // ------------------------------------------------------------
                // Tâches d'hier
                // ------------------------------------------------------------
                if (yesterday.isNotEmpty || !searching) ...[
                  SectionTitle(
                    title: l10n.t('Tâche d’hier'),
                    action: l10n.t('Tout voir'),
                    onAction: () => widget.onSeeAll(
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (yesterday.isEmpty)
                    _EmptyLine(text: l10n.t('Aucune tâche hier'))
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
                        onToggle: () => widget.onToggleTask(task),
                      ),
                  const SizedBox(height: 25),
                ],
              ],
            ],
          ),
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
    final auth = context.watch<AuthProvider>();
    final firstName = _firstName(auth);
    final l10n = context.l10n;
    final onHeader = AppColors.onContrast(context);

    return Container(
      height: 225 + topPadding,
      padding: EdgeInsets.fromLTRB(22, topPadding + 35, 22, 25),
      decoration: BoxDecoration(
        color: AppColors.contrast(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: WavePainter(color: onHeader)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.greeting(firstName),
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        color: onHeader.withValues(alpha: 0.7),
                        fontSize: 21,
                      ),
                    ),
                  ),
                  // Photo de profil dynamique (initiales à défaut).
                  Avatar(
                    initials: firstName.isEmpty
                        ? 'M'
                        : firstName[0].toUpperCase(),
                    color: AppColors.avatarSkin,
                    size: 56,
                    image: auth.avatar,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                l10n.t('Trouvons\nvotre meilleure journée !'),
                style: TextStyle(
                  color: onHeader,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - 48).clamp(220.0, 320.0).toDouble();
    final compact = cardWidth < 260;
    // Cartes « contrastées » : anthracite en clair, blanches en sombre.
    final Color foreground = dark
        ? (isDark ? AppColors.text : Colors.white)
        : theme.colorScheme.onSurface;
    final Color muted = dark
        ? (isDark ? AppColors.text.withValues(alpha: 0.62) : Colors.white70)
        : theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final Color accentBg = dark
        ? (isDark ? AppColors.text : Colors.white)
        : AppColors.dark;
    final Color accentFg = dark
        ? (isDark ? Colors.white : AppColors.dark)
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.all(compact ? 17 : 22),
        decoration: BoxDecoration(
          color: dark
              ? (isDark ? Colors.white : AppColors.dark)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(38),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 50 : 58,
              height: compact ? 50 : 58,
              decoration: BoxDecoration(
                color: accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentFg, size: compact ? 27 : 31),
            ),
            SizedBox(height: compact ? 14 : 20),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: compact ? 17 : 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: compact ? 10 : 16),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted,
                fontSize: compact ? 14 : 16,
                height: 1.4,
              ),
            ),
            const Spacer(),
            // Flèche sur TOUTES les cartes (pastille contrastée).
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: accentBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: accentFg,
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
