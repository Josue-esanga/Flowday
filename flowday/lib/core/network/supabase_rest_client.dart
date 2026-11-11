import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';
import 'supabase_config.dart';

/// Client HTTP minimal vers l'API REST **Supabase** (PostgREST).
///
/// Chaque table est une ressource JSON sur `/rest/v1/…` :
/// - `GET    <table>?select=…&<col>=eq.…&order=…` → liste de lignes
/// - `POST   <table>` (insertion, `Prefer: return=representation`)
/// - `PATCH  <table>?id=eq.<uuid>` (mise à jour partielle)
/// - `DELETE <table>?id=eq.<uuid>` (renvoie les lignes supprimées)
///
/// Les en-têtes `apikey` + `Authorization` portent la clé publique du projet
/// (`SupabaseConfig.anonKey`). Toutes les réponses sont des **listes de
/// lignes** : une liste vide sur une mutation signifie « ligne introuvable »
/// et est traduite en `ApiException(404)` par la couche au-dessus.
class SupabaseRestClient {
  SupabaseRestClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Délai par requête (Supabase est public : réseau mobile compris).
  static const Duration _timeout = Duration(seconds: 10);

  static const String _networkMessage =
      'Serveur Supabase injoignable : vérifiez votre connexion internet.';

  static const String _missingKeyMessage =
      'Clé API Supabase manquante : renseignez FLOWDAY_SUPABASE_ANON_KEY '
      'ou la valeur par défaut de SupabaseConfig.anonKey.';

  Map<String, String> get _headers => {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Accept': 'application/json',
      };

  /// GET : lignes de `table`. Les filtres PostgREST passent par `query`,
  /// ex. `{'select': 'id,name', 'date': 'eq.2026-11-11'}` ; une valeur
  /// `List` produit un paramètre répété (ET), ex. plage de dates.
  Future<List<Map<String, dynamic>>> get(
    String table, {
    Map<String, Object> query = const {},
  }) =>
      _send('GET', table, query: query);

  /// POST : insère `body` et renvoie la ligne créée (avec les `select`).
  Future<List<Map<String, dynamic>>> post(
    String table, {
    required Map<String, dynamic> body,
    Map<String, Object> query = const {},
  }) =>
      _send('POST', table, query: query, body: body);

  /// PATCH : met à jour les lignes visées par `query` avec `body`.
  Future<List<Map<String, dynamic>>> patch(
    String table, {
    required Map<String, dynamic> body,
    Map<String, Object> query = const {},
  }) =>
      _send('PATCH', table, query: query, body: body);

  /// DELETE : supprime les lignes visées par `query`, renvoie les supprimées.
  Future<List<Map<String, dynamic>>> delete(
    String table, {
    Map<String, Object> query = const {},
  }) =>
      _send('DELETE', table, query: query);

  Future<List<Map<String, dynamic>>> _send(
    String method,
    String table, {
    Map<String, Object> query = const {},
    Map<String, dynamic>? body,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw const ApiException(statusCode: 0, message: _missingKeyMessage);
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
      return _decode(response);
    } on TimeoutException {
      throw const ApiException(statusCode: 0, message: _networkMessage);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(statusCode: 0, message: _networkMessage);
    }
  }

  /// Réponse 2xx → liste de lignes (vide si corps vide).
  List<Map<String, dynamic>> _decode(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException.fromBody(
        response.statusCode,
        _errorBody(response.body),
      );
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
        // corps non JSON : on retombe sur le message générique ci-dessous
      }
    }
    return {'message': 'Erreur serveur'};
  }
}
