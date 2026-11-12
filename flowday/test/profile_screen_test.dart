import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/app.dart';
import 'package:flowday/core/network/supabase_auth_client.dart';
import 'package:flowday/core/providers/auth_provider.dart';
import 'package:flowday/features/account/presentation/profile_edit_sheet.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_task_repository.dart';

/// PNG 8×8 minimal : simule la photo choisie dans la galerie.
const String _tinyAvatar =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGP4UiaPFTEMLQkAmUJiQV5sAqkAAAAASUVORK5CYII=';

/// Client d'auth factice : enregistre la dernière mise à jour envoyée
/// (`PUT /user` simulé — aucun réseau en test).
class FakeAuthClient extends SupabaseAuthClient {
  Map<String, dynamic>? lastData;
  String? lastPassword;

  @override
  Future<Map<String, dynamic>> updateUser({
    required String token,
    Map<String, dynamic>? data,
    String? password,
  }) async {
    lastData = data;
    lastPassword = password;
    return data ?? const {};
  }
}

/// Laisse le SnackBar se terminer (timer) puis termine son animation.
Future<void> _settleSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  Widget app(AuthProvider auth) =>
      FlowdayApp(repository: FakeTaskRepository(), auth: auth);

  testWidgets('Profil : compte réel + déconnexion confirmée', (tester) async {
    await tester.pumpWidget(
      app(
        AuthProvider.authenticated(
          email: 'josue@flowday.app',
          metadata: const {'full_name': 'Josué Esanga'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Onglet Profil.
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    // Identité réelle du compte (aucun nom codé en dur).
    expect(find.text('Josué Esanga'), findsOneWidget);
    expect(find.text('josue@flowday.app'), findsOneWidget);

    // Déconnexion : confirmation puis retour à l'écran de connexion.
    await tester.ensureVisible(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter ?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await tester.pumpAndSettle();

    expect(find.text('Prêt pour une journée productive ?'), findsOneWidget); // AuthScreen
    expect(find.text('Josué Esanga'), findsNothing);
    expect(find.text('Vous êtes déconnecté.'), findsOneWidget);
    await _settleSnackBars(tester);
  });

  testWidgets('Modifier le profil : le nom est enregistré', (tester) async {
    final client = FakeAuthClient();
    await tester.pumpWidget(
      app(
        AuthProvider.authenticated(
          metadata: const {'full_name': 'Ancien Nom'},
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Ancien Nom'), findsOneWidget);

    // Ouverture de la feuille d'édition.
    await tester.ensureVisible(find.text('Modifier le profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier le profil'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3)); // nom + 2 mots de passe

    // Saisie du nouveau nom + enregistrement.
    await tester.enterText(find.byType(TextField).first, 'Josué Nouveau');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    // Feuille fermée, profil rafraîchi, patch envoyé au client.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Josué Nouveau'), findsOneWidget);
    expect(find.text('Profil mis à jour.'), findsOneWidget);
    expect(client.lastData?['full_name'], 'Josué Nouveau');
    await _settleSnackBars(tester);
  });

  testWidgets('Feuille : la photo choisie rejoint la mise à jour', (
    tester,
  ) async {
    final client = FakeAuthClient();
    final auth = AuthProvider.authenticated(
      metadata: const {'full_name': 'Photo Test'},
      client: client,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showProfileEditSheet(
                  context,
                  pickImage: () async => _tinyAvatar,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));

    // Choix de la photo (sélecteur injecté) → « Retirer » apparaît.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choisir une photo'));
    await tester.pumpAndSettle();
    expect(find.text('Retirer'), findsOneWidget);

    // Enregistrement → la photo (data-URL) part avec le nom.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing); // feuille fermée
    expect(auth.fullName, 'Photo Test');
    expect(auth.avatar, _tinyAvatar);
    expect(client.lastData?['avatar'], _tinyAvatar);
    expect(client.lastData?['full_name'], 'Photo Test');
  });

  testWidgets('Paramètres : déconnexion confirmée', (tester) async {
    await tester.pumpWidget(app(AuthProvider.authenticated()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter ?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await tester.pumpAndSettle();

    expect(find.text('Prêt pour une journée productive ?'), findsOneWidget);
    expect(find.text('Vous êtes déconnecté.'), findsOneWidget);
    await _settleSnackBars(tester);
  });
}
