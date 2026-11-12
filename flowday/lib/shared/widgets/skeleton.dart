import 'package:flutter/material.dart';

/// Bloc de chargement « skeleton » : masque défilant (shimmer) qui
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
  static const _base = Color(0xFFE9E9ED);
  static const _light = Color(0xFFF8F8FB);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final stops = <double>[
          (t - 0.45).clamp(0.0, 1.0),
          t,
          (t + 0.45).clamp(0.0, 1.0),
        ];
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            colors: [_base, _light, _base],
            stops: stops,
          ).createShader(rect),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _base,
              borderRadius: BorderRadius.circular(widget.radius),
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

/// Ligne de tâche en skeleton (pastille + deux barres), fidèle à la
/// forme de `TaskListItem`.
class SkeletonTaskTile extends StatelessWidget {
  const SkeletonTaskTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 44, height: 44, radius: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: double.infinity, height: 14, radius: 7),
                SizedBox(height: 9),
                Skeleton(width: 120, height: 10, radius: 5),
              ],
            ),
          ),
          SizedBox(width: 12),
          Skeleton(width: 46, height: 20, radius: 10),
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

/// Liste de squelettes de tâches (ex. : chargement d'un écran de liste).
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
