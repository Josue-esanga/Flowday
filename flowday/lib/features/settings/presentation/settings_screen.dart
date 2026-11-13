import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/ui/confirm_sign_out.dart';

/// Paramètres (README §3.4) : thème, notifications, langue, à propos.
/// Design statique au style clair, les interrupteurs ne pilotent rien.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final auth = context.watch<AuthProvider>();
    final appearance = context.watch<ThemeProvider>();
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 110),
      children: [
        // Titre principal (même échelle que les autres écrans).
        Text(
          'Paramètres',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('Apparence'),
        _SettingsCard(
          children: [
            _SwitchRow(
              icon: Icons.dark_mode_outlined,
              label: 'Thème sombre',
              value: appearance.isDark,
              onChanged: context.read<ThemeProvider>().setDarkMode,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Notifications'),
        _SettingsCard(
          children: [
            _SwitchRow(
              icon: Icons.notifications_outlined,
              label: 'Activer les rappels',
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            const _LinkRow(
              icon: Icons.schedule,
              label: 'Rappel par défaut',
              value: '10 min avant',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Langue'),
        _SettingsCard(
          children: const [
            _LinkRow(icon: Icons.translate, label: 'Langue', value: 'Français'),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Compte'),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 22,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connecté en tant que',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          auth.email ?? '—',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            InkWell(
              onTap: auth.busy ? null : () => _signOut(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 22, color: AppColors.personal),
                    SizedBox(width: 12),
                    Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: AppColors.personal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('À propos'),
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
              label: 'Cahier des charges',
              value: 'MVP',
            ),
          ],
        ),
      ],
    );
  }

  /// Déconnexion avec confirmation → le sélecteur de session bascule sur
  /// l'écran de connexion.
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.cardColor
            : AppColors.itemBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}
