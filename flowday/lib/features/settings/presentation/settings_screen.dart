import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Paramètres (README §3.4) : thème, notifications, langue, à propos.
/// Design statique, les interrupteurs ne pilotent rien encore.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkTheme = true;
  bool _notifications = true;

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
          'Paramètres',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle('Apparence'),
        _SettingsCard(
          children: [
            _SwitchRow(
              icon: Icons.dark_mode_outlined,
              label: 'Thème sombre',
              value: _darkTheme,
              onChanged: (v) => setState(() => _darkTheme = v),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle('Notifications'),
        _SettingsCard(
          children: [
            _SwitchRow(
              icon: Icons.notifications_outlined,
              label: 'Activer les rappels',
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            const Divider(color: AppColors.divider, height: 1),
            const _LinkRow(
              icon: Icons.schedule,
              label: 'Rappel par défaut',
              value: '10 min avant',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle('Langue'),
        _SettingsCard(
          children: const [
            _LinkRow(
              icon: Icons.translate,
              label: 'Langue',
              value: 'Français',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle('À propos'),
        _SettingsCard(
          children: const [
            _LinkRow(
              icon: Icons.info_outline,
              label: 'Flowday',
              value: 'v1.0.0',
            ),
            Divider(color: AppColors.divider, height: 1),
            _LinkRow(
              icon: Icons.description_outlined,
              label: "Cahier des charges",
              value: 'MVP',
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accent,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.surfaceStrong,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
