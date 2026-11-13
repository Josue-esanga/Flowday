import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Dialogue de confirmation « Se déconnecter ? » ; renvoie `true` si
/// l'utilisateur confirme, `false` s'il annule.
///
/// Design épuré : la **croix** en haut à droite tient lieu de bouton
/// « Annuler » et un **seul bouton** « Se déconnecter » pleine largeur
/// (flex) termine l'action — ni barre d'actions encombrée, ni double
/// bouton.
Future<bool> confirmSignOut(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 4, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Se déconnecter ?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // La croix remplace le bouton « Annuler ».
          IconButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            icon: const Icon(Icons.close, size: 22, color: AppColors.muted),
            tooltip: 'Fermer',
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vos données restent enregistrées sur votre compte : vous pourrez '
            'vous reconnecter à tout moment.',
            style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 24),
          // Bouton unique pleine largeur (flex).
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.personal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Se déconnecter',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
