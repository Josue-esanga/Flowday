import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Profil (README §3.5) : informations utilisateur et statistiques.
/// Écran minimal pour le MVP — design statique.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        20,
        110,
      ),
      children: [
        const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 26),

        // Identité.
        const Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.surfaceStrong,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Mobina',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'mobina@flowday.app',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Statistiques de productivité.
        Row(
          children: const [
            Expanded(
              child: _StatCard(value: '12', label: 'Tâches terminées'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '85%', label: 'Taux de réussite'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '30', label: 'Cette semaine'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Actions.
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              _ProfileLink(
                icon: Icons.edit_outlined,
                label: 'Modifier le profil',
              ),
              Divider(color: AppColors.divider, height: 1),
              _ProfileLink(
                icon: Icons.download_outlined,
                label: 'Exporter mes tâches',
              ),
              Divider(color: AppColors.divider, height: 1),
              _ProfileLink(
                icon: Icons.logout,
                label: 'Déconnexion',
                danger: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
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
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.personal : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: danger ? color : AppColors.textSecondary),
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
            color: danger ? color : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
