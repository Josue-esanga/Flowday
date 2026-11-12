import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Dialogue de confirmation « Se déconnecter ? » ; renvoie `true` si
/// l'utilisateur confirme, `false` s'il annule.
Future<bool> confirmSignOut(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Se déconnecter ?',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Vos données restent enregistrées sur votre compte : vous pourrez '
        'vous reconnecter à tout moment.',
        style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text(
            'Annuler',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.personal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );
  return result ?? false;
}
