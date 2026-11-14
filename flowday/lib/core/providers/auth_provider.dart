import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../network/pkce.dart';
import '../network/supabase_auth_client.dart';
import '../network/supabase_storage_client.dart';

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
  AuthProvider({
    SupabaseAuthClient? client,
    SupabaseStorageClient? storage,
    this.persist = true,
  }) : _client = client ?? SupabaseAuthClient(),
       _storage = storage ?? SupabaseStorageClient(),
       _status = AuthStatus.unknown;

  /// Session déjà établie, sans persistance — utilisé par les tests.
  AuthProvider.authenticated({
    this.email = 'demo@flowday.app',
    Map<String, dynamic>? metadata,
    SupabaseAuthClient? client,
    SupabaseStorageClient? storage,
    String id = 'test-user',
  }) : _client = client ?? SupabaseAuthClient(),
       _storage = storage ?? SupabaseStorageClient(),
       persist = false,
       _status = AuthStatus.authenticated {
    this.metadata = metadata ?? const {};
    _acceptMetadata(this.metadata);
    _session = AuthSession(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      email: email ?? 'demo@flowday.app',
      metadata: this.metadata,
      id: id,
    );
  }

  /// Non connecté, sans persistance — écran de connexion (tests).
  AuthProvider.signedOut({
    SupabaseAuthClient? client,
    SupabaseStorageClient? storage,
  }) : _client = client ?? SupabaseAuthClient(),
       _storage = storage ?? SupabaseStorageClient(),
       persist = false,
       _status = AuthStatus.unauthenticated;

  final SupabaseAuthClient _client;

  /// Dépôt des photos de profil (Supabase Storage).
  final SupabaseStorageClient _storage;

  /// Persistance des jetons (locale) ; désactivée en environnement de test.
  final bool persist;

  AuthStatus _status;
  AuthSession? _session;

  /// Adresse e-mail du compte connecté.
  String? email;

  /// Métadonnées légères du compte (nom, `avatar` = URL publique…).
  Map<String, dynamic> metadata = const {};

  /// Photo de profil courante : URL Supabase Storage (cas normal) ou
  /// ancienne data-URL locale (comptes migrés, convertie à la connexion).
  String? _avatar;

  /// Une photo inline (data-URL) traîne encore dans les métadonnées
  /// distantes et doit en être retirée (jeton Supabase trop lourd).
  bool _needsAvatarCleanup = false;

  /// Nom complet du compte (vide s'il n'a pas encore été renseigné).
  String get fullName => metadata['full_name']?.toString().trim() ?? '';

  String get phone => metadata['phone']?.toString().trim() ?? '';

  String get location => metadata['location']?.toString().trim() ?? '';

  /// Photo de profil : URL publique Supabase Storage (ou data-URL legacy),
  /// `null` si le compte n'en a pas.
  String? get avatar => _avatar;

  /// Identifiant Supabase du compte (dossier Storage des photos).
  String? get userId {
    final id = _session?.id;
    return id == null || id.isEmpty ? null : id;
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
      final restoredMetadata = _decodeMeta(storedMeta);
      final storedId = prefs.getString('fd.session.user_id') ?? '';
      // La photo vient des métadonnées (URL Storage) ; les anciennes
      // photos locales en data-URL restent affichées jusqu'à leur envoi.
      _acceptMetadata(restoredMetadata);
      await _loadLocalAvatar(storedEmail);
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
          id: storedId,
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
        } on ApiException catch (e) {
          if (_isTransientAuthError(e)) {
            // Réseau indisponible / serveur momentanément en erreur :
            // on conserve la session locale. L'utilisateur reste connecté
            // et le prochain rafraîchissement réessaiera.
            _session = AuthSession(
              accessToken: access,
              refreshToken: refresh,
              expiresAt: expiresAt,
              email: storedEmail,
              id: storedId,
            );
            email = storedEmail;
            _status = AuthStatus.authenticated;
          } else if (_status != AuthStatus.authenticated) {
            await _clearLocal();
            _status = AuthStatus.unauthenticated;
          }
        } catch (_) {
          if (_status != AuthStatus.authenticated) {
            await _clearLocal();
            _status = AuthStatus.unauthenticated;
          }
        }
      }
      await _persistSession();
      unawaited(_syncRemoteAvatar());
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
        _resetProfileState();
        _session = _withEmail(session, email);
        this.email = email;
        await _loadLocalAvatar(email);
        _acceptMetadata(session.metadata);
        if (metadata.isEmpty) {
          // La réponse n'a pas inclus `user` : on récupère le profil.
          try {
            _acceptMetadata(await _client.fetchUser(session.accessToken));
          } catch (_) {
            // Profil non critique : la session reste valide.
          }
        }
        _status = AuthStatus.authenticated;
        await _persistSession();
        unawaited(_syncRemoteAvatar());
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
      _resetProfileState();
      _session = _withEmail(result.session!, email);
      this.email = email;
      await _loadLocalAvatar(email);
      _acceptMetadata(result.session!.metadata);
      _status = AuthStatus.authenticated;
      _pkceVerifier = null;
      await _clearPkce();
      await _persistSession();
      unawaited(_syncRemoteAvatar());
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
      return AppLocalizations.instance.t(
        'Le lien de confirmation est invalide ou a expiré. '
        'Inscrivez-vous de nouveau pour recevoir un nouvel e-mail.',
      );
    }
    _pkceVerifier = verifier;
    busy = true;
    notifyListeners();
    try {
      final session = await _client.exchangeCode(
        authCode: code,
        codeVerifier: verifier,
      );
      _resetProfileState();
      _session = _withEmail(session, email);
      email = _session!.email;
      await _loadLocalAvatar(email);
      _acceptMetadata(session.metadata);
      if (metadata.isEmpty) {
        try {
          _acceptMetadata(await _client.fetchUser(session.accessToken));
        } catch (_) {
          // Profil non critique : la session reste valide.
        }
      }
      _status = AuthStatus.authenticated;
      _pkceVerifier = null;
      await _clearPkce();
      await _persistSession();
      unawaited(_syncRemoteAvatar());
      notice = AppLocalizations.instance.t(
        'Votre adresse e-mail est confirmée. Bienvenue !',
      );
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 0 || e.statusCode >= 500) return e.message;
      // Code expiré, déjà utilisé ou vérificateur non reconnu.
      return AppLocalizations.instance.t(
        'Le lien de confirmation est invalide ou a expiré. Demandez un '
        'nouvel e-mail puis réessayez.',
      );
    } catch (_) {
      return AppLocalizations.instance.t(
        'Impossible de joindre le serveur. Vérifiez votre connexion '
        'internet, puis réessayez.',
      );
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
      return AppLocalizations.instance.t(
        'Impossible de joindre le serveur. Vérifiez votre connexion '
        'internet, puis réessayez.',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Informations du compte (nom, photo, mot de passe)
  // ---------------------------------------------------------------------
  /// Met à jour les informations du compte : métadonnées (nom complet,
  /// photo de profil) et/ou mot de passe ; renvoie `null` en cas de
  /// succès, sinon un message utilisateur (aucun détail technique).
  ///
  /// La photo choisie (data-URL) est d'abord **envoyée sur Supabase
  /// Storage** ; seule son URL publique rejoint les métadonnées du compte
  /// — la photo est donc retrouvée à chaque connexion, sur n'importe quel
  /// appareil.
  Future<String?> updateProfile({
    Map<String, dynamic>? metadata,
    String? newPassword,
  }) async {
    if (_session == null) {
      return AppLocalizations.instance.t(
        'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }
    return _runAuth(() async {
      final session = _session!;
      final changes = <String, dynamic>{...?metadata};
      if (changes.containsKey('avatar')) {
        final image = changes['avatar'];
        if (image is String && image.startsWith('data:')) {
          _avatar = await _uploadAvatar(session, image);
          changes['avatar'] = _avatar;
          _needsAvatarCleanup = false;
        } else if (image is String && image.trim().isNotEmpty) {
          // URL déjà distante (inchangée).
          _avatar = image;
          changes['avatar'] = image;
          _needsAvatarCleanup = false;
        } else {
          final previous = _avatar;
          _avatar = null;
          changes['avatar'] = null; // photo retirée
          if (previous != null && !previous.startsWith('data:')) {
            final path = _storage.pathFromUrl(previous);
            if (path != null) {
              await _storage.deleteAvatar(
                token: session.accessToken,
                path: path,
              );
            }
          }
        }
      }
      final merged = <String, dynamic>{...this.metadata, ...changes};
      final updated = await _client.updateUser(
        token: session.accessToken,
        data: merged.isEmpty ? null : merged,
        password: newPassword,
      );
      _acceptMetadata(updated.isNotEmpty ? updated : merged);
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
      return AppLocalizations.instance.t(
        'Impossible de joindre le serveur. Vérifiez votre connexion '
        'internet, puis réessayez.',
      );
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
    final accountEmail = _session?.email ?? email;
    _session = null;
    email = null;
    _resetProfileState();
    _status = AuthStatus.unauthenticated;
    confirmationSent = false;
    notice = null;
    _pkceVerifier = null;
    notifyListeners();
    await _clearLocal(accountEmail);
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
    } on ApiException catch (e) {
      if (_isTransientAuthError(e)) {
        // Panne réseau / serveur : ne pas déconnecter l'utilisateur.
        // La session reste en mémoire et sera retentée plus tard.
        return false;
      }
      // Jeton de rafraîchissement refusé : session réellement terminée.
      _session = null;
      email = null;
      _status = AuthStatus.unauthenticated;
      await _clearLocal();
      notifyListeners();
      return false;
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

  /// Vrai pour une erreur passagère qui ne doit pas fermer la session.
  static bool _isTransientAuthError(ApiException error) =>
      error.isNetwork || error.statusCode == 429 || error.statusCode >= 500;

  // ---------------------------------------------------------------------
  // Internes
  // ---------------------------------------------------------------------
  AuthSession _withEmail(AuthSession session, String? fallback) => AuthSession(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
    expiresAt: session.expiresAt,
    email: session.email.isNotEmpty ? session.email : (fallback ?? email ?? ''),
    id: session.id.isNotEmpty ? session.id : (_session?.id ?? ''),
  );

  /// Efface l'identité en mémoire (photo, nom…) : aucun reste du compte
  /// précédent ne doit apparaître au prochain connexion.
  void _resetProfileState() {
    metadata = const {};
    _avatar = null;
    _needsAvatarCleanup = false;
  }

  /// Applique les métadonnées reçues du serveur : la photo est une **URL
  /// publique** (Storage) ; une ancienne data-URL inline est conservée
  /// pour l'affichage mais retirée des métadonnées (JWT trop lourd).
  void _acceptMetadata(Map<String, dynamic> value) {
    final clean = Map<String, dynamic>.from(value);
    final remoteAvatar = clean['avatar'];
    if (remoteAvatar is String && remoteAvatar.trim().isNotEmpty) {
      _avatar = remoteAvatar;
      if (remoteAvatar.startsWith('data:')) {
        clean.remove('avatar');
        _needsAvatarCleanup = true;
      } else {
        _needsAvatarCleanup = false;
      }
    } else if (clean.containsKey('avatar')) {
      clean.remove('avatar');
      _avatar = null;
      _needsAvatarCleanup = false;
    }
    metadata = clean;
  }

  /// Ancienne photo locale (data-URL, versions précédentes) : lue une
  /// dernière fois pour ne pas la perdre, puis envoyée sur Storage par
  /// [_syncRemoteAvatar].
  Future<void> _loadLocalAvatar(String? accountEmail) async {
    if (_avatar != null || !persist || accountEmail == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy =
          prefs.getString(_avatarKey(accountEmail)) ??
          prefs.getString('fd.profile.avatar');
      if (legacy != null && legacy.isNotEmpty) _avatar = legacy;
    } catch (_) {
      // L'image est facultative ; le reste du profil reste disponible.
    }
  }

  String _avatarKey(String accountEmail) =>
      'fd.profile.avatar.${Uri.encodeComponent(accountEmail.toLowerCase())}';

  /// Envoie vers Supabase Storage une photo encore locale (data-URL) et
  /// nettoie les métadonnées distantes. Sans effet si la photo est déjà
  /// une URL publique.
  Future<void> _syncRemoteAvatar() async {
    final session = _session;
    if (session == null) return;
    final avatar = _avatar;

    if (avatar != null && avatar.startsWith('data:')) {
      try {
        final url = await _uploadAvatar(session, avatar);
        final merged = <String, dynamic>{...metadata, 'avatar': url};
        final updated = await _client.updateUser(
          token: session.accessToken,
          data: merged,
        );
        _acceptMetadata(updated.isNotEmpty ? updated : merged);
        _needsAvatarCleanup = false;
        await _refreshToken(session);
        await _persistSession();
        return;
      } catch (_) {
        // Hors ligne : la photo reste affichée ; nouvelle tentative à la
        // prochaine ouverture. Les métadonnées sont nettoyées ci-dessous.
      }
    }

    if (_needsAvatarCleanup) await _stripInlineAvatar(session);
  }

  /// Retire une ancienne photo inline des métadonnées distantes. Supabase
  /// inclut ces métadonnées dans le JWT : une image de 40 Ko produisait un
  /// jeton de 55 Ko que PostgREST rejetait avec HTTP 400.
  Future<void> _stripInlineAvatar(AuthSession session) async {
    try {
      await _client.updateUser(
        token: session.accessToken,
        data: const {'avatar': null},
      );
      _needsAvatarCleanup = false;
      metadata = Map<String, dynamic>.from(metadata)..remove('avatar');
      await _refreshToken(session);
    } catch (_) {
      // La connexion reste utilisable ; une prochaine ouverture ou
      // modification du profil retentera la migration.
    }
    await _persistSession();
  }

  /// Régénère le jeton pour qu'il ne contienne plus l'ancienne image.
  Future<void> _refreshToken(AuthSession session) async {
    try {
      final renewed = await _client.refresh(session.refreshToken);
      _session = _withEmail(
        renewed,
        session.email.isEmpty ? email : session.email,
      );
      if (renewed.metadata.isNotEmpty) _acceptMetadata(renewed.metadata);
    } catch (_) {
      // Le jeton sera régénéré au prochain renouvellement automatique.
    }
  }

  /// Envoie une image `data:…;base64,…` sur Supabase Storage et renvoie
  /// son URL publique.
  Future<String> _uploadAvatar(AuthSession session, String dataUrl) async {
    final match = RegExp(
      r'^data:([^;,]*);base64,(.*)$',
      dotAll: true,
    ).firstMatch(dataUrl);
    if (match == null) {
      throw ApiException(
        statusCode: 400,
        message: AppLocalizations.instance.t(
          "Cette photo n'est pas lisible. Choisissez-en une autre.",
        ),
      );
    }
    final mime = (match.group(1) ?? '').trim();
    final bytes = base64Decode(match.group(2)!);
    return _storage.uploadAvatar(
      token: session.accessToken,
      userId: _storageUserId(session),
      bytes: bytes,
      contentType: mime.isEmpty ? 'image/jpeg' : mime,
    );
  }

  /// Dossier Storage de l'utilisateur : identifiant Supabase, ou e-mail
  /// encodé pour les sessions restaurées d'avant cette version.
  String _storageUserId(AuthSession session) {
    if (session.id.isNotEmpty) return session.id;
    return Uri.encodeComponent(session.email.toLowerCase());
  }

  Future<void> _persistSession() async {
    if (!persist || _session == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fd.session.access', _session!.accessToken);
      await prefs.setString('fd.session.refresh', _session!.refreshToken);
      await prefs.setString('fd.session.email', _session!.email);
      await prefs.setString('fd.session.user_id', _session!.id);
      await prefs.setString('fd.session.meta', jsonEncode(metadata));
      // Seules les anciennes photos inline restent en cache local ; une
      // photo envoyée sur Storage n'est plus dupliquée sur l'appareil.
      final avatar = _avatar;
      if (avatar == null || !avatar.startsWith('data:')) {
        await prefs.remove(_avatarKey(_session!.email));
      } else {
        await prefs.setString(_avatarKey(_session!.email), avatar);
        await prefs.remove('fd.profile.avatar');
      }
      await prefs.setInt(
        'fd.session.expires',
        _session!.expiresAt.millisecondsSinceEpoch,
      );
    } catch (_) {
      // Stockage indisponible : la session reste en mémoire.
    }
  }

  Future<void> _clearLocal([String? accountEmail]) async {
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fd.session.access');
      await prefs.remove('fd.session.refresh');
      await prefs.remove('fd.session.email');
      await prefs.remove('fd.session.user_id');
      await prefs.remove('fd.session.meta');
      final target = accountEmail ?? _session?.email ?? email;
      if (target != null) await prefs.remove(_avatarKey(target));
      _avatar = null;
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
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
