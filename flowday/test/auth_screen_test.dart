import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowday/app/app.dart';
import 'package:flowday/core/providers/auth_provider.dart';

import 'fakes/fake_task_repository.dart';

/// Écran d'authentification (maquette « Se connecter » / « Créer un
/// compte ») : aucune session → connexion (en-tête noir, champs à
/// libellé flottant), validation client (aucun appel réseau), bascule
/// vers l'inscription puis retour.
void main() {
  Widget app() => FlowdayApp(
    repository: FakeTaskRepository(),
    auth: AuthProvider.signedOut(),
  );

  testWidgets('Aucune session → écran de connexion', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // En-tête noir (marque + accroche + titre) et champs de connexion.
    expect(find.text('Flowday'), findsOneWidget);
    expect(find.text('Prêt pour une journée productive ?'), findsOneWidget);
    expect(find.text('Se connecter'), findsWidgets); // titre + bouton
    expect(find.text('Adresse email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('OU CONTINUER AVEC'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);

    // Bascule vers l'inscription via le lien du bas.
    await tester.ensureVisible(find.text("S'inscrire"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("S'inscrire"));
    await tester.pumpAndSettle();
    expect(find.text('Créer un compte'), findsWidgets); // titre + bouton
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.textContaining('Déjà un compte'), findsOneWidget);

    // Retour à la connexion (le lien est sous la ligne de flottaison :
    // défilement puis clic).
    await tester.ensureVisible(find.textContaining('Déjà un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Prêt pour une journée productive ?'), findsOneWidget);
  });

  testWidgets('Validation avant tout appel réseau', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Champs vides → messages de validation (aucun appel réseau).
    final button = find.widgetWithText(ElevatedButton, 'Se connecter');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('L’adresse e-mail est obligatoire.'), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);

    // Adresse malformée → message dédié.
    await tester.enterText(find.byType(TextFormField).first, 'pas-un-email');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
  });
}
