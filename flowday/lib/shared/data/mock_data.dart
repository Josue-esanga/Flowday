import '../models/models.dart';
import '../../app/theme/app_theme.dart';

/// Données de maquette utilisées pour le design.
/// Elles seront remplacées par le stockage local à la phase « logique ».
class MockData {
  MockData._();

  // ---------------------------------------------------------------------
  // Catégories (README §5)
  // ---------------------------------------------------------------------
  static const Category work = Category(
    id: 'work',
    name: 'Work',
    color: AppColors.work,
  );
  static const Category health = Category(
    id: 'health',
    name: 'Health',
    color: AppColors.health,
  );
  static const Category personal = Category(
    id: 'personal',
    name: 'Personal',
    color: AppColors.personal,
  );
  static const Category education = Category(
    id: 'education',
    name: 'Education',
    color: AppColors.education,
  );

  static const List<Category> categories = [personal, work, health, education];

  // ---------------------------------------------------------------------
  // Sélecteur de semaine (maquette : semaine du 24 au 30)
  // ---------------------------------------------------------------------
  static const List<WeekDay> weekDays = [
    WeekDay(label: 'Mon', dayNumber: 24),
    WeekDay(label: 'Tues', dayNumber: 25),
    WeekDay(label: 'Wed', dayNumber: 26),
    WeekDay(label: 'Thur', dayNumber: 27),
    WeekDay(label: 'Fri', dayNumber: 28),
    WeekDay(label: 'Sat', dayNumber: 29),
    WeekDay(label: 'Sun', dayNumber: 30),
  ];

  /// Index du jour sélectionné par défaut (vendredi 28).
  static const int defaultWeekDayIndex = 4;

  // ---------------------------------------------------------------------
  // Tâches du jour (timeline « Today's task »)
  // ---------------------------------------------------------------------
  static const List<TaskItem> todayTasks = [
    TaskItem(
      id: 't1',
      title: 'Meeting with Shakib',
      description: 'At Google meet',
      timeLabel: '02:00 PM',
      category: work,
      completed: true,
    ),
    TaskItem(
      id: 't2',
      title: 'Prepare workplace',
      description: 'on the computer and launch apps',
      timeLabel: '03:00 PM',
      category: work,
    ),
    TaskItem(
      id: 't3',
      title: 'Yoga',
      description: 'Yoga at peaceful place village',
      timeLabel: '04:00 PM',
      category: health,
    ),
    TaskItem(
      id: 't4',
      title: 'Go laundering',
      description: 'doing laundry a home',
      timeLabel: '05:00 PM',
      category: personal,
    ),
  ];

  // ---------------------------------------------------------------------
  // Tâches d'hier (accueil)
  // ---------------------------------------------------------------------
  static const List<TaskItem> yesterdayTasks = [
    TaskItem(
      id: 'y1',
      title: 'Go laundering',
      description: 'doing laundry a home',
      timeLabel: '05:00 PM',
      category: personal,
    ),
  ];
}
