import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import 'auth_widgets.dart';

/// Vue **connexion** (maquette fournie) : en-tête noir full-bleed avec la
/// marque « Flowday » en cursive, champs à libellé flottant, bouton
/// primaire noir fléché, mot de passe oublié (e-mail GoTrue), séparateur
/// « OU CONTINUER AVEC », boutons sociaux larges et lien d'inscription.
class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.onSwitchToRegister});

  /// Lien « Pas encore de compte ? S'inscrire ».
  final VoidCallback onSwitchToRegister;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Affichage du mot de passe (œil).
  bool _obscurePassword = true;

  /// Message d'erreur affiché au-dessus du formulaire.
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'L’adresse e-mail est obligatoire.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    if (auth.busy) return;

    final message = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (message != null) setState(() => _error = message);
    // Sinon : session ouverte → le sélecteur de session bascule seul.
  }

  /// Mot de passe oublié : saisie de l'adresse puis e-mail GoTrue de
  /// réinitialisation (aucune fuite d'existence de compte).
  Future<void> _forgotPassword() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Mot de passe oublié ?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: FloatingInputField(
            controller: controller,
            labelText: 'Adresse email',
            hintText: 'alexandre@exemple.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AuthColors.ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Envoyer le lien'),
          ),
        ],
      ),
    );
    // `controller` vit le temps de la route de dialogue (exit animation).

    if (email == null || !mounted) return;
    final message = await context.read<AuthProvider>().recover(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message ??
                'Si un compte existe avec cette adresse, un e-mail de '
                    'réinitialisation vient de vous être envoyé.',
          ),
        ),
      );
  }

  void _socialUnavailable() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Connexion Google / Apple non disponible pour le moment.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ----------------------------------------------------------
            // En-tête noir full-bleed (marque cursive + accroche)
            // ----------------------------------------------------------
            const FlowdayHeader(
              subtitleBadge: 'Prêt pour une journée productive ?',
              title: 'Se connecter',
              description:
                  'Retrouvez vos listes et atteignez vos objectifs du jour.',
            ),

            // ----------------------------------------------------------
            // Formulaire — pleine largeur (gouttière 24)
            // ----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AuthErrorBox(text: _error!),
                    const SizedBox(height: 18),
                  ],

                  // Champ e-mail.
                  FloatingInputField(
                    controller: _emailController,
                    labelText: 'Adresse email',
                    hintText: 'alexandre@exemple.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    enabled: !auth.busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 18),

                  // Champ mot de passe (œil de visibilité).
                  FloatingInputField(
                    controller: _passwordController,
                    labelText: 'Mot de passe',
                    hintText: '••••••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    enabled: !auth.busy,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AuthColors.label,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),

                  // Mot de passe oublié (aligné à droite).
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: auth.busy ? null : _forgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AuthColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bouton primaire noir (texte + flèche).
                  PrimaryFlowButton(
                    text: 'Se connecter',
                    busy: auth.busy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 28),

                  // Séparateur « OU CONTINUER AVEC ».
                  const DividerWithLabel(label: 'OU CONTINUER AVEC'),
                  const SizedBox(height: 24),

                  // Boutons sociaux Google / Apple.
                  Row(
                    children: [
                      Expanded(
                        child: SocialAuthButton(
                          label: 'Google',
                          isGoogle: true,
                          onTap: _socialUnavailable,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SocialAuthButton(
                          label: 'Apple',
                          isGoogle: false,
                          onTap: _socialUnavailable,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Lien vers l'inscription (jamais de débordement).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Pas encore de compte ? ',
                          style: TextStyle(
                            color: AuthColors.label,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: auth.busy ? null : widget.onSwitchToRegister,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "S'inscrire",
                              style: TextStyle(
                                color: AuthColors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
