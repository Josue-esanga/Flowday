import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/task_reminder_service.dart';

/// Point d'entrée de l'application Flowday.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TaskReminderService.instance.initialize();
  runApp(const FlowdayApp());
}
