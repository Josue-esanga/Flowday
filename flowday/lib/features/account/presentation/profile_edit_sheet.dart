import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

/// Sélecteur de photo injectable (permet de tester la feuille sans
/// plateforme native) ; défaut = galerie compressée.
typedef ProfileImagePicker = Future<String?> Function();

/// Choix d'une photo dans la galerie, réduite à 512 px et convertie en
/// data-URL (`data:image/…;base64,…`) stockée dans `user_metadata`.
Future<String?> pickProfileImage() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 80,
  );
  if (picked == null) return null; // Annulé par l'utilisateur.
  final bytes = await picked.readAsBytes();
  final isPng = picked.path.toLowerCase().endsWith('.png');
  final mime = isPng ? 'image/png' : 'image/jpeg';
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

/// Ouvre la feuille « Modifier le profil » ; `true` = enregistré.
/// [pickImage] permet d'injecter un sélecteur (tests).
Future<bool> showProfileEditSheet(
  BuildContext context, {
  ProfileImagePicker? pickImage,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ProfileEditSheet(pickImage: pickImage),
  );
  return saved ?? false;
}

/// Feuille d'édition des informations du compte :
/// nom complet, photo de profil et (optionnel) nouveau mot de passe.
class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({super.key, this.pickImage});

  /// Sélecteur de photo (tests) ; galerie par défaut.
  final ProfileImagePicker? pickImage;

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;

  /// Data-URL de la photo courante (existante ou fraîchement choisie).
  String? _avatar;

  /// La photo a été changée / retirée dans cette session.
  bool _avatarTouched = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _name = TextEditingController(text: auth.fullName);
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
    _avatar = auth.avatar;
  }

  @override
  void dispose() {
    _name.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final pick = widget.pickImage ?? pickProfileImage;
    final dataUrl = await pick();
    if (dataUrl == null || !mounted) return; // Annulation.
    setState(() {
      _avatar = dataUrl;
      _avatarTouched = true;
    });
  }

  void _removePhoto() {
    setState(() {
      _avatar = null;
      _avatarTouched = true;
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Le nom est obligatoire.');
      return;
    }
    final newPassword = _newPassword.text;
    if (newPassword.isNotEmpty && newPassword.length < 8) {
      setState(() => _error = '8 caractères minimum pour le mot de passe.');
      return;
    }
    if (newPassword != _confirmPassword.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.busy) return;

    final patch = <String, dynamic>{'full_name': name};
    if (_avatarTouched) patch['avatar'] = _avatar; // null = retirée.

    final message = await auth.updateProfile(
      metadata: patch,
      newPassword: newPassword.isEmpty ? null : newPassword,
    );
    if (!mounted) return;
    if (message != null) {
      setState(() => _error = message);
      return;
    }
    Navigator.pop(context, true);
  }

  ImageProvider? _avatarImage() {
    final dataUrl = _avatar;
    if (dataUrl == null) return null;
    try {
      final comma = dataUrl.indexOf(',');
      final base64Part = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
      return MemoryImage(base64Decode(base64Part));
    } catch (_) {
      return null; // Donnée illisible → initiales.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final image = _avatarImage();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée de la feuille.
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modifier le profil',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: auth.busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Aperçu de la photo.
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.lightCard,
                backgroundImage: image,
                child: image == null
                    ? Text(
                        _initials(auth),
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: auth.busy ? null : _choosePhoto,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(
                      _avatar == null ? 'Choisir une photo' : 'Changer',
                    ),
                  ),
                  if (_avatar != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: auth.busy ? null : _removePhoto,
                      child: const Text(
                        'Retirer',
                        style: TextStyle(
                          color: AppColors.personal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.personal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.personal.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Nom complet.
            const _FieldLabel('Nom complet'),
            _SheetField(
              controller: _name,
              enabled: !auth.busy,
              keyboardType: TextInputType.name,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            // Mot de passe (optionnel).
            const _FieldLabel('Nouveau mot de passe (optionnel)'),
            _SheetField(
              controller: _newPassword,
              enabled: !auth.busy,
              obscureText: true,
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Confirmer le mot de passe'),
            _SheetField(
              controller: _confirmPassword,
              enabled: !auth.busy,
              obscureText: true,
              icon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 22),

            // Enregistrement.
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.dark.withValues(
                    alpha: 0.5,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: auth.busy ? null : _save,
                child: auth.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Enregistrer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(AuthProvider auth) {
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.icon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onFieldSubmitted,
        style: const TextStyle(color: AppColors.text, fontSize: 14.5),
        decoration: InputDecoration(
          hintText: '—',
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.black54, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
