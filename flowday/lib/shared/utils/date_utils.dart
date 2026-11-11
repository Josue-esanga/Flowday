import 'package:flutter/material.dart';

/// Formats de dates/heures de Flowday (sans dépendance `intl`).
class FlowDates {
  FlowDates._();

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> weekLabels = [
    'Mon',
    'Tues',
    'Wed',
    'Thur',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// « 2026-06-28 » — format attendu par l'API.
  static String apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// « June 28, 2026 » — en-tête de la timeline.
  static String displayDate(DateTime d) =>
      '${months[d.month - 1]} ${d.day}, ${d.year}';

  /// « Friday » — grand titre de la timeline.
  static String weekdayName(DateTime d) => weekdays[d.weekday - 1];

  /// Lundi de la semaine contenant [day].
  static DateTime mondayOf(DateTime day) =>
      day.subtract(Duration(days: day.weekday - 1));

  /// Les 7 jours (lundi → dimanche) de la semaine de [day].
  static List<DateTime> weekOf(DateTime day) => [
        for (var i = 0; i < 7; i++) mondayOf(day).add(Duration(days: i)),
      ];

  /// [TimeOfDay] → « 14:00 » (format API).
  static String timeParam(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  /// Jour de la semaine abrégé (« Mon ») pour [date].
  static String shortWeekday(DateTime date) => weekLabels[date.weekday - 1];
}
