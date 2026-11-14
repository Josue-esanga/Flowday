import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// Formats de dates/heures de Flowday, adaptés à la langue courante.
class FlowDates {
  FlowDates._();

  static List<String> get months => AppLocalizations.instance.months;

  static List<String> get weekdays => AppLocalizations.instance.weekdays;

  static List<String> get weekLabels => AppLocalizations.instance.weekLabels;

  /// « 2026-06-28 » — format attendu par l'API.
  static String apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// « 28 juin 2026 » / « June 28, 2026 » — en-tête de la timeline.
  static String displayDate(DateTime d) =>
      AppLocalizations.instance.displayDate(d);

  /// « Vendredi » / « Friday » — grand titre de la timeline.
  static String weekdayName(DateTime d) => weekdays[d.weekday - 1];

  /// « Vendredi 28 juin » / « Friday, June 28 » — résumé du calendrier.
  static String summaryDate(DateTime d) =>
      AppLocalizations.instance.summaryDate(d);

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

  /// Jour de la semaine abrégé (« Lun » / « Mon ») pour [date].
  static String shortWeekday(DateTime date) => weekLabels[date.weekday - 1];
}
