import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Bloc de chargement « skeleton » : **balayage lumineux continu** à la
/// TikTok (une bande claire traverse le bloc de gauche à droite), qui
/// remplace les ronds d'attente — le contenu à venir est esquissé
/// immédiatement, ce qui donne une perception de démarrage plus rapide.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 10});

  /// Largeur ; `double.infinity` pour remplir la largeur disponible.
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF2A2A31) : const Color(0xFFE9E9EE);
    final highlight = dark ? const Color(0xFF3D3D47) : const Color(0xFFFCFCFE);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Bande de lumière : part hors du bloc à gauche, le traverse, puis
        // sort à droite — le cycle est continu (aucune pause visible).
        final shift = _controller.value * 2.4 - 1.2;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(shift - 0.7, -0.5),
              end: Alignment(shift + 0.7, 0.5),
              colors: [base, highlight, base],
              stops: const [0.15, 0.5, 0.85],
            ),
          ),
        );
      },
    );
  }
}

// ======================================================================
// COMPOSITIONS PRÊTES À L'EMPLOI
// ======================================================================

/// Carte de tâche en skeleton, fidèle à la forme de `TaskListItem`
/// (accueil) : case carrée, deux lignes de texte, heure à droite.
class SkeletonTaskTile extends StatelessWidget {
  const SkeletonTaskTile({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: dark ? Theme.of(context).cardColor : AppColors.itemBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Skeleton(width: 30, height: 30, radius: 8),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: double.infinity, height: 12, radius: 6),
                SizedBox(height: 8),
                Skeleton(width: 110, height: 10, radius: 5),
              ],
            ),
          ),
          SizedBox(width: 12),
          Skeleton(width: 32, height: 12, radius: 6),
        ],
      ),
    );
  }
}

/// Carte de la timeline en skeleton : point + cadre arrondi sombre, avec
/// les mêmes lignes que la carte réelle (titre, description, action).
class SkeletonTimelineCard extends StatelessWidget {
  const SkeletonTimelineCard({super.key, this.emphasis = false});

  /// Première carte : un peu plus grande, comme la tâche mise en avant.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Skeleton(width: 17, height: 17, radius: 9),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? Theme.of(context).cardColor : AppColors.itemBg,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(
                    width: emphasis ? 200 : 150,
                    height: emphasis ? 18 : 14,
                    radius: 9,
                  ),
                  const SizedBox(height: 12),
                  const Skeleton(width: double.infinity, height: 11, radius: 6),
                  const SizedBox(height: 8),
                  const Skeleton(width: 150, height: 11, radius: 6),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Skeleton(width: 43, height: 43, radius: 12),
                      Spacer(),
                      Skeleton(width: 56, height: 11, radius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de statistique en skeleton (forme de `_StatCard` du profil).
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeleton(height: 96, radius: 26);
  }
}

/// Liste de squelettes de cartes de tâches (accueil, catégories).
class SkeletonTaskList extends StatelessWidget {
  const SkeletonTaskList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const Skeleton(width: 140, height: 15, radius: 8),
        const SizedBox(height: 16),
        for (int i = 0; i < itemCount; i++) const SkeletonTaskTile(),
      ],
    );
  }
}

/// Liste de squelettes de la timeline (cartouches sombres).
class SkeletonTimelineList extends StatelessWidget {
  const SkeletonTimelineList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const Skeleton(width: 140, height: 15, radius: 8),
        const SizedBox(height: 16),
        for (int i = 0; i < itemCount; i++)
          SkeletonTimelineCard(emphasis: i == 0),
      ],
    );
  }
}
