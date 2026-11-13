import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/tasks_provider.dart';
import '../features/account/presentation/profile_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/category_tasks_screen.dart';
import '../features/tasks/presentation/task_form_screen.dart';
import '../features/tasks/presentation/timeline_screen.dart';
import '../shared/models/models.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import 'theme/app_theme.dart';

/// Coque principale : barre de navigation (4 destinations + bouton +)
/// et contenu de l'onglet courant.
///
/// L'onglet Accueil alterne entre le tableau de bord (« Hey Mobina ! »)
/// et la timeline (ouverte via « See all » ou le calendrier).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _timelineOpen = false;

  /// Onglet d'où la timeline a été ouverte (retour à l'issue).
  int _timelineOrigin = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _timelineOpen = false;
    });
  }

  /// Ouvre la timeline sur `date` : charge la date demandée, bascule sur
  /// l'onglet Accueil (même depuis le Calendrier) et mémorise l'onglet
  /// d'origine pour y revenir à la fermeture.
  void _openTimelineFor(DateTime date) {
    context.read<TasksProvider>().selectDate(date);
    setState(() {
      _timelineOrigin = _selectedIndex;
      _selectedIndex = 0;
      _timelineOpen = true;
    });
  }

  void _closeTimeline() {
    setState(() {
      _timelineOpen = false;
      _selectedIndex = _timelineOrigin;
    });
  }

  /// Clic sur une tâche (dashboard) : coche / décoche (F6) **sans
  /// message au succès** (fluidité perçue) — seule une erreur d'appel
  /// serveur est signalée.
  Future<void> _toggleTask(TaskItem task) async {
    final ok = await context.read<TasksProvider>().toggle(task);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        content: Text('Action impossible pour le moment. Réessayez.'),
      ),
    );
  }

  void _openTaskForm([TaskItem? task]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)));
  }

  /// Ouvre la page « tâches de la catégorie » (flèche des cartes).
  void _openCategory(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryTasksScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // Onglet Accueil : dashboard ou timeline.
      _timelineOpen
          ? TimelineScreen(onBack: _closeTimeline)
          : DashboardScreen(
              onSeeAll: _openTimelineFor,
              onToggleTask: _toggleTask,
              onOpenCategory: _openCategory,
            ),
      CalendarScreen(onOpenTimeline: _openTimelineFor),
      const SettingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onSelected: _onTabSelected,
        onAdd: () => _openTaskForm(),
      ),
    );
  }
}
