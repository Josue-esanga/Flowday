import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';
import '../l10n/app_localizations.dart';
import 'supabase_config.dart';

/// Client **Supabase Storage** pour la photo de profil.
///
/// L'image est envoyée dans le bucket public [avatarsBucket], dans un
/// dossier portant l'identifiant du compte
/// (`<user-id>/avatar.jpg`) : elle est donc disponible sur tous les
/// appareils et **survit aux reconnexions**. L'URL publique renvoyée est
/// ensuite enregistrée dans `user_metadata.avatar` (chaîne courte, sans
/// impact sur la taille du jeton).
///
/// Le bucket doit être créé une seule fois dans le projet Supabase — voir
/// `supabase/avatars_bucket.sql` (script fourni avec le dépôt).
class SupabaseStorageClient {
  SupabaseStorageClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Bucket public des photos de profil.
  static const String avatarsBucket = 'avatars';

  static const Duration _timeout = Duration(seconds: 20);

  /// Taille maximale acceptée par le bucket (5 Mo).
  static const int maxBytes = 5 * 1024 * 1024;

  /// Envoie [bytes] (upsert) et renvoie l'**URL publique** de l'image,
  /// horodatée pour forcer le rafraîchissement du cache après un
  /// changement de photo.
  Future<String> uploadAvatar({
    required String token,
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (bytes.length > maxBytes) {
      throw ApiException(
        statusCode: 413,
        message: AppLocalizations.instance.t(
          'La photo est trop volumineuse (5 Mo maximum).',
        ),
      );
    }
    final path = '${_safeSegment(userId)}/avatar.${_extension(contentType)}';
    final uri = Uri.parse(
      '${SupabaseConfig.projectUrl}/storage/v1/object/$avatarsBucket/$path',
    );
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'Authorization': 'Bearer $token',
              'Content-Type': contentType,
              'Cache-Control': 'max-age=3600',
              'x-upsert': 'true',
            },
            body: bytes,
          )
          .timeout(_timeout);
      if (response.statusCode >= 400) {
        debugPrint(
          'Flowday storage upload → HTTP ${response.statusCode}: '
          '${response.body}',
        );
        throw ApiException(
          statusCode: response.statusCode,
          message: _errorMessage(response.statusCode, response.body),
        );
      }
      return '${publicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: _networkMessage);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Flowday storage upload ignoré : $e');
      throw ApiException(statusCode: 0, message: _networkMessage);
    }
  }

  /// Supprime une photo (best-effort : un échec ne bloque jamais
  /// l'enregistrement du profil).
  Future<void> deleteAvatar({
    required String token,
    required String path,
  }) async {
    final safePath = path.split('/').map(_safeSegment).join('/');
    try {
      await _client
          .delete(
            Uri.parse(
              '${SupabaseConfig.projectUrl}/storage/v1/object/'
              '$avatarsBucket/$safePath',
            ),
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
    } catch (e) {
      debugPrint('Flowday storage delete ignoré : $e');
    }
  }

  /// URL publique d'un objet du bucket.
  String publicUrl(String path) =>
      '${SupabaseConfig.projectUrl}/storage/v1/object/public/'
      '$avatarsBucket/$path';

  /// Extrait le chemin Storage d'une URL publique Flowday (`null` si
  /// l'URL n'appartient pas au bucket).
  String? pathFromUrl(String url) {
    final marker = '/storage/v1/object/public/$avatarsBucket/';
    final index = url.indexOf(marker);
    if (index < 0) return null;
    final path = url.substring(index + marker.length).split('?').first;
    return path.isEmpty ? null : path;
  }

  static String _extension(String contentType) {
    final type = contentType.toLowerCase();
    if (type.contains('png')) return 'png';
    if (type.contains('webp')) return 'webp';
    if (type.contains('gif')) return 'gif';
    return 'jpg';
  }

  static String _safeSegment(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._\-]'), '_');

  static String get _networkMessage => AppLocalizations.instance.t(
    'Impossible de joindre le serveur. Vérifiez votre connexion internet, '
    'puis réessayez.',
  );

  /// Message utilisateur (aucun détail technique).
  static String _errorMessage(int status, String body) {
    final l10n = AppLocalizations.instance;
    if (status == 404 ||
        body.contains('Bucket not found') ||
        body.contains('NoSuchBucket')) {
      return l10n.t(
        "L'envoi des photos n'est pas encore activé. Réessayez plus tard.",
      );
    }
    if (status == 401 || status == 403) {
      return l10n.t(
        "Vous n'êtes pas autorisé à envoyer cette photo. Reconnectez-vous "
        'puis réessayez.',
      );
    }
    if (status == 413) {
      return l10n.t('La photo est trop volumineuse (5 Mo maximum).');
    }
    if (status >= 500) {
      return l10n.t('Le service rencontre un problème. Réessayez plus tard.');
    }
    return l10n.t("L'envoi de la photo a échoué. Réessayez plus tard.");
  }
}
