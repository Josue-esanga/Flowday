import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Paire **PKCE** (RFC 7636) : vérificateur aléatoire + défi `s256`.
///
/// À l'inscription, l'application envoie le défi à GoTrue ; le
/// vérificateur reste local (mémoire + `shared_preferences`). Quand
/// l'utilisateur clique le lien de confirmation e-mail et que l'ouvre
/// l'application (`flowday://login-callback?code=…`), le code reçu est
/// échangé contre une session **avec** ce vérificateur — un lien volé
/// ne peut donc pas être utilisé seul.
class Pkce {
  const Pkce({required this.verifier, required this.challenge});

  /// Vérificateur aléatoire (43 caractères, `base64url` sans padding).
  final String verifier;

  /// Défi `s256` envoyé à GoTrue (SHA-256 du vérificateur, `base64url`).
  final String challenge;

  /// Génère une nouvelle paire (32 octets aléatoires sécurisés).
  factory Pkce.generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final verifier = base64UrlEncode(bytes).replaceAll('=', '');
    return Pkce(verifier: verifier, challenge: challengeFor(verifier));
  }

  /// Défi `s256` : `BASE64URL(SHA256(verifier))` sans padding.
  ///
  /// Vecteur de référence de la RFC 7636 (annexe B) couvert par les tests.
  static String challengeFor(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');
}
