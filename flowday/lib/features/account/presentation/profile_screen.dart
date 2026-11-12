import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/ui/confirm_sign_out.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/skeleton.dart';
import 'profile_edit_sheet.dart';

/// Profil (README §3.5) : identité du compte connecté (nom, e-mail,
/// photo de profil), statistiques chargées depuis l'API (`GET
/// /api/stats/`) et actions : modifier le profil, exporter les tâches,
/// déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final auth = context.watch<AuthProvider>();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 110),
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 26),

        // Identité (compte réel — photo ou initiales).
        Center(
          child: Column(
            children: [
              _ProfileAvatar(radius: 44),
              const SizedBox(height: 14),
              Text(
                _displayName(auth),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.email ?? '—',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Statistiques de productivité (API).
        Consumer<TasksProvider>(
          builder: (context, state, _) {
            final stats = state.stats;
            if (stats == null && state.loading) {
              // Cartes de statistiques en skeleton.
              return const Row(
                children: [
                  Expanded(child: SkeletonStatCard()),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonStatCard()),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonStatCard()),
                ],
              );
            }
            if (stats == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 36,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error ?? 'Statistiques indisponibles.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: state.retry,
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(color: AppColors.dark),
                      ),
                    ),
                  ],
                ),
              );
            }
            final rate = stats.successRate;
            final rateLabel = rate == rate.roundToDouble()
                ? '${rate.round()}%'
                : '${rate.toStringAsFixed(1)}%';
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '${stats.completedTasks}',
                    label: 'Tâches terminées',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(value: rateLabel, label: 'Taux de réussite'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: '${stats.tasksThisWeek}',
                    label: 'Cette semaine',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Actions.
        Container(
          decoration: BoxDecoration(
            color: AppColors.itemBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _ProfileLink(
                icon: Icons.edit_outlined,
                label: 'Modifier le profil',
                onTap: () => _editProfile(context),
              ),
              const Divider(color: AppColors.divider, height: 1),
              _ProfileLink(
                icon: Icons.download_outlined,
                label: 'Exporter mes tâches',
                onTap: () => _exportTasks(context),
              ),
              const Divider(color: AppColors.divider, height: 1),
              _ProfileLink(
                icon: Icons.logout,
                label: 'Déconnexion',
                danger: true,
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Nom affiché : `full_name` du compte, à défaut la partie locale de
  /// l'e-mail (aucune donnée codée en dur).
  static String _displayName(AuthProvider auth) {
    if (auth.fullName.isNotEmpty) return auth.fullName;
    final email = auth.email ?? '';
    final local = email.split('@').first;
    return local.isEmpty ? 'Votre profil' : local;
  }

  /// Ouvre la feuille d'édition puis confirme l'enregistrement.
  Future<void> _editProfile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showProfileEditSheet(context);
    if (!saved || !context.mounted) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Profil mis à jour.'),
        ),
      );
  }

  /// Exporte toutes les tâches en JSON dans le presse-papiers.
  void _exportTasks(BuildContext context) {
    final provider = context.read<TasksProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Fusion + dédoublonnage par identifiant (aujourd'hui / hier / jour).
    final byId = <String, TaskItem>{
      for (final task in [
        ...provider.todayTasks,
        ...provider.yesterdayTasks,
        ...provider.dayTasks,
      ])
        task.id: task,
    };
    final payload = jsonEncode({
      'exported_at': DateTime.now().toIso8601String(),
      'count': byId.length,
      'tasks': byId.values
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'date': t.date,
              'time': t.time,
              'category': t.category.name,
              'completed': t.completed,
            },
          )
          .toList(),
    });

    Clipboard.setData(ClipboardData(text: payload));
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            byId.isEmpty
                ? 'Aucune tâche à exporter.'
                : '${byId.length} tâche(s) copiée(s) dans le presse-papiers '
                      '(JSON).',
          ),
        ),
      );
  }

  /// Déconnexion avec confirmation (le sélecteur de session bascule sur
  /// l'écran de connexion).
  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmSignOut(context)) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().signOut();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Vous êtes déconnecté.'),
        ),
      );
  }
}

// ======================================================================
// AVATAR (photo de profil ou initiales)
// ======================================================================

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lightCard,
      backgroundImage: _decodeAvatar(auth.avatar),
      child: _decodeAvatar(auth.avatar) == null
          ? Text(
              _initials(auth),
              style: TextStyle(
                color: AppColors.dark,
                fontSize: radius * 0.68,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }

  /// Data-URL (`data:image/…;base64,…`) → image ; `null` si absente ou
  /// illisible.
  static ImageProvider? _decodeAvatar(String? dataUrl) {
    if (dataUrl == null) return null;
    try {
      final comma = dataUrl.indexOf(',');
      final base64Part = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
      final Uint8List bytes = base64Decode(base64Part);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _initials(AuthProvider auth) {
    final source = auth.fullName.isNotEmpty
        ? auth.fullName
        : (auth.email ?? '');
    final words = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first[0].toUpperCase();
    if (words.length < 2) return first;
    return '$first${words[1][0].toUpperCase()}';
  }
}

// ======================================================================
// COMPOSANTS
// ======================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.personal : AppColors.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: danger ? color : AppColors.muted),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: danger ? color : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
