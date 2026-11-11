import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/priority_quadrant.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/priority_matrix_selector.dart';

/// Screen 2: Task Input & Edit (Full CRUD)
/// Supports Creating a new task or Updating an existing task.
class TaskInputScreen extends StatefulWidget {
  final TaskModel? taskToEdit;

  const TaskInputScreen({super.key, this.taskToEdit});

  @override
  State<TaskInputScreen> createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;

  late TimeOfDay _selectedTime;
  late PriorityQuadrant _selectedQuadrant;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final task = widget.taskToEdit!;
      _titleController = TextEditingController(text: task.title);
      _durationController =
          TextEditingController(text: task.durationMinutes.toString());
      _selectedTime = task.timeOfDay;
      _selectedQuadrant = task.priorityQuadrant;
    } else {
      _titleController = TextEditingController();
      _durationController = TextEditingController(text: '30');
      _selectedTime = const TimeOfDay(hour: 9, minute: 30);
      _selectedQuadrant = PriorityQuadrant.doFirst;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveOrUpdateTask() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    if (isEditing) {
      // Full CRUD: Update existing task
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        targetTime: timeStr,
        durationMinutes: duration,
        priorityQuadrant: _selectedQuadrant,
      );

      await taskProvider.updateTask(updatedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedTask.title} berhasil diperbarui.'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      // Full CRUD: Create new task
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final newTask = TaskModel(
        title: _titleController.text.trim(),
        targetTime: timeStr,
        durationMinutes: duration,
        assignee: null, // "Ditugaskan Kepada" option removed per user request
        priorityQuadrant: _selectedQuadrant,
        createdAt: todayStr,
      );

      await taskProvider.addTask(newTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newTask.title} disimpan.'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete_task')),
        content: Text(context.tr('delete_task_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.tr('confirm'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (widget.taskToEdit?.id != null) {
        await taskProvider.deleteTask(widget.taskToEdit!.id!);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing
              ? context.tr('edit_screen_title')
              : context.tr('input_screen_title'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
              tooltip: context.tr('delete_task'),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Task Name
              Text(
                context.tr('task_name_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: context.tr('task_name_hint'),
                  prefixIcon:
                      const Icon(Icons.edit_note, color: AppColors.textSecondary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr('error_title_empty');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Side-by-side row: Target Time & Duration
              Row(
                children: [
                  // Target Time Picker Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('target_time_label'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.divider, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  timeString,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Duration (Numeric) Field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('duration_label'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '30',
                            suffixText: context.tr('minutes_short'),
                            prefixIcon: const Icon(Icons.timer_outlined,
                                color: AppColors.textSecondary),
                          ),
                          validator: (val) {
                            final parsed = int.tryParse(val ?? '');
                            if (parsed == null || parsed <= 0) {
                              return context.tr('error_duration_invalid');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Priority Matrix (2x2 Grid)
              Text(
                context.tr('priority_matrix_title'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              PriorityMatrixSelector(
                selectedQuadrant: _selectedQuadrant,
                onQuadrantSelected: (q) {
                  setState(() {
                    _selectedQuadrant = q;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Primary CTA Button (Full-width dark button at bottom)
              ElevatedButton(
                onPressed: _saveOrUpdateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEditing
                      ? context.tr('update_task_cta')
                      : context.tr('save_task_cta'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
