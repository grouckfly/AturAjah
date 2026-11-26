import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/priority_quadrant.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/shift_schedule_service.dart';
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
  late final TextEditingController _assigneeController;

  late TimeOfDay _selectedTime;
  late PriorityQuadrant _selectedQuadrant;
  bool _makeRecurring = false;

  final ShiftScheduleService _shiftService = ShiftScheduleService.instance;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final task = widget.taskToEdit!;
      _titleController = TextEditingController(text: task.title);
      _durationController =
          TextEditingController(text: task.durationMinutes.toString());
      _assigneeController = TextEditingController(text: task.assignee ?? '');
      _selectedTime = task.timeOfDay;
      _selectedQuadrant = task.priorityQuadrant;
    } else {
      _titleController = TextEditingController();
      _durationController = TextEditingController(text: '30');
      _assigneeController = TextEditingController();
      _selectedTime = const TimeOfDay(hour: 9, minute: 30);
      _selectedQuadrant = PriorityQuadrant.doFirst;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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

  /// Proposal feature 3: warn when prep work is planned inside the rush window
  /// and offer a one-tap move to the quiet (prep) window.
  void _applyQuietWindowSuggestion() {
    setState(() {
      _selectedTime = _shiftService.quietStart;
    });
  }

  Future<void> _saveOrUpdateTask() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;
    final timeStr = _formatTime(_selectedTime);
    final assignee = _assigneeController.text.trim();

    if (isEditing) {
      // Full CRUD: Update existing task
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        targetTime: timeStr,
        durationMinutes: duration,
        priorityQuadrant: _selectedQuadrant,
        assignee: assignee.isEmpty ? null : assignee,
        clearAssignee: assignee.isEmpty,
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
        assignee: assignee.isEmpty ? null : assignee,
        priorityQuadrant: _selectedQuadrant,
        createdAt: todayStr,
      );

      await taskProvider.addTask(newTask, makeRecurring: _makeRecurring);

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
    final timeString = _formatTime(_selectedTime);
    final inPeakWindow = _shiftService.isTimeInPeakWindow(_selectedTime);
    final quietWindow = _shiftService.formatWindow(
      _shiftService.quietStart,
      _shiftService.quietEnd,
    );
    final suggestedTime = _formatTime(_shiftService.quietStart);

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
              const SizedBox(height: 18),

              // Quiet-hour suggestion (proposal feature 3)
              if (inPeakWindow) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              size: 18, color: AppColors.snoozeOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('suggestion_peak_title'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.snoozeOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('suggestion_peak_body', [quietWindow]),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _applyQuietWindowSuggestion,
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          context.tr('suggestion_move_cta', [suggestedTime]),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.snoozeOrange,
                          side: const BorderSide(
                              color: AppColors.snoozeOrange, width: 1.2),
                          minimumSize: const Size.fromHeight(42),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Assignee (proposal feature 4: tasks can be assigned to staff)
              Text(
                context.tr('assignee_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _assigneeController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: context.tr('assignee_hint'),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 18),

              // Recurring template (proposal: repetitive daily prep work)
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('repeat_daily_label'),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              context.tr('repeat_daily_desc'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _makeRecurring,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _makeRecurring = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              if (!isEditing) const SizedBox(height: 22),

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

              const SizedBox(height: 28),

              // Primary CTA Button (Full-width dark button at bottom)
              ElevatedButton.icon(
                onPressed: _saveOrUpdateTask,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  isEditing
                      ? context.tr('update_task_cta')
                      : context.tr('save_task_cta'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
