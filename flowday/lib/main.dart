import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/task_reminder_service.dart';

/// Point d'entrée de l'application Flowday.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // L'icône du splash (et de l'application) est décodée **avant** la
  // première image Flutter : l'écran de lancement natif — qui affiche déjà
  // ce logo — reste affiché le temps du décodage, puis le splash Flutter
  // apparaît complet, sans clignotement.
  await Future.wait([
    TaskReminderService.instance.initialize(),
    _preloadSplashLogo(),
  ]);
  runApp(const FlowdayApp());
}

/// Décode l'icône du splash dans le cache d'images de Flutter.
///
/// La clé de cache est identique à celle utilisée par `Image.asset`
/// (`AssetImage` avec `scale: 1.0`), donc le splash l'affiche dès sa
/// première image.
Future<void> _preloadSplashLogo() async {
  const image = AssetImage('assets/images/app_icon.png');
  final completer = Completer<void>();
  final stream = image.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, _) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
    onError: (_, _) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {});
}
