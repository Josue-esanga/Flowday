import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/date_utils.dart';

/// Formulaire de création (F3) / modification (F4) / suppression (F5)
/// d'une tâche, connecté à l'API via [TasksProvider].
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  /// Tâche à modifier ; `null` = création.
  final TaskItem? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _date;
  late TimeOfDay _time;
  Category? _category;
  bool _saving = false;
  String? _titleError;
  String? _formError;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');

    if (task != null) {
      final parts = task.date.split('-');
      _date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final timeParts = task.time.split(':');
      _time = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      _category = task.category;
    } else {
      _date = DateTime.now();
      _time = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Le titre est obligatoire.');
      return;
    }
    final category = _category;
    if (category == null) {
      setState(() => _formError = 'Choisissez une catégorie.');
      return;
    }

    setState(() {
      _saving = true;
      _titleError = null;
      _formError = null;
    });

    final state = context.read<TasksProvider>();
    try {
      if (_isEdit) {
        await state.updateTask(
          widget.task!,
          title: title,
          description: _description.text.trim(),
          date: FlowDates.apiDate(_date),
          time: FlowDates.timeParam(_time),
          categoryId: category.id,
        );
      } else {
        await state.createTask(
          title: title,
          description: _description.text.trim(),
          date: FlowDates.apiDate(_date),
          time: FlowDates.timeParam(_time),
          categoryId: category.id,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        final titleError = e.fieldErrors['title'];
        _titleError = titleError;
        _formError = titleError == null ? e.message : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = 'Impossible de contacter le serveur.';
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor:
            Theme.of(dialogContext).dialogTheme.backgroundColor ??
            Theme.of(dialogContext).cardColor,
        title: const Text('Supprimer la tâche ?'),
        content: Text(
          '« ${widget.task!.title} » sera définitivement supprimée.',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Supprimer',
              style: TextStyle(color: AppColors.personal),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final state = context.read<TasksProvider>();
    try {
      await state.deleteTask(widget.task!);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suppression impossible.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final categories = context.watch<TasksProvider>().categories;

    // Catégorie par défaut : « work » si présente.
    _category ??= categories.isNotEmpty
        ? categories.firstWhere(
            (c) => c.id == 'work',
            orElse: () => categories.first,
          )
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // En-tête avec retour.
          Padding(
            padding: EdgeInsets.fromLTRB(8, topPadding + 6, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppColors.dark,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _isEdit ? 'Edit task' : 'New task',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // ----------------------------------------------------------
                // Titre (obligatoire)
                // ----------------------------------------------------------
                const _FieldLabel('Title *'),
                TextField(
                  controller: _title,
                  // Colonne `title varchar(200)` : au-delà, PostgREST
                  // renvoie 400 (`22001`) — on bloque la saisie.
                  maxLength: 200,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  onChanged: (_) {
                    if (_titleError != null) {
                      setState(() => _titleError = null);
                    }
                  },
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ex. Meeting with Shakib',
                    hintStyle: const TextStyle(
                      color: AppColors.placeholderText,
                      fontSize: 14,
                    ),
                    errorText: _titleError,
                    filled: true,
                    fillColor: AppColors.field,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.personal),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.personal),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ----------------------------------------------------------
                // Description
                // ----------------------------------------------------------
                const _FieldLabel('Description'),
                TextField(
                  controller: _description,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Short description',
                    hintStyle: const TextStyle(
                      color: AppColors.placeholderText,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.field,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ----------------------------------------------------------
                // Date + heure (sélecteurs natifs)
                // ----------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Date'),
                          _PickerField(
                            value: FlowDates.displayDate(_date),
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Time'),
                          _PickerField(
                            value: _time.format(context),
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ----------------------------------------------------------
                // Catégories (F7)
                // ----------------------------------------------------------
                const _FieldLabel('Category'),
                const SizedBox(height: 10),
                if (categories.isEmpty)
                  const Text(
                    'Chargement des catégories…',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final category in categories)
                        GestureDetector(
                          onTap: () => setState(() => _category = category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: _category?.id == category.id
                                  ? AppColors.dark
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    color: _category?.id == category.id
                                        ? Colors.white
                                        : AppColors.muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _formError!,
                    style: const TextStyle(
                      color: AppColors.personal,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 34),

                // ----------------------------------------------------------
                // Enregistrer
                // ----------------------------------------------------------
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Enregistrer' : 'Créer',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Annuler.
                SizedBox(
                  height: 52,
                  child: TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // ----------------------------------------------------------
                // Suppression (F5) — seulement en modification
                // ----------------------------------------------------------
                if (_isEdit) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.personal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Supprimer la tâche',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Champ date / heure cliquable (ouvre le sélecteur natif).
class _PickerField extends StatelessWidget {
  const _PickerField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
