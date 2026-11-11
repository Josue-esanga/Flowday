import 'package:flowday/app/theme/app_theme.dart';
import 'package:flowday/shared/models/models.dart';

/// Données de maquette — utilisées comme **fixture de tests** (tests de
/// rendu et faux repository) ; le rendu réel est alimenté par l'API via
/// `TaskRepository` (voir `test/fakes/fake_task_repository.dart`).
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
  static final List<WeekDay> weekDays = [
    WeekDay(label: 'Mon', dayNumber: 24, date: DateTime(2026, 6, 24)),
    WeekDay(label: 'Tues', dayNumber: 25, date: DateTime(2026, 6, 25)),
    WeekDay(label: 'Wed', dayNumber: 26, date: DateTime(2026, 6, 26)),
    WeekDay(label: 'Thur', dayNumber: 27, date: DateTime(2026, 6, 27)),
    WeekDay(label: 'Fri', dayNumber: 28, date: DateTime(2026, 6, 28)),
    WeekDay(label: 'Sat', dayNumber: 29, date: DateTime(2026, 6, 29)),
    WeekDay(label: 'Sun', dayNumber: 30, date: DateTime(2026, 6, 30)),
  ];

  /// Index du jour sélectionné par défaut (vendredi 28).
  static const int defaultWeekDayIndex = 4;

  // ---------------------------------------------------------------------
  // Tâches du jour (timeline « Today's task ») — format API :
  // date « AAAA-MM-JJ », time « HH:MM » (24 h)
  // ---------------------------------------------------------------------
  static const List<TaskItem> todayTasks = [
    TaskItem(
      id: 't1',
      title: 'Meeting with Shakib',
      description: 'At Google meet',
      date: '2026-06-28',
      time: '14:00',
      category: work,
      completed: true,
    ),
    TaskItem(
      id: 't2',
      title: 'Prepare workplace',
      description: 'on the computer and launch apps',
      date: '2026-06-28',
      time: '15:00',
      category: work,
    ),
    TaskItem(
      id: 't3',
      title: 'Yoga',
      description: 'Yoga at peaceful place village',
      date: '2026-06-28',
      time: '16:00',
      category: health,
    ),
    TaskItem(
      id: 't4',
      title: 'Go laundering',
      description: 'doing laundry a home',
      date: '2026-06-28',
      time: '17:00',
      category: personal,
    ),
  ];

  // ---------------------------------------------------------------------
  // Tâches d'hier (accueil)
  // ---------------------------------------------------------------------
  static const List<TaskItem> yesterdayTasks = [
    TaskItem(
      id: 'y1',
      title: 'Clean the garage',
      description: 'sort boxes and take out trash',
      date: '2026-06-27',
      time: '17:00',
      category: personal,
    ),
  ];
}
