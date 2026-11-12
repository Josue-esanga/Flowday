import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/api_exception.dart';
import '../network/pkce.dart';
import '../network/supabase_auth_client.dart';

/// États de la session applicative.
enum AuthStatus {
  /// Session en cours de restauration (démarrage).
  unknown,

  /// Non connecté → écran de connexion / inscription.
  unauthenticated,

  /// Connecté → coque principale.
  authenticated,
}

/// État global de l'authentification (couche état, README §7).
///
/// Gère la session Supabase (GoTrue) : restauration au démarrage,
/// connexion, inscription, déconnexion et rafraîchissement des jetons.
/// Le jeton courant est exposé au client REST via [TokenSource] — en cas
/// d'expiration, le client demande un rafraîchissement puis réessaie la
/// requête ; si le rafraîchissement échoue, la session est fermée et
/// l'application revient à l'écran de connexion.
///
/// La persistance (jetons + e-mail) est **locale** (`shared_preferences`)
/// : aucun mot de passe n'est stocké. En environnement de test, la
/// persistance échoue silencieusement (plugin absent) — la session reste
/// alors en mémoire.
///
/// **Confirmation d'inscription par lien (PKCE)** : l'inscription envoie
/// un défi `s256` et conserve le vérificateur ; l'ouverture du lien
/// `flowday://login-callback?code=…` par [completeEmailConfirmation]
/// échange le code contre une session (voir `AuthDeepLinks`).
class AuthProvider extends ChangeNotifier implements TokenSource {
  AuthProvider({SupabaseAuthClient? client, this.persist = true})
    : _client = client ?? SupabaseAuthClient(),
      _status = AuthStatus.unknown;

  /// Session déjà établie, sans persistance — utilisé par les tests.
  AuthProvider.authenticated({
    this.email = 'demo@flowday.app',
    Map<String, dynamic>? metadata,
    SupabaseAuthClient? client,
  }) : _client = client ?? SupabaseAuthClient(),
       persist = false,
       _status = AuthStatus.authenticated {
    this.metadata = metadata ?? const {};
    _session = AuthSession(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      email: email ?? 'demo@flowday.app',
      metadata: this.metadata,
    );
  }

  /// Non connecté, sans persistance — écran de connexion (tests).
  AuthProvider.signedOut({SupabaseAuthClient? client})
    : _client = client ?? SupabaseAuthClient(),
      persist = false,
      _status = AuthStatus.unauthenticated;

  final SupabaseAuthClient _client;

  /// Persistance des jetons (locale) ; désactivée en environnement de test.
  final bool persist;

  AuthStatus _status;
  AuthSession? _session;

  /// Adresse e-mail du compte connecté.
  String? email;

  /// Métadonnées du compte (`full_name`, `avatar` en base64…).
  Map<String, dynamic> metadata = const {};

  /// Nom complet du compte (vide s'il n'a pas encore été renseigné).
  String get fullName => metadata['full_name']?.toString().trim() ?? '';

