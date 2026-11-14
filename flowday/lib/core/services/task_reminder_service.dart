import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../shared/models/models.dart';
import '../l10n/app_localizations.dart';

/// Rappels locaux programmés à l'heure de début de chaque tâche.
class TaskReminderService {
  TaskReminderService._();

  static final instance = TaskReminderService._();
  static const _enabledKey = 'flowday.task_reminders.enabled';
  static const _defaultMinutesKey = 'flowday.task_reminders.default_minutes';
  static const _timezoneChannel = MethodChannel('flowday/device_timezone');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = false;
  bool _canScheduleExactly = false;
  int _defaultReminderMinutes = 0;
  bool get isEnabled => _enabled;
  int get defaultReminderMinutes => _defaultReminderMinutes;

  Future<void> initialize() async {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    try {
      final zoneName = await _timezoneChannel.invokeMethod<String>(
        'getLocalTimezone',
      );
      if (zoneName != null) {
        timezone.setLocalLocation(timezone.getLocation(zoneName));
      }
    } catch (_) {
      timezone.setLocalLocation(timezone.getLocation('Africa/Bujumbura'));
    }

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    _enabled = preferences.getBool(_enabledKey) ?? false;
    _defaultReminderMinutes = preferences.getInt(_defaultMinutesKey) ?? 0;
    if (defaultTargetPlatform == TargetPlatform.android) {
      _canScheduleExactly =
          await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.canScheduleExactNotifications() ??
          false;
    }
    _initialized = true;
  }

  /// Délai appliqué avant l'heure prévue de chaque tâche.
  Future<void> setDefaultReminderMinutes(int minutes) async {
    await initialize();
    _defaultReminderMinutes = minutes.clamp(0, 7 * 24 * 60);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_defaultMinutesKey, _defaultReminderMinutes);
  }

  /// Demande les permissions au moment où l'utilisateur active l'option.
  /// Renvoie `false` si le système a refusé les notifications.
  Future<bool> setEnabled(bool value) async {
    await initialize();
    if (value) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        if (granted == false) return false;
        _canScheduleExactly =
            await android?.requestExactAlarmsPermission() ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        if (granted == false) return false;
      }
    }

    _enabled = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, value);
    if (!value) await _notifications.cancelAll();
    return true;
  }

  /// Remplace le planning par les tâches à venir (la liste est limitée en
  /// amont pour rester sous les quotas d'alarmes Android/iOS).
  Future<void> replaceScheduledTasks(List<TaskItem> tasks) async {
    await initialize();
    if (!_enabled) return;
    await _notifications.cancelAll();
    final now = timezone.TZDateTime.now(timezone.local);
    for (final task in tasks) {
      if (task.completed) continue;
      final dateParts = task.date.split('-');
      final timeParts = task.time.split(':');
      if (dateParts.length != 3 || timeParts.length < 2) continue;
      final taskTime = timezone.TZDateTime(
        timezone.local,
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final scheduled = taskTime.subtract(
        Duration(minutes: _defaultReminderMinutes),
      );
      if (!scheduled.isAfter(now)) continue;

      final l10n = AppLocalizations.instance;
      final reminderText = l10n.reminderDuration(_defaultReminderMinutes);

      await _notifications.zonedSchedule(
        id: _notificationId(task.id),
        title: _defaultReminderMinutes == 0
            ? l10n.t('C’est l’heure de votre tâche')
            : l10n.t('Rappel de tâche'),
        body: _defaultReminderMinutes == 0
            ? task.title
            : l10n.taskStartsIn(task.title, reminderText),
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'flowday_task_reminders',
            l10n.t('Rappels de tâches'),
            channelDescription: l10n.t(
              'Rappels à l’heure prévue pour vos tâches',
            ),
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: _canScheduleExactly
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: task.id,
      );
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _notifications.cancelAll();
  }

  int _notificationId(String taskId) {
    // Stable across launches so replacing schedules reliably replaces alarms.
    var hash = 0x811c9dc5;
    for (final codeUnit in taskId.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
