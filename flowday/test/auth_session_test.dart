import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/core/errors/api_exception.dart';
import 'package:flowday/core/network/supabase_auth_client.dart';
import 'package:flowday/core/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client dont le rafraîchissement échoue avec l'erreur fournie.
class _FailingRefreshClient extends SupabaseAuthClient {
  _FailingRefreshClient(this.error);

  final ApiException error;
  int refreshCalls = 0;

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshCalls++;
    throw error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Panne réseau : la session locale est conservée', () async {
    final auth = AuthProvider.authenticated(
      client: _FailingRefreshClient(
        const ApiException(statusCode: 0, message: 'Réseau indisponible.'),
      ),
    );

    final refreshed = await auth.refreshSession();

    expect(refreshed, isFalse);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isAuthenticated, isTrue);
  });

  test('Démarrage hors ligne : la session restaurée reste ouverte', () async {
    SharedPreferences.setMockInitialValues({
      'fd.session.access': 'access',
      'fd.session.refresh': 'refresh',
      'fd.session.email': 'demo@flowday.app',
      'fd.session.expires': DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('fd.session.access'), 'access');
    expect(prefs.getString('fd.session.refresh'), 'refresh');
    expect(prefs.getInt('fd.session.expires'), isNotNull);

    final client = _FailingRefreshClient(
      const ApiException(statusCode: 0, message: 'Réseau indisponible.'),
    );
    final auth = AuthProvider(client: client);

    await auth.restoreSession();

    expect(client.refreshCalls, 1);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isAuthenticated, isTrue);
  });

  test('Jeton refusé : la session est fermée', () async {
    final auth = AuthProvider.authenticated(
      client: _FailingRefreshClient(
        const ApiException(statusCode: 401, message: 'Session expirée.'),
      ),
    );

    final refreshed = await auth.refreshSession();

    expect(refreshed, isFalse);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.isAuthenticated, isFalse);
  });
}
