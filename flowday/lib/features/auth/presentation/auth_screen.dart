import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import 'auth_login_view.dart';
import 'auth_signup_view.dart';
import 'auth_widgets.dart';

/// Écran d'authentification — rendu de la maquette :
///
/// - fond clair `#F8F9FD` ;
/// - en-tête **anthracite organique** (continuité avec le dashboard) :
///   carte `AppColors.dark` à coins inférieurs arrondis, lignes d'ondes
///   fluides et typographie géométrique blanche affirmée ;
/// - bascule **connexion ⇄ inscription** par `AnimatedSwitcher`
///   (350 ms) via les liens du bas des écrans ;
/// - champs à **libellé flottant**, bouton primaire noir fléché,
///   séparateur « OU … AVEC » et boutons sociaux larges.
///
/// Affiché tant qu'aucune session n'est ouverte (voir `_AuthGate` dans
/// `app/app.dart`). Les erreurs restent professionnelles et en français ;
/// l'inscription réussie bascule sur la connexion avec un message
/// d'information (e-mail de confirmation). Les messages transitoires de
/// l'[AuthProvider] — confirmation d'adresse e-mail reçue par lien
/// profond, lien invalide… — s'affichent en SnackBar et sont consommés
/// après affichage.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  /// Écran courant : connexion (true) / inscription (false).
  bool _isLogin = true;

  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _auth.addListener(_onAuthChanged);
    // Un message peut précéder l'écran (lien de confirmation traité
    // pendant le splash) : on l'affiche dès la première frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onAuthChanged();
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Message transitoire de l'authentification → SnackBar (usage unique).
  void _onAuthChanged() {
    final message = _auth.notice;
    if (message == null || !mounted) return;
    _auth.consumeNotice();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(message),
        ),
      );
  }

  /// Inscription sans session : retour à la connexion + message.
  void _onConfirmationSent() {
    setState(() => _isLogin = true);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 6),
          content: Text(
            'Un e-mail de confirmation vient de vous être envoyé. '
            'Cliquez sur le lien, puis connectez-vous.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _isLogin
            ? LoginView(
                key: const ValueKey('login'),
                onSwitchToRegister: () => setState(() => _isLogin = false),
              )
            : SignUpView(
                key: const ValueKey('register'),
                onConfirmationSent: _onConfirmationSent,
                onSwitchToLogin: () => setState(() => _isLogin = true),
              ),
      ),
    );
  }
}
