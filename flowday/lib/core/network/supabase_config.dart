/// Configuration de l'accès **direct Supabase** (PostgREST) de Flowday.
///
/// L'application ne passe plus par le serveur Django : elle interroge
/// directement l'API REST de Supabase, joignable depuis n'importe quel
/// appareil connecté à internet (aucun `adb reverse` ni serveur local).
///
/// Surcharges au lancement (optionnelles) :
/// ```sh
/// flutter run \
///   --dart-define=FLOWDAY_SUPABASE_URL=https://mon-projet.supabase.co \
///   --dart-define=FLOWDAY_SUPABASE_ANON_KEY=sb_publishable_…
/// ```
class SupabaseConfig {
  SupabaseConfig._();

  /// URL du projet Supabase (sans le suffixe `/rest/v1`).
  static const String projectUrl = String.fromEnvironment(
    'FLOWDAY_SUPABASE_URL',
    defaultValue: 'https://dyodgnjsgrxmxtxfhpha.supabase.co',
  );

  /// Clé *publishable* (ex-`anon`) du projet.
  ///
  /// Clé **publique par conception** : embarquée dans l'application, elle
  /// authentifie la requête auprès de Supabase mais ne protège rien seule —
  /// la protection des données repose sur les politiques RLS de la base
  /// (voir `flowday_api/README.md`).
  static const String anonKey = String.fromEnvironment(
    'FLOWDAY_SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_XOefhBGt_eO6kdw12ndZiA_n3E6bRvC',
  );

  /// Endpoint REST (PostgREST) du projet.
  static final Uri restBase = Uri.parse('$projectUrl/rest/v1');

  /// `false` tant qu'aucune clé n'est renseignée (erreur explicite à l'usage).
  static bool get isConfigured => anonKey.isNotEmpty;
}
