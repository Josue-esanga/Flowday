import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';
import 'supabase_config.dart';

/// Session Supabase (jetons GoTrue) : jeton d'accès (1 h), jeton de
/// rafraîchissement, adresse e-mail du compte et métadonnées
/// (`user_metadata` : nom complet, photo de profil…).
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.email,
    this.metadata = const {},
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String email;

  /// Métadonnées du compte (`full_name`, `avatar` en base64…).
  final Map<String, dynamic> metadata;

  factory AuthSession.fromJson(
    Map<String, dynamic> json, {
    required String email,
    Map<String, dynamic>? metadata,
  }) {
    final seconds = (json['expires_in'] as num?)?.toInt() ?? 3600;
    // Réponses GoTrue : `user.user_metadata` (login / signup / GET user).
    final user = json['user'];
    final meta =
        metadata ??
        (user is Map && user['user_metadata'] is Map
            ? Map<String, dynamic>.from(user['user_metadata'] as Map)
            : <String, dynamic>{});
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
      email: email,
      metadata: meta,
    );
  }
}

/// Résultat d'une inscription : soit une session immédiate, soit la
/// confirmation par e-mail reste à faire.
class AuthSignupResult {
  const AuthSignupResult({this.session, this.confirmationSent = false});

  final AuthSession? session;

  /// Un e-mail de confirmation a été envoyé (à valider avant connexion).
  final bool confirmationSent;
}

/// Source de jetons utilisée par le client REST (`SupabaseRestClient`)
/// pour joindre les requêtes et rafraîchir la session sur un 401.
abstract class TokenSource {
  /// Jeton d'accès courant, ou `null` si non connecté.
  String? get accessToken;

  /// Rafraîchit la session ; `false` = plus de session valide.
  Future<bool> refreshSession();
}

/// Client d'authentification Supabase (GoTrue) en **accès direct** :
/// inscription, connexion, déconnexion et rafraîchissement, sans serveur
/// intermédiaire.
///
/// Endpoints (`/auth/v1`) :
/// - `POST signup`               → session immédiate ou e-mail de confirmation
/// - `POST token?grant_type=password`   → session
/// - `POST token?grant_type=refresh_token` → session renouvelée
/// - `POST logout` (jeton porté) → 204, en best-effort
///
/// Les messages d'erreur renvoyés sont **professionnels et génériques**
/// (FR) : le détail brut du serveur part uniquement en console.
class SupabaseAuthClient {
  SupabaseAuthClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  Uri _endpoint(String path, {Map<String, String>? query}) =>
      Uri.parse('${SupabaseConfig.projectUrl}/auth/v1/$path')
          .replace(queryParameters: query);

