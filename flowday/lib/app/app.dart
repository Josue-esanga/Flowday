import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FlowdayApp());
}

/// Application Flowday : thème clair et coque de navigation.
///
/// Phase actuelle : design (UI statique sur données de maquette).
/// La logique métier et le stockage local viendront ensuite.
class FlowdayApp extends StatelessWidget {
  const FlowdayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowday',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}
