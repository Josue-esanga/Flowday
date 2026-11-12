import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import 'auth_widgets.dart';

/// Vue **inscription** (maquette fournie) : en-tête noir full-bleed
/// « Créer un compte », champs à libellé flottant (nom / e-mail / mot de
/// passe), bouton primaire noir fléché, séparateur « OU S'INSCRIRE AVEC »,
/// boutons sociaux larges et lien vers la connexion.
///
/// Le nom est envoyé dans les métadonnées du compte Supabase
/// (`user_metadata.full_name`) ; sans session (confirmation par e-mail
/// requise), [onConfirmationSent] bascule sur la connexion avec un
/// message d'information.
class SignUpView extends StatefulWidget {
  const SignUpView({
    super.key,
    required this.onConfirmationSent,
    required this.onSwitchToLogin,
  });

  /// Inscription validée mais e-mail de confirmation à envoyer.
  final VoidCallback onConfirmationSent;

  /// Lien « Déjà un compte ? Se connecter ».
  final VoidCallback onSwitchToLogin;

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Affichage du mot de passe (œil).
  bool _obscurePassword = true;

  /// Message d'erreur affiché au-dessus du formulaire.
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le nom est obligatoire.';
    if (value.trim().length < 2) return 'Nom trop court.';
    return null;
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
    final password = value ?? '';
    if (password.isEmpty) return 'Le mot de passe est obligatoire.';
    if (password.length < 8) return '8 caractères minimum.';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    if (auth.busy) return;

    final message = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );
    if (!mounted) return;

    if (message != null) {
      setState(() => _error = message);
      return;
    }
    if (auth.confirmationSent) {
      // Sans session : on retourne sur la connexion avec le message d'info.
      widget.onConfirmationSent();
    }
    // Sinon : session ouverte → le sélecteur de session bascule seul.
  }

  void _socialUnavailable() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Inscription Google / Apple non disponible pour le moment.',
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
              subtitleBadge: 'Organisez votre quotidien',
              title: 'Créer un compte',
              description:
                  "Structurez vos tâches et gagnez en clarté dès aujourd'hui.",
            ),

            // ----------------------------------------------------------
            // Formulaire — largeur resserrée (gouttière 40, max 420)
            // ----------------------------------------------------------
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        AuthErrorBox(text: _error!),
                        const SizedBox(height: 18),
                      ],

                      // Nom complet.
                      FloatingInputField(
                        controller: _nameController,
                        labelText: 'Nom complet',
                        hintText: 'Alexandre Martin',
                        prefixIcon: Icons.person_outline_rounded,
                        enabled: !auth.busy,
                        keyboardType: TextInputType.name,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                      ),
                      const SizedBox(height: 18),

                      // E-mail.
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

                      // Mot de passe (œil de visibilité).
                      FloatingInputField(
                        controller: _passwordController,
                        labelText: 'Mot de passe',
                        hintText: 'Minimum 8 caractères',
                        prefixIcon: Icons.lock_outline_rounded,
                        enabled: !auth.busy,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
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
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bouton primaire noir (texte + flèche).
                      PrimaryFlowButton(
                        text: 'Créer mon compte',
                        busy: auth.busy,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 28),

                      // Séparateur « OU S'INSCRIRE AVEC ».
                      const DividerWithLabel(label: "OU S'INSCRIRE AVEC"),
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

                      // Lien vers la connexion (jamais de débordement).
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Déjà un compte ? ',
                              style: TextStyle(
                                color: AuthColors.label,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: auth.busy ? null : widget.onSwitchToLogin,
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Se connecter',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
