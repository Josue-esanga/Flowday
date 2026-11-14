import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/services/task_reminder_service.dart';
import '../../../shared/widgets/sheet_action_surface.dart';
import '../../../shared/widgets/theme_mode_switch.dart';

/// Paramètres : thème, notifications, langue et informations du compte.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = TaskReminderService.instance.isEnabled;
  bool _changingNotifications = false;

  Future<void> _setNotifications(bool value) async {
    if (_changingNotifications) return;
    setState(() => _changingNotifications = true);
    final enabled = await TaskReminderService.instance.setEnabled(value);
    if (!mounted) return;
    setState(() {
      _changingNotifications = false;
      if (enabled) _notifications = value;
    });
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Autorisez les notifications dans les réglages du téléphone.',
            ),
          ),
        ),
      );
      return;
    }
    if (value) await context.read<TasksProvider>().syncReminders();
  }

  /// Sélecteur compact du rappel par défaut : des puces pour les délais
  /// courants et une ligne « personnaliser » — pas de longue liste.
  Future<void> _chooseDefaultReminder() async {
    final reminderService = TaskReminderService.instance;
    const presets = [0, 5, 10, 15, 30, 60, 24 * 60];
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;
        final current = reminderService.defaultReminderMinutes;
        final isCustom = !presets.contains(current);

        // `heightFactor: 1` : la feuille prend la hauteur de son contenu
        // (un `Center` seul l'étirait sur tout l'écran).
        return Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 22,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('Rappel par défaut'),
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.t('Quand souhaitez-vous être rappelé ?'),
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: 0.62),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final minutes in presets)
                        _ReminderChoice(
                          label: l10n.reminderChipLabel(minutes),
                          selected: current == minutes,
                          onTap: () => Navigator.pop(sheetContext, minutes),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: theme.dividerColor),
                  const SizedBox(height: 10),
                  SheetActionSurface(
                    selected: isCustom,
                    child: InkWell(
                      onTap: () async {
                        final minutes = await _showCustomReminderDialog(
                          sheetContext,
                        );
                        if (minutes != null && sheetContext.mounted) {
                          Navigator.pop(sheetContext, minutes);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t('Personnaliser le délai'),
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isCustom) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.reminderDelay(current),
                                      style: TextStyle(
                                        color: colors.onSurface.withValues(
                                          alpha: 0.62,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isCustom)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: colors.primary,
                              )
                            else
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: colors.onSurface.withValues(alpha: 0.65),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    await reminderService.setDefaultReminderMinutes(selected);
    if (!mounted) return;
    setState(() {});
    await context.read<TasksProvider>().syncReminders();
  }

  Future<int?> _showCustomReminderDialog(BuildContext context) async {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    final l10n = AppLocalizations.of(context);
    String? error;
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: Text(l10n.t('Délai personnalisé')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.t('Choisissez combien de temps avant la tâche.')),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.t('Heures'),
                        hintText: '0',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.t('Minutes'),
                        hintText: '0',
                      ),
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.t('Retour')),
            ),
            FilledButton(
              onPressed: () {
                final hours = int.tryParse(hoursController.text) ?? 0;
                final minutes = int.tryParse(minutesController.text) ?? 0;
                final total = hours * 60 + minutes;
                if (hours < 0 || minutes < 0 || minutes > 59 || total > 10080) {
                  setDialogState(
                    () => error = l10n.t(
                      'Maximum : 7 jours. Vérifiez les valeurs.',
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, total);
              },
              child: Text(l10n.t('Enregistrer')),
            ),
          ],
        ),
      ),
    );
    hoursController.dispose();
    minutesController.dispose();
    return selected;
  }

  /// Choix de la langue : feuille compacte à deux options.
  Future<void> _chooseLanguage() async {
    final localeProvider = context.read<LocaleProvider>();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final theme = Theme.of(sheetContext);
        return Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('Choisir la langue'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('La langue s’applique à toute l’application.'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.62,
                      ),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final option in const [
                    ('fr', 'Français'),
                    ('en', 'English'),
                  ])
                    SheetActionSurface(
                      margin: const EdgeInsets.only(bottom: 8),
                      selected: localeProvider.locale.languageCode == option.$1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          option.$2,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing:
                            localeProvider.locale.languageCode == option.$1
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                                size: 22,
                              )
                            : null,
                        onTap: () => Navigator.pop(sheetContext, option.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;
    await localeProvider.setLanguageCode(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final auth = context.watch<AuthProvider>();
    final appearance = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 110),
      children: [
        // Titre principal (même échelle que les autres écrans).
        Text(
          l10n.t('Paramètres'),
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle(l10n.t('Apparence')),
        _SettingsCard(
          children: [
            _ThemeModeRow(
              icon: Icons.dark_mode_outlined,
              label: l10n.t('Thème sombre'),
              isDark: appearance.isDark,
              onChanged: context.read<ThemeProvider>().setDarkMode,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle(l10n.t('Notifications')),
        _SettingsCard(
          children: [
            _SwitchRow(
              icon: Icons.notifications_outlined,
              label: l10n.t('Activer les rappels'),
              value: _notifications,
              onChanged: _changingNotifications ? null : _setNotifications,
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            _LinkRow(
              icon: Icons.schedule,
              label: l10n.t('Rappel par défaut'),
              value: l10n.reminderDelay(
                TaskReminderService.instance.defaultReminderMinutes,
              ),
              onTap: _chooseDefaultReminder,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle(l10n.t('Langue')),
        _SettingsCard(
          children: [
            _LinkRow(
              icon: Icons.translate,
              label: l10n.t('Langue de l’application'),
              value: locale.languageName,
              onTap: _chooseLanguage,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle(l10n.t('Compte')),
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
                          l10n.t('Connecté en tant que'),
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
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle(l10n.t('À propos')),
        _SettingsCard(
          children: const [
            _LinkRow(
              icon: Icons.info_outline,
              label: 'Flowday',
              value: 'v1.0.0',
            ),
          ],
        ),
      ],
    );
  }
}

/// Puce de délai du sélecteur de rappel (compacte, une seule ligne).
class _ReminderChoice extends StatelessWidget {
  const _ReminderChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SheetActionSurface(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: colors.onSurface),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
  final ValueChanged<bool>? onChanged;

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

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ThemeModeSwitch(isDark: isDark, onChanged: onChanged),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
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
      ),
    );
  }
}
