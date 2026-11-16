import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/tasks_provider.dart';

/// Bandeau discret affiché en haut de la coque quand l'application
/// travaille **hors ligne** (F8) : les données viennent du cache local et
/// les modifications seront synchronisées au retour du réseau.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.pending,
    required this.onRetry,
    this.busy = false,
  });

  /// Nombre de modifications en attente de synchronisation.
  final int pending;

  /// Relance la synchronisation (et le chargement) des données.
  final VoidCallback onRetry;

  /// Vrai pendant une tentative : le bouton est remplacé par un indicateur
  /// (un seul « Réessayer » à la fois).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF23262F) : AppColors.lightCard;
    final foreground = dark ? const Color(0xFFC9CEDB) : const Color(0xFF5B5E6B);

    final l10n = AppLocalizations.of(context);
    final label = pending > 0
        ? l10n.offlinePending(pending)
        : l10n.t('Hors ligne — données enregistrées sur cet appareil.');

    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 16, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: foreground,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.tr('Réessayer'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enveloppe le contenu de la coque : insère le [OfflineBanner] au-dessus
/// quand les données proviennent du cache local, et neutralise la marge de
/// la barre d'état pour les écrans qui la gèrent eux-mêmes (évite un
/// double espacement sous le bandeau).
class OfflineBannerHost extends StatelessWidget {
  const OfflineBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Selector<TasksProvider, bool>(
      selector: (_, tasks) => tasks.isOffline,
      builder: (context, offline, child) => Column(
        children: [
          if (offline) const _OfflineBannerSlot(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: offline,
              child: child!,
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Bandeau alimenté par le provider (nombre de modifications en attente).
class _OfflineBannerSlot extends StatefulWidget {
  const _OfflineBannerSlot();

  @override
  State<_OfflineBannerSlot> createState() => _OfflineBannerSlotState();
}

class _OfflineBannerSlotState extends State<_OfflineBannerSlot> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await context.read<TasksProvider>().retrySync();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<TasksProvider, int>(
      selector: (_, tasks) => tasks.pendingWrites,
      builder: (context, pending, _) => OfflineBanner(
        pending: pending,
        busy: _retrying,
        onRetry: _retry,
      ),
    );
  }
}
