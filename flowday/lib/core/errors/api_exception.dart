import 'package:flutter/foundation.dart';

/// Erreur remontée par la couche data (Supabase/PostgREST, ou l'API
/// Django/DRF optionnelle).
///
/// **Politique d'affichage** : [message] est toujours un message
/// **professionnel, en français et générique** — il ne révèle jamais
/// l'infrastructure (serveur, base, colonnes, clés, codes SQL…). Le texte
/// brut renvoyé par le serveur est conservé dans [details] et n'est
/// affiché qu'en console (`debugPrint`), pour le diagnostic développeur.
///
/// Formats de corps rencontrés :
/// - **PostgREST** : `{"code": "PGRST…", "message": "…"}` (+ `details`,
///   `hint`) ou une erreur Postgres (`23502`, `23503`…).
/// - **DRF** : `{"detail": "…"}` ou des erreurs par champ
///   `{"title": ["Le titre est obligatoire."]}`.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.details = '',
    this.fieldErrors = const {},
  });

  /// Code HTTP (0 = erreur réseau / délai dépassé / configuration manquante).
  final int statusCode;

  /// Message global **affichable à l'utilisateur** (professionnel, FR).
  final String message;

  /// Détail brut du serveur — **console uniquement**, jamais affiché.
  final String details;

  /// Erreurs par champ, ex. `{'title': 'Le titre est obligatoire.'}`.
  final Map<String, String> fieldErrors;

  bool get isNetwork => statusCode == 0;

  factory ApiException.fromBody(int statusCode, Map<String, dynamic> body) {
    final details = _detailsOf(body);

    // 401 / 403 : toujours « session expirée » (aucun détail serveur).
    if (statusCode == 401 || statusCode == 403) {
      return ApiException(
        statusCode: statusCode,
        message: 'Votre session a expiré. Veuillez vous reconnecter.',
        details: details,
      );
    }

    // PostgREST / Postgres : corps technique → message générique (jamais
    // le texte brut, qui contiendrait noms de tables et de colonnes).
    if (body['message'] is String || body['code'] is String) {
      return ApiException(
        statusCode: statusCode,
        message: _genericMessage(statusCode, body),
        details: details,
      );
    }

    // DRF : détail global ou erreurs par champ (messages applicatifs).
    final fieldErrors = _fieldErrorsOf(body);
    var message = body['detail'] is String ? body['detail'] as String : '';
    if (message.isEmpty && fieldErrors.isNotEmpty) {
      message = fieldErrors.values.first;
    }
    if (!_looksUserFacing(message)) {
      message = _genericMessage(statusCode, body);
    }
    return ApiException(
      statusCode: statusCode,
      message: message,
      details: details,
      fieldErrors: fieldErrors,
    );
  }

  /// Message générique, sans fuite d'information sur l'infrastructure.
  static String _genericMessage(int statusCode, Map<String, dynamic> body) {
    switch (statusCode) {
      case 404:
      case 410:
        return "Cet élément est introuvable : il a peut-être été supprimé.";
      case 409:
        return 'Cet enregistrement existe déjà.';
      case 429:
        return 'Trop de tentatives. Réessayez dans quelques instants.';
      case 400:
      case 422:
        switch (body['code']?.toString()) {
          case '23503':
            return "Cette opération est impossible : la catégorie liée est "
                'introuvable.';
          case '23505':
            return 'Cet enregistrement existe déjà.';
          case '22001':
            // `varchar(n)` dépassé (titre de tâche) → message actionnable.
            return 'Saisie trop longue : réduisez la taille de vos '
                'informations, puis réessayez.';
          default:
            return 'Vérifiez les informations saisies, puis réessayez.';
        }
      default:
        if (statusCode >= 500) {
          return 'Le service rencontre un problème. Réessayez plus tard.';
        }
        return 'Une erreur est survenue. Réessayez plus tard.';
    }
  }

  /// Corps d'erreur → texte brut (diagnostic console uniquement).
  static String _detailsOf(Map<String, dynamic> body) {
    final buffer = <String>[];
    final code = body['code'];
    if (code != null) buffer.add('code=$code');
    for (final key in ['message', 'detail', 'msg', 'details']) {
      final value = body[key];
      if (value is String && value.isNotEmpty) buffer.add(value);
    }
    return buffer.join(' — ');
  }

  /// Erreurs par champ DRF `{'title': ["…"]}` → `{'title': '…'}`.
  static Map<String, String> _fieldErrorsOf(Map<String, dynamic> body) {
    final errors = <String, String>{};
    body.forEach((key, value) {
      if (key == 'detail') return;
      if (value is List && value.isNotEmpty) {
        errors[key] = value.first.toString();
      } else if (value is String && value.isNotEmpty) {
        errors[key] = value;
      }
    });
    return errors;
  }

  /// Un message DRF rédigé pour l'utilisateur ? (sinon on le remplace par
  /// un message générique pour ne pas exposer de technique.)
  static bool _looksUserFacing(String message) {
    if (message.isEmpty) return false;
    // Messages applicatifs : français, sans nom de colonne ni de table.
    final technical = RegExp(
      r'(planning_|auth\.|column|relation|constraint|syntax|JWT|api ?key)',
      caseSensitive: false,
    );
    return !technical.hasMatch(message);
  }

  /// Journalise le détail brut du serveur (console développeur).
  void logDetails(String context) {
    if (details.isNotEmpty) {
      debugPrint('Flowday [$context] HTTP $statusCode — $details');
    }
  }

  @override
  String toString() => message;
}
