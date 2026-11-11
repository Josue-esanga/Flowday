import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/tasks_provider.dart';
import '../shared/data/task_repository.dart';
import 'home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FlowdayApp());
}

/// Application Flowday : thème clair, état global (API) et coque.
///
/// [repository] est injectable pour les tests (faux repository) ; en
/// production, un `TaskRepository` réel vers l'API Django est utilisé.
class FlowdayApp extends StatelessWidget {
  const FlowdayApp({super.key, this.repository});

  final TaskRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TasksProvider>(
      create: (_) => TasksProvider(
        repository: repository ?? TaskRepository(),
      )..loadInitial(),
      child: MaterialApp(
        title: 'Flowday',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeShell(),
      ),
    );
  }
}
