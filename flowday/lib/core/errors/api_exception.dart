/// Erreur remontée par la couche data (Supabase/PostgREST, ou l'API
/// Django/DRF optionnelle).
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
    this.fieldErrors = const {},
  });

  /// Code HTTP (0 = erreur réseau / délai dépassé / configuration manquante).
  final int statusCode;

  /// Message global lisible.
  final String message;

  /// Erreurs par champ, ex. `{'title': 'Le titre est obligatoire.'}`.
  final Map<String, String> fieldErrors;

  bool get isNetwork => statusCode == 0;

  factory ApiException.fromBody(int statusCode, Map<String, dynamic> body) {
    // PostgREST : un seul champ `message` (details/hint ne sont pas des
    // erreurs de champ — on les ignore volontairement).
    if (body['message'] is String) {
      return ApiException(
        statusCode: statusCode,
        message: _serverMessage(statusCode, body),
      );
    }

    // DRF : détail global ou erreurs par champ.
    final fieldErrors = <String, String>{};
    var message = '';

    body.forEach((key, value) {
      String? text;
      if (value is List && value.isNotEmpty) {
        text = value.first.toString();
      } else if (value is String) {
        text = value;
      }
      if (text == null) return;
      if (key == 'detail') {
        message = text;
      } else {
        fieldErrors[key] = text;
      }
    });

    if (message.isEmpty) {
      message = fieldErrors.values.isNotEmpty
          ? fieldErrors.values.first
          : 'Erreur $statusCode';
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      fieldErrors: fieldErrors,
    );
  }

  /// Message lisible pour une erreur PostgREST / Postgres.
  static String _serverMessage(int statusCode, Map<String, dynamic> body) {
    if (statusCode == 401 || statusCode == 403) {
      return 'Accès refusé : clé API Supabase invalide ou droits insuffisants.';
    }
    switch (body['code']?.toString()) {
      case 'PGRST116':
        return 'Élément introuvable.';
      case '23502':
        return 'Un champ obligatoire est manquant.';
      case '23503':
        return 'Référence inexistante (catégorie inconnue).';
      case '23505':
        return 'Cet enregistrement existe déjà.';
      case '42501':
        return 'Accès refusé par la base de données.';
      case '42703':
        return 'Erreur interne de la base de données.';
      default:
        return body['message'] as String;
    }
  }

  @override
  String toString() => message;
}
