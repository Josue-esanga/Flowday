import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/auth_deep_links.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/providers/onboarding_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/tasks_provider.dart';
import '../core/services/task_reminder_service.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../shared/data/task_repository.dart';
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
  late final ThemeProvider _theme;
  late final LocaleProvider _locale;
  late final OnboardingProvider _onboarding;
  AuthDeepLinks? _deepLinks;

  @override
  void initState() {
    super.initState();
    _theme = ThemeProvider()..restore();
    _locale = LocaleProvider()..restore();
    // En test, une session est injectée : on ne montre pas l'onboarding.
    _onboarding = OnboardingProvider(
      initialValue: widget.auth == null ? null : true,
    );
    if (widget.auth == null) _onboarding.restore();
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
    _theme.dispose();
    _locale.dispose();
    _onboarding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<ThemeProvider>.value(value: _theme),
        ChangeNotifierProvider<LocaleProvider>.value(value: _locale),
        ChangeNotifierProvider<OnboardingProvider>.value(value: _onboarding),
        ChangeNotifierProvider<TasksProvider>(
          create: (_) => TasksProvider(
            repository: widget.repository ?? TaskRepository(auth: _auth),
          ),
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, appearance, locale, _) => MaterialApp(
          title: 'Flowday',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: appearance.isDark ? ThemeMode.dark : ThemeMode.light,
          locale: locale.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _RootGate(
            // En production, le splash reste visible un court instant même
            // quand la session est déjà restaurée (sinon il disparaît en
            // quelques millisecondes). En test (session injectée), aucune
            // attente artificielle.
            minSplash: widget.auth == null
                ? const Duration(milliseconds: 800)
                : Duration.zero,
          ),
        ),
      ),
    );
  }
}

/// Porte d'entrée : onboarding au premier lancement, puis écran de
/// connexion ou coque principale selon la session.
///
/// Le splash reste affiché **au moins** [minSplash] : une session déjà
/// restaurée le faisait sinon disparaître en quelques millisecondes, ce
/// qui donnait l'impression qu'il avait été supprimé.
class _RootGate extends StatefulWidget {
  const _RootGate({required this.minSplash});

  final Duration minSplash;

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _splashElapsed = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    if (widget.minSplash <= Duration.zero) {
      _splashElapsed = true;
      return;
    }
    _splashTimer = Timer(widget.minSplash, () {
      if (mounted) setState(() => _splashElapsed = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    if (!_splashElapsed || onboarding.isLoading) return const _Splash();
    if (onboarding.needsOnboarding) return const OnboardingScreen();
    return const _AuthGate();
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

      // Connexion (initiale ou après reconnexion) → charger les données et
      // proposer **une seule fois** l'autorisation des notifications avec la
      // boîte de dialogue native du téléphone (Android 13+ / iOS).
      if (auth.status == AuthStatus.authenticated &&
          previous != AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<TasksProvider>().loadInitial();
          TaskReminderService.instance.requestPermissionAfterLogin();
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
            _SplashLogo(),
            SizedBox(height: 22),
            Text(
              'Flowday',
              style: TextStyle(
                fontFamily: 'DancingScript',
                fontVariations: [FontVariation('wght', 700)],
                fontWeight: FontWeight.w700,
                fontSize: 38,
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

/// Logo du splash : **exactement l'icône de l'application**
/// (`assets/images/app_icon.png`, master 1024 px), présentée comme une
/// carte arrondie avec une ombre douce — même rendu que l'icône sur
/// l'écran d'accueil du téléphone.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  static const double size = 136;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.225),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/app_icon.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
