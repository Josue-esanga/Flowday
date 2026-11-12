import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flowday/core/network/pkce.dart';
import 'package:flowday/core/network/supabase_auth_client.dart';
import 'package:flowday/core/providers/auth_provider.dart';

/// Flux de confirmation d'inscription **par lien** (PKCE) :
/// - `Pkce` : vérificateur + défi `s256` (preuve RFC 7636) ;
/// - `signUp` : défi + `redirect_to` (deep link) envoyés à GoTrue ;
/// - `exchangeCode` : `POST token?grant_type=pkce` avec `auth_code` ;
/// - `AuthProvider` : vérificateur conservé, session ouverte après
///   échange, lien refusé sans inscription en attente ou sans
///   correspondance défi/vérificateur.
void main() {
  group('Pkce', () {
    test('génère un vérificateur aléatoire et son défi s256', () {
      final pkce = Pkce.generate();
      final other = Pkce.generate();

      expect(pkce.verifier.length, 43);
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(pkce.verifier), isTrue);
      expect(pkce.challenge, Pkce.challengeFor(pkce.verifier));
      expect(pkce.challenge, isNot(contains('=')));
      expect(pkce.verifier, isNot(equals(other.verifier)));
    });

    test('défi conforme à la preuve de référence RFC 7636 (annexe B)', () {
      expect(
        Pkce.challengeFor('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });
  });

  group('SupabaseAuthClient — PKCE', () {
    test(
      'signUp envoie le défi, la méthode et le deep link redirect_to',
      () async {
        late http.Request captured;
        final client = SupabaseAuthClient(
          client: MockClient((request) async {
            captured = request;
            return http.Response('{"id":"user-1"}', 200);
          }),
        );

        final result = await client.signUp(
          email: 'test@flowday.app',
          password: 'secret123',
          fullName: 'Test Flowday',
          codeChallenge: 'defi-s256',
        );

        expect(result.confirmationSent, isTrue);
        expect(
          captured.url.queryParameters['redirect_to'],
          'flowday://login-callback',
        );
        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body['code_challenge'], 'defi-s256');
        expect(body['code_challenge_method'], 's256');
        expect(body['data'], {'full_name': 'Test Flowday'});
      },
    );

    test('exchangeCode échange le code contre la session', () async {
      late http.Request captured;
      final client = SupabaseAuthClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'access_token': 'jeton-acces',
              'refresh_token': 'jeton-refresh',
              'expires_in': 3600,
              'user': {
                'email': 'test@flowday.app',
                'user_metadata': {'full_name': 'Test Flowday'},
              },
            }),
            200,
          );
        }),
      );

      final session = await client.exchangeCode(
        authCode: 'code-1',
        codeVerifier: 'verificateur-1',
      );

      expect(captured.url.path, endsWith('/token'));
      expect(captured.url.queryParameters['grant_type'], 'pkce');
      expect(jsonDecode(captured.body), {
        'auth_code': 'code-1',
        'code_verifier': 'verificateur-1',
      });
      expect(session.accessToken, 'jeton-acces');
      expect(session.email, 'test@flowday.app');
      expect(session.metadata['full_name'], 'Test Flowday');
    });
  });

  group('AuthProvider — confirmation par lien', () {
    const validSession = {
      'access_token': 'jeton-acces',
      'refresh_token': 'jeton-refresh',
      'expires_in': 3600,
      'user': {
        'email': 'test@flowday.app',
        'user_metadata': {'full_name': 'Test Flowday'},
      },
    };

    /// Faux serveur GoTrue : `/signup` enregistre le défi reçu ;
    /// `/token?grant_type=pkce` valide le couple défi/vérificateur
    /// (comme GoTrue) avant de renvoyer la session.
    SupabaseAuthClient fakeServer({bool recordChallenge = true}) {
      String? sentChallenge;
      return SupabaseAuthClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/signup')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            if (recordChallenge) {
              sentChallenge = body['code_challenge'] as String?;
            }
            return http.Response('{"id":"user-1"}', 200);
          }
          if (request.url.path.endsWith('/token')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final verifier = body['code_verifier'] as String?;
            final valid =
                verifier != null &&
                sentChallenge != null &&
                Pkce.challengeFor(verifier) == sentChallenge;
            if (!valid) {
              return http.Response(
                jsonEncode({
                  'error_code': 'bad_code_verifier',
                  'msg': 'invalid',
                }),
                400,
              );
            }
            return http.Response(jsonEncode(validSession), 200);
          }
          return http.Response('{}', 404);
        }),
      );
    }

    test('inscription puis échange du lien → session ouverte', () async {
      final auth = AuthProvider(client: fakeServer(), persist: false);

      expect(
        await auth.signUp(email: 'test@flowday.app', password: 'secret123'),
        isNull,
      );
      expect(auth.confirmationSent, isTrue);

      final error = await auth.completeEmailConfirmation('code-lien');
      expect(error, isNull);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.email, 'test@flowday.app');
      expect(auth.metadata['full_name'], 'Test Flowday');
      expect(auth.notice, 'Votre adresse e-mail est confirmée. Bienvenue !');

      // Vérificateur consommé : tout nouvel échange est refusé.
      final second = await auth.completeEmailConfirmation('code-lien');
      expect(second, isNotNull);
      expect(auth.isAuthenticated, isTrue); // la session reste ouverte
    });

    test('lien ouvert sans inscription en attente → refus explicite', () async {
      final auth = AuthProvider.signedOut(client: fakeServer());

      final error = await auth.completeEmailConfirmation('code-lien');

      expect(error, contains('invalide'));
      expect(auth.isAuthenticated, isFalse);
    });

    test(
      'vérificateur non reconnu → message générique, pas de session',
      () async {
        final auth = AuthProvider(
          client: fakeServer(recordChallenge: false),
          persist: false,
        );
        await auth.signUp(email: 'test@flowday.app', password: 'secret123');

        final error = await auth.completeEmailConfirmation('code-lien');

        expect(error, contains('invalide ou a expiré'));
        expect(auth.isAuthenticated, isFalse);
        expect(auth.notice, isNull);
      },
    );
  });
}
