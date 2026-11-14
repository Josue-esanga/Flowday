import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/core/errors/api_exception.dart';
import 'package:flowday/core/network/supabase_storage_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'La photo part dans avatars/<user-id>/ et renvoie son URL publique',
    () async {
      http.Request? sent;
      final client = SupabaseStorageClient(
        client: MockClient((request) async {
          sent = request;
          return http.Response('{"Key":"avatars/u-1/avatar.png"}', 200);
        }),
      );

      final url = await client.uploadAvatar(
        token: 'jwt-test',
        userId: 'u-1',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
      );

      expect(sent, isNotNull);
      expect(sent!.method, 'POST');
      expect(sent!.url.path, '/storage/v1/object/avatars/u-1/avatar.png');
      expect(sent!.headers['Authorization'], 'Bearer jwt-test');
      expect(sent!.headers['x-upsert'], 'true');
      expect(sent!.headers['Content-Type'], 'image/png');
      expect(sent!.bodyBytes, [1, 2, 3]);

      expect(
        url,
        contains('/storage/v1/object/public/avatars/u-1/avatar.png?v='),
      );
      expect(client.pathFromUrl(url), 'u-1/avatar.png');
    },
  );

  test('Bucket absent → message utilisateur explicite', () async {
    final client = SupabaseStorageClient(
      client: MockClient(
        (_) async => http.Response(
          '{"statusCode":"404","error":"Bucket not found"}',
          404,
        ),
      ),
    );

    await expectLater(
      client.uploadAvatar(
        token: 'jwt-test',
        userId: 'u-1',
        bytes: Uint8List.fromList([1]),
        contentType: 'image/jpeg',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('pas encore activé'),
        ),
      ),
    );
  });

  test('Photo trop lourde → refus avant tout envoi', () async {
    var called = false;
    final client = SupabaseStorageClient(
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      client.uploadAvatar(
        token: 'jwt-test',
        userId: 'u-1',
        bytes: Uint8List(SupabaseStorageClient.maxBytes + 1),
        contentType: 'image/jpeg',
      ),
      throwsA(isA<ApiException>()),
    );
    expect(called, isFalse);
  });

  test('Les noms de dossier sont assainis', () async {
    http.Request? sent;
    final client = SupabaseStorageClient(
      client: MockClient((request) async {
        sent = request;
        return http.Response('{}', 200);
      }),
    );

    await client.uploadAvatar(
      token: 'jwt-test',
      userId: 'user@example.com',
      bytes: Uint8List.fromList([1]),
      contentType: 'image/jpeg',
    );

    expect(
      sent!.url.path,
      '/storage/v1/object/avatars/user_example.com/avatar.jpg',
    );
  });
}
