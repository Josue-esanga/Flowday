import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'auth_provider.dart';

/// Liens profonds d'authentification : `flowday://login-callback?code=…`
///
/// Après clic sur le lien de confirmation e-mail, GoTrue confirme
/// l'adresse puis **redirige vers le deep link de l'app** avec un code
/// PKCE. Ce gestionnaire échange le code contre une session
/// ([AuthProvider.completeEmailConfirmation]) : l'application
/// s'ouvre directement connectée, sans jamais repasser par une page web.
///
/// - **Démarrage à froid** : le lien a lancé l'app — lu via
///   `getInitialLink()` une fois la restauration de session terminée
///   (paramètre [ready] de [attach]) pour ne jamais écraser la session
///   fraîchement ouverte ;
/// - **App déjà ouverte** : le lien arrive sur `uriLinkStream`.
///
/// Environnement de test (plugin absent) : l'écoute échoue silencieusement
/// — l'authentification classique reste utilisable.
class AuthDeepLinks {
  AuthDeepLinks._(this._auth, this._ready);

  final AuthProvider _auth;

  /// Restauration de la session à terminer avant d'échanger le lien.
  final Future<void> _ready;

  StreamSubscription<Uri>? _subscription;

  /// Code déjà traité (le lien initial peut être livré deux fois).
  String? _handledCode;

  /// Écoute les liens d'ouverture ; libéré par [dispose].
  static AuthDeepLinks attach(AuthProvider auth, {Future<void>? ready}) {
    final handler = AuthDeepLinks._(auth, ready ?? Future<void>.value());
    try {
      final links = AppLinks();
      handler._subscription = links.uriLinkStream.listen(
        handler._handle,
        onError: (Object e) => debugPrint('Flowday lien profond ignoré : $e'),
      );
      unawaited(
        links
            .getInitialLink()
            .then((uri) async {
              if (uri != null) await handler._handle(uri);
            })
            .catchError((Object e) {
              debugPrint('Flowday lien initial ignoré : $e');
            }),
      );
    } catch (e) {
      debugPrint('Flowday liens profonds indisponibles : $e');
    }
    return handler;
  }

  /// Traite une URL entrante : n'importe quel autre lien est ignoré.
  Future<void> _handle(Uri uri) async {
    try {
      if (uri.scheme != 'flowday' || uri.host != 'login-callback') return;
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) return;
      if (code == _handledCode || _auth.isAuthenticated) return;
      _handledCode = code;

      // Lien initial : attendre la fin de la restauration locale.
      await _ready;
      final error = await _auth.completeEmailConfirmation(code);
      if (error != null) _auth.showNotice(error);
    } catch (e) {
      // Jamais d'erreur remontée : l'écran de connexion reste utilisable.
      debugPrint('Flowday confirmation par lien : $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
