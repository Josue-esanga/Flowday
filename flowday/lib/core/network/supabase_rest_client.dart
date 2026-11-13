import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';
import 'supabase_auth_client.dart';
import 'supabase_config.dart';

/// Client HTTP minimal vers l'API REST **Supabase** (PostgREST).
///
/// Chaque table est une ressource JSON sur `/rest/v1/…` :
/// - `GET    <table>?select=…&<col>=eq.…&order=…` → liste de lignes
/// - `POST   <table>` (insertion, `Prefer: return=representation`)
/// - `PATCH  <table>?id=eq.<uuid>` (mise à jour partielle)
/// - `DELETE <table>?id=eq.<uuid>` (renvoie les lignes supprimées)
///
/// **Authentification** : l'en-tête `apikey` porte la clé publique du
/// projet, l'en-tête `Authorization` porte le **jeton de l'utilisateur
/// connecté** ([TokenSource]) — les politiques RLS de la base ne
/// laissent alors à chacun que l'accès à ses propres tâches. Si le
/// jeton est refusé (401), le client tente un rafraîchissement puis
/// réessaie la requête une fois ; sinon la session est close et
/// l'application bascule à l'écran de connexion.
///
/// Toutes les réponses sont des **listes de lignes** : une liste vide
/// sur une mutation signifie « ligne introuvable » et est traduite en
/// `ApiException(404)` par la couche au-dessus. Les messages d'erreur
/// affichés sont professionnels et génériques — le détail brut du
/// serveur part uniquement en console.
class SupabaseRestClient {
  SupabaseRestClient({http.Client? client, this.tokens})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Jetons de l'utilisateur connecté (authentification + rafraîchissement).
  final TokenSource? tokens;

  /// Délai par requête (Supabase est public : réseau mobile compris).
  static const Duration _timeout = Duration(seconds: 10);

  static const String _networkMessage =
      'Impossible de joindre le serveur. Vérifiez votre connexion internet, '
      'puis réessayez.';

  static const String _configMessage =
      'Application non configurée. Contactez le support.';

  /// En-têtes : `apikey` (identification du projet) + `Authorization`
  /// (jeton utilisateur, sinon clé publique → rôle `anon` bloqué par RLS).
  Map<String, String> get _headers => {
    'apikey': SupabaseConfig.anonKey,
    'Authorization': 'Bearer ${tokens?.accessToken ?? SupabaseConfig.anonKey}',
    'Accept': 'application/json',
  };

  /// GET : lignes de `table`. Les filtres PostgREST passent par `query`,
  /// ex. `{'select': 'id,name', 'date': 'eq.2026-11-11'}` ; une valeur
  /// `List` produit un paramètre répété (ET), ex. plage de dates.
  Future<List<Map<String, dynamic>>> get(
    String table, {
    Map<String, Object> query = const {},
  }) => _send('GET', table, query: query);

  /// POST : insère `body` et renvoie la ligne créée (avec les `select`).
  Future<List<Map<String, dynamic>>> post(
    String table, {
    required Map<String, dynamic> body,
    Map<String, Object> query = const {},
  }) => _send('POST', table, query: query, body: body);

  /// PATCH : met à jour les lignes visées par `query` avec `body`.
  Future<List<Map<String, dynamic>>> patch(
    String table, {
    required Map<String, dynamic> body,
    Map<String, Object> query = const {},
  }) => _send('PATCH', table, query: query, body: body);

  /// DELETE : supprime les lignes visées par `query`, renvoie les supprimées.
  Future<List<Map<String, dynamic>>> delete(
    String table, {
    Map<String, Object> query = const {},
  }) => _send('DELETE', table, query: query);

  Future<List<Map<String, dynamic>>> _send(
    String method,
    String table, {
    Map<String, Object> query = const {},
    Map<String, dynamic>? body,
    bool retried = false,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw const ApiException(statusCode: 0, message: _configMessage);
    }

    final uri = SupabaseConfig.restBase.replace(
      path: '${SupabaseConfig.restBase.path}/$table',
      queryParameters: query.isEmpty ? null : query,
    );

    try {
      final request = http.Request(method, uri);
      request.headers.addAll(_headers);
      // PostgREST : renvoie les lignes impactées (permet de détecter un
      // « rien supprimé / rien modifié » → 404).
      if (body != null || method == 'DELETE') {
        request.headers['Prefer'] = 'return=representation';
      }
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }

      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      // 401 → rafraîchir la session puis réessayer une seule fois.
      if (response.statusCode == 401 && !retried) {
        final refreshed = await tokens?.refreshSession() ?? false;
        if (refreshed) {
          return await _send(
            method,
            table,
            query: query,
            body: body,
            retried: true,
          );
        }
      }
      return _decode(response, method: method, uri: uri);
    } on TimeoutException {
      throw const ApiException(statusCode: 0, message: _networkMessage);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(statusCode: 0, message: _networkMessage);
    }
  }

  /// Réponse 2xx → liste de lignes (vide si corps vide).
  List<Map<String, dynamic>> _decode(
    http.Response response, {
    required String method,
    required Uri uri,
  }) {
    if (response.statusCode >= 400) {
      debugPrint('Flowday [rest] $method $uri');
      final accessToken = tokens?.accessToken;
      debugPrint(
        'Flowday [rest] tokenPresent=${accessToken != null} '
        'jwtParts=${accessToken?.split('.').length ?? 0} '
        'contentType=${response.headers['content-type']} '
        'requestId=${response.headers['sb-request-id']}',
      );
      final error = ApiException.fromBody(
        response.statusCode,
        _errorBody(response.body),
      );
      error.logDetails('rest'); // détail serveur → console
      throw error;
    }
    if (response.body.isEmpty) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    if (decoded is Map<String, dynamic>) return [decoded];
    return const [];
  }

  /// Corps d'erreur → JSON ; PostgREST : `{"code", "message", "details"…}`.
  Map<String, dynamic> _errorBody(String body) {
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Un proxy ou une passerelle peut renvoyer du texte/HTML au lieu
        // du JSON PostgREST. Conserver un extrait pour le diagnostic local.
      }
    }
    final excerpt = body.trim();
    return {
      'message': excerpt.isEmpty
          ? 'Réponse HTTP sans corps exploitable'
          : excerpt.length <= 500
          ? excerpt
          : '${excerpt.substring(0, 500)}…',
    };
  }
}
