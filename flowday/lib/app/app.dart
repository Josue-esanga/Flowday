import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_deep_links.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/tasks_provider.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../shared/data/task_repository.dart';
import '../shared/widgets/flowday_logo.dart';
import 'home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FlowdayApp());
}

/// Application Flowday : thème clair, session (authentification), état
/// global des tâches et coque.
///
/// [repository] et [auth] sont injectables pour les tests (faux
/// repository / session déjà ouverte) ; en production, la session est
/// restaurée localement puis ouverte auprès de Supabase (GoTrue).
/// L'instance d'[AuthProvider] est créée **une seule fois** : l'état de
/// session survit aux rebuilds.
class FlowdayApp extends StatefulWidget {
  const FlowdayApp({super.key, this.repository, this.auth});

  final TaskRepository? repository;
  final AuthProvider? auth;

  @override
  State<FlowdayApp> createState() => _FlowdayAppState();
}

class _FlowdayAppState extends State<FlowdayApp> {
  late final AuthProvider _auth;
  AuthDeepLinks? _deepLinks;

  @override
  void initState() {
    super.initState();
    if (widget.auth != null) {
      // Session injectée (tests) : aucune restauration, aucun lien.
      _auth = widget.auth!;
      return;
    }
    final auth = AuthProvider();
    _auth = auth;
    // Restauration locale de la session, puis écoute des liens
    // profonds : le lien de confirmation e-mail reçu au démarrage à
    // froid attend la fin de la restauration avant d'ouvrir la session.
    final restoring = auth.restoreSession();
    _deepLinks = AuthDeepLinks.attach(auth, ready: restoring);
  }

  @override
  void dispose() {
    _deepLinks?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<TasksProvider>(
          create: (_) => TasksProvider(
            repository: widget.repository ?? TaskRepository(auth: _auth),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flowday',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Sélecteur de session : restauration (chargement), écran de connexion
/// ou coque principale. Les données de tâches ne sont chargées
/// **qu'après authentification** et réinitialisées à la déconnexion
/// (aucune donnée d'un compte n'est visible depuis un autre).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AuthStatus? _previous;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_previous != auth.status) {
      final previous = _previous;
      _previous = auth.status;

      // Connexion (initiale ou après reconnexion) → charger les données.
      if (auth.status == AuthStatus.authenticated &&
          previous != AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<TasksProvider>().loadInitial();
        });
      }

      // Déconnexion → vider les données du compte précédent.
      if (auth.status == AuthStatus.unauthenticated &&
          previous == AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<TasksProvider>().reset();
        });
      }
    }

    switch (auth.status) {
      case AuthStatus.unknown:
        return const _Splash();
      case AuthStatus.unauthenticated:
        return const AuthScreen();
      case AuthStatus.authenticated:
        return const HomeShell();
    }
  }
}

/// Écran de démarrage pendant la restauration de la session — affiche
/// directement le **logo Flowday** (aucun logo Flutter à l'ouverture).
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlowdayLogo(size: 136),
            SizedBox(height: 22),
            Text(
              'Flowday',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