  Map<String, String> get _headers => {
    'apikey': SupabaseConfig.anonKey,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// POST JSON → corps décodé ; lève une `ApiException` sur erreur HTTP.
  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic> body = const {},
    String? bearer,
  }) => _send('POST', path, query: query, body: body, bearer: bearer);

  /// Requête JSON (POST / PUT / GET) → corps décodé ; lève une
  /// `ApiException` sur erreur HTTP.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? bearer,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw const ApiException(
        statusCode: 0,
        message: 'Application non configurée. Contactez le support.',
      );
    }

    try {
      final headers = Map<String, String>.from(_headers);
      if (bearer != null) headers['Authorization'] = 'Bearer $bearer';
      final uri = _endpoint(path, query: query);
      final encoded = body == null ? null : jsonEncode(body);
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encoded != null) request.body = encoded;
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (response.statusCode >= 400) {
        debugPrint(
          'Flowday auth $path → HTTP ${response.statusCode}: ${response.body}',
        );
        throw ApiException(
          statusCode: response.statusCode,
          message: _errorMessage(response.statusCode, map),
        );
      }
      return map;
    } on TimeoutException {
      throw const ApiException(statusCode: 0, message: _networkMessage);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(statusCode: 0, message: _networkMessage);
    }
  }

  static const String _networkMessage =
      'Impossible de joindre le serveur. Vérifiez votre connexion internet, '
      'puis réessayez.';

  /// Message d'authentification **professionnel** (aucune fuite
  /// d'information sur l'infrastructure).
  static String _errorMessage(int status, Map<String, dynamic> body) {
    final code = body['error_code']?.toString() ?? '';
    final msg = body['msg']?.toString() ?? '';
    if (status == 429) {
      return 'Trop de tentatives. Réessayez dans quelques instants.';
    }
    if (code == 'invalid_credentials' || msg.contains('Invalid login')) {
      return 'Adresse e-mail ou mot de passe incorrect.';
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return "Veuillez confirmer votre adresse e-mail avant de vous "
          'connecter (vérifiez votre boîte mail).';
    }
    if (code == 'user_already_exists' ||
        msg.contains('already been registered')) {
      return 'Un compte existe déjà avec cette adresse e-mail.';
    }
    if (code == 'weak_password' || msg.contains('weak')) {
      return 'Mot de passe trop faible : 8 caractères minimum.';
    }
    if (status == 401 || status == 403) {
      return 'Identifiants incorrects ou accès refusé.';
    }
    if (status >= 500) {
      return 'Le service rencontre un problème. Réessayez plus tard.';
    }
    return 'Une erreur est survenue. Réessayez plus tard.';
  }

  /// Inscription (e-mail + mot de passe), le nom complet part dans les
  /// métadonnées du compte (`user_metadata.full_name`).
  ///
  /// Selon la configuration du projet, renvoie une session directement ou
  /// signale qu'un e-mail de confirmation doit être validé.
  ///
  /// En flux **PKCE**, [codeChallenge] (défi `s256`) accompagne la
  /// demande et `redirect_to` indique le deep link de l'app : le lien de
  /// confirmation ouvrira l'application avec un code à échanger via
  /// [exchangeCode].
  Future<AuthSignupResult> signUp({
    required String email,
    required String password,
    String fullName = '',
    String? codeChallenge,
  }) async {
    final data = await _post(
      'signup',
      query: {'redirect_to': SupabaseConfig.emailRedirectUri},
      body: {
        'email': email,
        'password': password,
        if (fullName.trim().isNotEmpty) 'data': {'full_name': fullName.trim()},
        if (codeChallenge != null) ...{
          'code_challenge': codeChallenge,
          'code_challenge_method': 's256',
        },
      },
    );
    if (data['access_token'] is String) {
      return AuthSignupResult(
        session: AuthSession.fromJson(data, email: email),
      );
    }
    // L'utilisateur existe mais la confirmation par e-mail est requise.
    if (data['id'] is String || data['user'] is Map) {
      return const AuthSignupResult(confirmationSent: true);
    }
    throw const ApiException(
      statusCode: 400,
      message: "Le compte n'a pas pu être créé. Réessayez plus tard.",
    );
  }

  /// Réinitialisation de mot de passe : envoie l'e-mail GoTrue associé.
  /// Un compte inconnu n'est jamais révélé (toute réponse serveur autre
  /// qu'un problème réseau est traitée comme « e-mail envoyé »).
  Future<void> recover({required String email}) async {
    await _post('recover', body: {'email': email});
  }

  /// Échange d'un **code d'autorisation PKCE** (reçu à l'ouverture du
  /// lien de confirmation e-mail) contre une session complète.
  ///
  /// `POST token?grant_type=pkce` avec `auth_code` + `code_verifier`
  /// (RFC 7636) — GoTrue valide le couple défi/vérificateur envoyé à
  /// l'inscription, confirme l'adresse e-mail et renvoie les jetons.
  Future<AuthSession> exchangeCode({
    required String authCode,
    required String codeVerifier,
  }) async {
    final data = await _post(
      'token',
      query: {'grant_type': 'pkce'},
      body: {'auth_code': authCode, 'code_verifier': codeVerifier},
    );
    if (data['access_token'] is! String) {
      throw const ApiException(
        statusCode: 401,
        message:
            'Le lien de confirmation est invalide ou a expiré. '
            'Demandez un nouvel e-mail puis réessayez.',
      );
    }
    final user = data['user'];
    final email = user is Map && user['email'] is String
        ? user['email'] as String
        : '';
    return AuthSession.fromJson(data, email: email);
  }

  /// Mise à jour du compte (`PUT /user`, jeton porté) : métadonnées
  /// (`full_name`, `avatar`…) et/ou nouveau mot de passe.
  ///
  /// Renvoie les **métadonnées finales** (`user_metadata`) telles que
  /// le serveur les a enregistrées.
  Future<Map<String, dynamic>> updateUser({
    required String token,
    Map<String, dynamic>? data,
    String? password,
  }) async {
    final safeData = data == null ? null : Map<String, dynamic>.from(data);
    final avatar = safeData?['avatar'];
    if (avatar is String &&
        (avatar.startsWith('data:') || utf8.encode(avatar).length > 2048)) {
      // user_metadata is embedded in Supabase JWTs. Never send an inline
      // image (or another oversized avatar value) back to GoTrue.
      safeData!['avatar'] = null;
    }
    final body = <String, dynamic>{
      'data': ?safeData,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    final user = await _send('PUT', 'user', body: body, bearer: token);
    final metadata = user['user_metadata'];
    return metadata is Map
        ? Map<String, dynamic>.from(metadata)
        : <String, dynamic>{};
  }

  /// Profil courant (`GET /user`) : récupère notamment les métadonnées
  /// après une connexion dont la réponse n'en contenait pas.
  Future<Map<String, dynamic>> fetchUser(String token) async {
    final user = await _send('GET', 'user', bearer: token);
    final metadata = user['user_metadata'];
    return metadata is Map
        ? Map<String, dynamic>.from(metadata)
        : <String, dynamic>{};
  }

  /// Connexion (e-mail + mot de passe) → session.
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final data = await _post(
      'token',
      query: {'grant_type': 'password'},
      body: {'email': email, 'password': password},
    );
    if (data['access_token'] is! String) {
      throw const ApiException(
        statusCode: 401,
        message: 'Adresse e-mail ou mot de passe incorrect.',
      );
    }
    return AuthSession.fromJson(data, email: email);
  }

  /// Renvoi de la session à partir d'un jeton de rafraîchissement.
  Future<AuthSession> refresh(String refreshToken) async {
    final data = await _post(
      'token',
      query: {'grant_type': 'refresh_token'},
      body: {'refresh_token': refreshToken},
    );
    if (data['access_token'] is! String) {
      throw const ApiException(
        statusCode: 401,
        message: 'Votre session a expiré. Veuillez vous reconnecter.',
      );
    }
    return AuthSession.fromJson(data, email: '');
  }

  /// Déconnexion côté serveur (best-effort : une erreur réseau ne doit
  /// jamais bloquer la déconnexion locale).
  Future<void> signOut(String accessToken) async {
    try {
      await _client
          .post(
            _endpoint('logout'),
            headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
          )
          .timeout(_timeout);
    } catch (e) {
      debugPrint('Flowday auth logout ignoré : $e');
    }
  }
}
