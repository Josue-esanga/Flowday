import 'package:flutter/material.dart';

import '../features/account/presentation/profile_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/task_form_screen.dart';
import '../features/tasks/presentation/timeline_screen.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import 'theme/app_theme.dart';

/// Coque principale : barre de navigation (4 destinations + bouton +)
/// et contenu de l'onglet courant.
///
/// L'onglet Accueil alterne entre le tableau de bord (« Hello Mobina! »)
/// et la timeline « Today's task » (ouverte via « See all »).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _timelineOpen = false;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _timelineOpen = false;
    });
  }

  void _openTimeline() => setState(() => _timelineOpen = true);

  void _closeTimeline() => setState(() => _timelineOpen = false);

  void _openTaskForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TaskFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // Onglet Accueil : dashboard ou timeline.
      _timelineOpen
          ? TimelineScreen(onBack: _closeTimeline)
          : DashboardScreen(onSeeAll: _openTimeline),
      const CalendarScreen(),
      const SettingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onSelected: _onTabSelected,
        onAdd: _openTaskForm,
      ),
    );
  }
}