  /// Photo de profil en data-URL (`data:image/…;base64,…`), ou `null`.
  String? get avatar {
    final value = metadata['avatar'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Une opération (connexion/inscription) est en cours.
  bool busy = false;

  /// Vérificateur PKCE en attente du clic sur le lien de confirmation
  /// e-mail (conservé en mémoire **et** localement pour survivre à un
  /// redémarrage de l'app avant le clic).
  String? _pkceVerifier;

  /// Message transitoire à afficher (SnackBar) : confirmation d'adresse
  /// e-mail traitée, lien invalide… Consommé après affichage —
  /// voir `consumeNotice`.
  String? notice;

  AuthStatus get status => _status;

  @override
  String? get accessToken => _session?.accessToken;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------
  // Démarrage : restauration de la session locale
  // ---------------------------------------------------------------------
  Future<void> restoreSession() async {
    try {
      // Une session déjà ouverte (lien de confirmation traité pendant la
      // restauration) ne doit pas être écrasée.
      if (_status == AuthStatus.authenticated) return;
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString('fd.session.access');
      final refresh = prefs.getString('fd.session.refresh');
      final storedEmail = prefs.getString('fd.session.email');
      final storedMeta = prefs.getString('fd.session.meta');
      final expiresAtMs = prefs.getInt('fd.session.expires');
      if (access == null || refresh == null || storedEmail == null) {
        if (_status != AuthStatus.authenticated) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
        return;
      }
      metadata = _decodeMeta(storedMeta);
      final expiresAt = expiresAtMs == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(expiresAtMs);

      // Jeton encore valable (marge de 5 min) : utilisation directe.
      if (DateTime.now().isBefore(
        expiresAt.subtract(const Duration(minutes: 5)),
      )) {
        _session = AuthSession(
          accessToken: access,
          refreshToken: refresh,
          expiresAt: expiresAt,
          email: storedEmail,
        );
        email = storedEmail;
        _status = AuthStatus.authenticated;
      } else {
        // Jeton expiré : rafraîchissement immédiat, sinon reconnexion.
        try {
          final renewed = await _client.refresh(refresh);
          _session = _withEmail(renewed, storedEmail);
          email = storedEmail;
          _status = AuthStatus.authenticated;
          await _persistSession();
        } catch (_) {
          if (_status != AuthStatus.authenticated) {
            await _clearLocal();
            _status = AuthStatus.unauthenticated;
          }
        }
      }
    } catch (_) {
      // Plugin de stockage indisponible (tests) → connexion requise.
      if (_status != AuthStatus.authenticated) {
        _status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Connexion / inscription
  // ---------------------------------------------------------------------
  /// Connexion ; renvoie `null` en cas de succès, sinon un message
  /// utilisateur (aucun détail technique).
  Future<String?> signIn({required String email, required String password}) =>
      _runAuth(() async {
        final session = await _client.signIn(email: email, password: password);
        _session = _withEmail(session, email);
        this.email = email;
        metadata = session.metadata;
        if (metadata.isEmpty) {
          // La réponse n'a pas inclus `user` : on récupère le profil.
          try {
            metadata = await _client.fetchUser(session.accessToken);
          } catch (_) {
            // Profil non critique : la session reste valide.
          }
        }
        _status = AuthStatus.authenticated;
        await _persistSession();
      });

  /// Inscription ; renvoie `null` en cas de succès (session ouverte ou
  /// e-mail de confirmation envoyé — voir [confirmationSent]), sinon un
  /// message utilisateur.
  bool confirmationSent = false;

  Future<String?> signUp({
    required String email,
    required String password,
    String fullName = '',
  }) => _runAuth(() async {
    confirmationSent = false;
    // Flux PKCE : défi envoyé à GoTrue, vérificateur conservé jusqu'au
    // clic sur le lien de confirmation e-mail.
    final pkce = Pkce.generate();
    _pkceVerifier = pkce.verifier;
    await _persistPkce(pkce.verifier);
    final result = await _client.signUp(
      email: email,
      password: password,
      fullName: fullName,
      codeChallenge: pkce.challenge,
    );
    if (result.session != null) {
      // Session immédiate (confirmation désactivée) : aucun lien attendu.
      _session = _withEmail(result.session!, email);
      this.email = email;
      metadata = result.session!.metadata;
      _status = AuthStatus.authenticated;
      _pkceVerifier = null;
      await _clearPkce();
      await _persistSession();
    } else {
      confirmationSent = true;
      this.email = email;
    }
  });

  /// Termine la confirmation d'inscription **par lien** : échange le code
  /// reçu à l'ouverture de `flowday://login-callback?code=…` contre une
  /// session (GoTrue confirme alors l'adresse e-mail).
  ///
  /// Renvoie `null` en cas de succès (session ouverte — la coque
  /// principale prend le relais), sinon un message utilisateur
  /// professionnel et générique.
  Future<String?> completeEmailConfirmation(String code) async {
    final verifier = _pkceVerifier ?? await _loadPkce();
    if (verifier == null || verifier.isEmpty) {
      return 'Le lien de confirmation est invalide ou a expiré. '
          'Inscrivez-vous de nouveau pour recevoir un nouvel e-mail.';
    }
    _pkceVerifier = verifier;
    busy = true;
    notifyListeners();
    try {
      final session = await _client.exchangeCode(
        authCode: code,
        codeVerifier: verifier,
      );
      _session = _withEmail(session, email);
      email = _session!.email;
      metadata = session.metadata;
      if (metadata.isEmpty) {
        try {
          metadata = await _client.fetchUser(session.accessToken);
        } catch (_) {
          // Profil non critique : la session reste valide.
        }
      }
      _status = AuthStatus.authenticated;
      _pkceVerifier = null;
      await _clearPkce();
      await _persistSession();
      notice = 'Votre adresse e-mail est confirmée. Bienvenue !';
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 0 || e.statusCode >= 500) return e.message;
      // Code expiré, déjà utilisé ou vérificateur non reconnu.
      return 'Le lien de confirmation est invalide ou a expiré. '
          'Demandez un nouvel e-mail puis réessayez.';
    } catch (_) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion '
          'internet, puis réessayez.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Affiche un message transitoire (SnackBar) — voir [notice].
  void showNotice(String message) {
    notice = message;
    notifyListeners();
  }

  /// Efface le message transitoire après affichage (usage unique).
  void consumeNotice() {
    if (notice == null) return;
    notice = null;
    notifyListeners();
  }

  /// Réinitialisation du mot de passe (e-mail GoTrue) ; renvoie `null`
  /// quand l'e-mail a été (probablement) envoyé — un compte inconnu n'est
  /// jamais révélé — sinon un message utilisateur.
  Future<String?> recover({required String email}) async {
    try {
      await _client.recover(email: email);
      return null;
    } on ApiException catch (e) {
      // Réponse serveur (compte inconnu…) → message générique côté app.
      return e.statusCode == 0 ? e.message : null;
    } catch (_) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion '
          'internet, puis réessayez.';
    }
  }

  // ---------------------------------------------------------------------
  // Informations du compte (nom, photo, mot de passe)
  // ---------------------------------------------------------------------
  /// Met à jour les informations du compte : métadonnées (nom complet,
  /// photo de profil) et/ou mot de passe ; renvoie `null` en cas de
  /// succès, sinon un message utilisateur (aucun détail technique).
  Future<String?> updateProfile({
    Map<String, dynamic>? metadata,
    String? newPassword,
  }) async {
    if (_session == null) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }
    return _runAuth(() async {
      final session = _session!;
      // GoTrue remplace `user_metadata` : on envoie le dictionnaire
      // complet (existant + modifications).
      final merged = <String, dynamic>{...this.metadata, ...?metadata};
      final updated = await _client.updateUser(
        token: session.accessToken,
        data: merged.isEmpty ? null : merged,
        password: newPassword,
      );
      this.metadata = updated.isNotEmpty ? updated : merged;
      await _persistSession();
    });
  }

  /// Exécute une opération d'authentification : horodatage [busy],
  /// propagation des erreurs sous forme de message utilisateur.
  Future<String?> _runAuth(Future<void> Function() action) async {
    busy = true;
    confirmationSent = false;
    notice = null;
    notifyListeners();
    try {
      await action();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion '
          'internet, puis réessayez.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Déconnexion
  // ---------------------------------------------------------------------
  Future<void> signOut() async {
    final token = _session?.accessToken;
    final local = _session;
    _session = null;
    email = null;
    _status = AuthStatus.unauthenticated;
    confirmationSent = false;
    notice = null;
    _pkceVerifier = null;
    notifyListeners();
    await _clearLocal();
    await _clearPkce();
    if (token != null && local != null) {
      await _client.signOut(token); // best-effort
    }
  }

  // ---------------------------------------------------------------------
  // TokenSource — rafraîchissement piloté par le client REST (401)
  // ---------------------------------------------------------------------
  @override
  Future<bool> refreshSession() async {
    final refreshToken = _session?.refreshToken;
    if (refreshToken == null) return false;
    try {
      final renewed = await _client.refresh(refreshToken);
      _session = _withEmail(renewed, email);
      await _persistSession();
      notifyListeners();
      return true;
    } catch (_) {
      // Session morte : retour à l'écran de connexion.
      _session = null;
      email = null;
      _status = AuthStatus.unauthenticated;
      await _clearLocal();
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Internes
  // ---------------------------------------------------------------------
  AuthSession _withEmail(AuthSession session, String? fallback) => AuthSession(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    expiresAt: session.expiresAt,
    email: session.email.isNotEmpty ? session.email : (fallback ?? email ?? ''),
  );

  Future<void> _persistSession() async {
    if (!persist || _session == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fd.session.access', _session!.accessToken);
      await prefs.setString('fd.session.refresh', _session!.refreshToken);
      await prefs.setString('fd.session.email', _session!.email);
      await prefs.setString('fd.session.meta', jsonEncode(metadata));
      await prefs.setInt(
        'fd.session.expires',
        _session!.expiresAt.millisecondsSinceEpoch,
      );
    } catch (_) {
      // Stockage indisponible : la session reste en mémoire.
    }
  }

  Future<void> _clearLocal() async {
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fd.session.access');
      await prefs.remove('fd.session.refresh');
      await prefs.remove('fd.session.email');
      await prefs.remove('fd.session.meta');
      await prefs.remove('fd.session.expires');
    } catch (_) {
      // Rien à nettoyer.
    }
  }

  // Vérificateur PKCE : mémoire d'abord, localement ensuite (le clic
  // sur le lien d'e-mail peut survenir après un redémarrage de l'app).
  static const String _pkceStorageKey = 'fd.auth.pkce';

  Future<void> _persistPkce(String verifier) async {
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pkceStorageKey, verifier);
    } catch (_) {
      // Stockage indisponible : le vérificateur reste en mémoire.
    }
  }

  Future<String?> _loadPkce() async {
    if (!persist) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_pkceStorageKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearPkce() async {
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pkceStorageKey);
    } catch (_) {
      // Rien à nettoyer.
    }
  }

  /// Décode les métadonnées persistées (JSON → map), sûr en cas de
  /// valeur absente ou corrompue.
  static Map<String, dynamic> _decodeMeta(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
    } catch (_) {
      return const {};
    }
  }
}
