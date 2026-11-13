import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/ui/confirm_sign_out.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/wave_painter.dart';
import 'profile_edit_sheet.dart';

/// Profil (README §3.5) : identité du compte connecté (nom, e-mail,
/// photo de profil), statistiques chargées depuis l'API (`GET
/// /api/stats/`) et actions : modifier le profil, exporter les tâches,
/// déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final auth = context.watch<AuthProvider>();

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF8F8FC),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 18),
        children: [
          _ProfileTopArea(
            topPadding: topPadding,
            auth: auth,
            name: _displayName(auth),
            onEdit: () => _editProfile(context),
          ),
          Consumer<TasksProvider>(
            builder: (context, state, _) => _ProfileStatistics(
              stats: state.stats,
              loading: state.loading,
              error: state.error,
              onRetry: state.retry,
            ),
          ),
          _PersonalInformationCard(
            name: _displayName(auth),
            email: auth.email ?? '—',
            onEdit: () => _editProfile(context),
          ),
          _ProfileSettingsCard(
            onOpenSettings: onOpenSettings,
            onExport: () => _exportTasks(context),
          ),
          _LogoutButton(onTap: () => _signOut(context)),
          const SizedBox(height: 14),
        ],
      ),
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
    return Avatar(
      initials: _initials(auth),
      color: AppColors.avatarSkin,
      size: radius * 2,
      image: auth.avatar,
    );
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

class _ProfileTopArea extends StatelessWidget {
  const _ProfileTopArea({
    required this.topPadding,
    required this.auth,
    required this.name,
    required this.onEdit,
  });

  final double topPadding;
  final AuthProvider auth;
  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final headerHeight = topPadding + 220;
    return SizedBox(
      height: topPadding + 337,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: ClipPath(
              clipper: _ProfileHeaderClipper(),
              child: ColoredBox(
                color: AppColors.dark,
                child: const CustomPaint(painter: WavePainter()),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 22,
            left: 24,
            child: const Text(
              'Profil',
              style: TextStyle(
                fontFamily: 'DancingScript',
                fontVariations: [FontVariation('wght', 700)],
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: topPadding + 91,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _ProfileAvatar(radius: 60),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: onEdit,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.edit,
                          color: AppColors.dark,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 220,
            left: 22,
            right: 22,
            child: Column(
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        auth.email ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 1.08,
        size.width * 0.5,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.58,
        0,
        size.height * 0.9,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ProfileStatistics extends StatelessWidget {
  const _ProfileStatistics({
    required this.stats,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final ProfileStats? stats;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (stats == null && loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Row(
          children: [
            Expanded(child: SkeletonStatCard()),
            SizedBox(width: 10),
            Expanded(child: SkeletonStatCard()),
            SizedBox(width: 10),
            Expanded(child: SkeletonStatCard()),
          ],
        ),
      );
    }
    if (stats == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        padding: const EdgeInsets.all(18),
        decoration: _profileCardDecoration(context),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error ?? 'Statistiques indisponibles.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final rate = stats!.successRate;
    final rateLabel = rate == rate.roundToDouble()
        ? '${rate.round()}%'
        : '${rate.toStringAsFixed(1)}%';
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      padding: const EdgeInsets.symmetric(vertical: 19),
      decoration: _profileCardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: _ProfileStatItem(
              icon: Icons.task_alt_rounded,
              value: '${stats!.completedTasks}',
              label: 'Terminées',
            ),
          ),
          const _ProfileVerticalDivider(),
          Expanded(
            child: _ProfileStatItem(
              icon: Icons.star_border_rounded,
              value: rateLabel,
              label: 'Réussite',
            ),
          ),
          const _ProfileVerticalDivider(),
          Expanded(
            child: _ProfileStatItem(
              icon: Icons.bar_chart_rounded,
              value: '${stats!.tasksThisWeek}',
              label: 'Cette semaine',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 21, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _ProfileVerticalDivider extends StatelessWidget {
  const _ProfileVerticalDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 66, color: const Color(0xFFE7E8ED));
}

class _PersonalInformationCard extends StatelessWidget {
  const _PersonalInformationCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      padding: const EdgeInsets.all(20),
      decoration: _profileCardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.onSurface,
                size: 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Informations personnelles',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Modifier'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _ProfileInfoRow(
            icon: Icons.badge_outlined,
            label: 'Nom complet',
            value: name,
          ),
          const SizedBox(height: 12),
          _ProfileInfoRow(
            icon: Icons.mail_outline,
            label: 'Adresse e-mail',
            value: email,
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 12),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSettingsCard extends StatelessWidget {
  const _ProfileSettingsCard({
    required this.onOpenSettings,
    required this.onExport,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: _profileCardDecoration(context),
      child: Column(
        children: [
          if (onOpenSettings != null) ...[
            _ProfileActionTile(
              icon: Icons.settings_outlined,
              title: 'Paramètres',
              subtitle: 'Notifications, apparence et langue',
              onTap: onOpenSettings!,
            ),
            const Divider(height: 1, indent: 58, color: AppColors.divider),
          ],
          _ProfileActionTile(
            icon: Icons.download_outlined,
            title: 'Exporter mes tâches',
            subtitle: 'Copier une sauvegarde au format JSON',
            onTap: onExport,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.dark, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 19),
        label: const Text('Se déconnecter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

BoxDecoration _profileCardDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).cardColor
      : Colors.white,
  borderRadius: BorderRadius.circular(30),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 22,
      offset: const Offset(0, 7),
    ),
  ],
);
