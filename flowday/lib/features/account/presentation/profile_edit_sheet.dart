import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/avatar.dart';

/// Sélecteur de photo injectable (permet de tester la feuille sans
/// plateforme native) ; défaut = galerie compressée.
typedef ProfileImagePicker = Future<String?> Function();

/// Choix d'une photo dans la galerie, réduite à 512 px. L'image revient en
/// data-URL et sera **envoyée sur Supabase Storage** à l'enregistrement
/// (seule son URL publique est conservée dans le profil).
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
  final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (_) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: ProfileEditSheet(pickImage: pickImage),
    ),
  );
  return saved ?? false;
}

/// Feuille d'édition du nom, du téléphone, de la localisation et de la photo.
class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({super.key, this.pickImage});

  /// Sélecteur de photo (tests) ; galerie par défaut.
  final ProfileImagePicker? pickImage;

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;

  /// Data-URL de la photo courante (existante ou fraîchement choisie).
  String? _avatar;

  /// La photo a été changée / retirée dans cette session.
  bool _avatarTouched = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final firstName = auth.metadata['first_name']?.toString().trim() ?? '';
    final lastName = auth.metadata['last_name']?.toString().trim() ?? '';
    final nameParts = auth.fullName.split(RegExp(r'\s+'));
    _firstName = TextEditingController(
      text: firstName.isNotEmpty
          ? firstName
          : (nameParts.isEmpty ? '' : nameParts.first),
    );
    _lastName = TextEditingController(
      text: lastName.isNotEmpty
          ? lastName
          : (nameParts.length > 1 ? nameParts.skip(1).join(' ') : ''),
    );
    _email = TextEditingController(text: auth.email ?? '');
    _avatar = auth.avatar;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
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
    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      setState(
        () => _error = context.tr('Le prénom et le nom sont obligatoires.'),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.busy) return;

    final patch = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'full_name': '$firstName $lastName',
    };
    if (_avatarTouched) patch['avatar'] = _avatar; // null = retirée.

    final message = await auth.updateProfile(metadata: patch);
    if (!mounted) return;
    if (message != null) {
      setState(() => _error = message);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final sheetButtonColor = isDark ? theme.cardColor : Colors.white;
    final sheetBorderColor = isDark ? theme.dividerColor : AppColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('Modifier le profil'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.t('Mettez à jour vos coordonnées personnelles'),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.62,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('Fermer'),
                    onPressed: auth.busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: sheetButtonColor,
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: sheetBorderColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.t('Photo de profil'),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          child: Avatar(
                            initials: _initials(auth),
                            color: AppColors.avatarSkin,
                            size: 90,
                            image: _avatar,
                          ),
                        ),
                        Material(
                          color: sheetButtonColor,
                          elevation: 1,
                          shape: CircleBorder(
                            side: BorderSide(color: sheetBorderColor),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: auth.busy ? null : _choosePhoto,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 17,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: auth.busy ? null : _choosePhoto,
                      style: TextButton.styleFrom(
                        backgroundColor: sheetButtonColor,
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: sheetBorderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _avatar == null
                            ? l10n.t('Ajouter une photo')
                            : l10n.t('Changer la photo'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_avatar != null)
                      TextButton(
                        onPressed: auth.busy ? null : _removePhoto,
                        style: TextButton.styleFrom(
                          backgroundColor: sheetButtonColor,
                          foregroundColor: AppColors.personal,
                          side: BorderSide(color: sheetBorderColor),
                        ),
                        child: Text(l10n.t('Retirer la photo')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.t('Informations personnelles'),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.personal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.personal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _buildField(
                label: l10n.t('Prénom'),
                controller: _firstName,
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 14),
              _buildField(
                label: l10n.t('Nom'),
                controller: _lastName,
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 14),
              _buildField(
                label: l10n.t('Adresse e-mail'),
                controller: _email,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sheetButtonColor,
                    foregroundColor: theme.colorScheme.onSurface,
                    disabledBackgroundColor: sheetButtonColor,
                    disabledForegroundColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    side: BorderSide(color: sheetBorderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: auth.busy ? null : _save,
                  label: auth.busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : Text(
                          l10n.t('Enregistrer les modifications'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  icon: auth.busy
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check, size: 20),
                ),
              ),
            ],
          ),
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _SheetField(
          controller: controller,
          icon: icon,
          enabled: enabled && !context.read<AuthProvider>().busy,
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.icon,
    required this.enabled,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14.5),
        decoration: InputDecoration(
          hintText: '—',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            size: 20,
          ),
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
