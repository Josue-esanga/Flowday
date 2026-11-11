import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/ui/states/error_state.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/category_meta.dart';
import '../../../shared/widgets/task_list_item.dart';
import 'task_form_screen.dart';

/// Page « Tâches de la catégorie » (flèche des cartes de l'accueil) :
/// toutes les tâches d'une catégorie, tous les jours, groupées par date
/// (F7 + F1) ; tap sur une tâche → modification (F4).
class CategoryTasksScreen extends StatefulWidget {
  const CategoryTasksScreen({super.key, required this.category});

  final Category category;

  @override
  State<CategoryTasksScreen> createState() => _CategoryTasksScreenState();
}

class _CategoryTasksScreenState extends State<CategoryTasksScreen> {
  List<TaskItem>? _tasks;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await context
          .read<TasksProvider>()
          .tasksOfCategory(widget.category.id);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de contacter le serveur.';
        _loading = false;
      });
    }
  }

  /// Ouvre le formulaire (F4) puis recharge (modification / suppression).
  Future<void> _openTask(TaskItem task) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskFormScreen(task: task)),
    );
    if (mounted) _load();
  }

  String get _countLabel {
    final count = _tasks?.length ?? 0;
    return '$count tâche${count > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------
          // En-tête sombre arrondi : retour + nom + pastille icône
          // ------------------------------------------------------------
          Container(
            padding: EdgeInsets.fromLTRB(6, topPadding + 12, 22, 20),
            decoration: const BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _loading ? 'Chargement…' : _countLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon(category.id),
                    color: category.color,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Corps : chargement / erreur / vide / liste groupée par date.
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    final tasks = _tasks ?? const <TaskItem>[];
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'Aucune tâche dans cette catégorie',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      );
    }

    // Groupement par date (les tâches arrivent triées date, heure).
    final groups = <String, List<TaskItem>>{};
    for (final task in tasks) {
      groups.putIfAbsent(task.date, () => []).add(task);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 30),
      children: [
        for (final entry in groups.entries) ...[
          // Titre de jour + nombre de tâches.
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
            child: Row(
              children: [
                Text(
                  FlowDates.displayDate(DateTime.parse(entry.key)),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value.length} tâche'
                  '${entry.value.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          for (final task in entry.value)
            TaskListItem(
              title: task.title,
              subtitle: task.description,
              completed: task.completed,
              trailing: Text(
                task.timeLabel.toLowerCase(),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _openTask(task),
            ),
        ],
      ],
    );
  }
}
