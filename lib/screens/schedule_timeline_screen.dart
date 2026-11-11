import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/priority_quadrant.dart';
import '../models/task_model.dart';
import '../providers/locale_provider.dart';
import '../providers/task_provider.dart';
import '../services/shift_schedule_service.dart';
import 'task_input_screen.dart';
import 'task_reminder_modal.dart';

/// Screen 3: Schedule by Category (Tab 2 - "Jadwal" / "Schedule")
/// Shows tasks categorized by Eisenhower Priority Quadrants, sorted by time.
class ScheduleTimelineScreen extends StatelessWidget {
  const ScheduleTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final shiftService = ShiftScheduleService.instance;

    final totalDurationStr = shiftService.calculateTotalDuration(
      taskProvider.tasks,
      isIndonesian: localeProvider.isIndonesian,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('schedule_screen_title')),
        actions: [
          // Total planned duration badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 14, color: AppColors.primaryDark),
                const SizedBox(width: 4),
                Text(
                  '$totalDurationStr ${context.tr('planned_duration')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // Category 1: Kerjakan Dahulu (Do First)
            _buildCategoryBlock(
              context: context,
              quadrant: PriorityQuadrant.doFirst,
              titleKey: 'q1_title',
              subtitleKey: 'q1_subtitle',
              tasks: taskProvider.tasks
                  .where((t) => t.priorityQuadrant == PriorityQuadrant.doFirst)
                  .toList(),
              taskProvider: taskProvider,
            ),

            const SizedBox(height: 14),

            // Category 2: Jadwalkan (Schedule)
            _buildCategoryBlock(
              context: context,
              quadrant: PriorityQuadrant.schedule,
              titleKey: 'q2_title',
              subtitleKey: 'q2_subtitle',
              tasks: taskProvider.tasks
                  .where((t) => t.priorityQuadrant == PriorityQuadrant.schedule)
                  .toList(),
              taskProvider: taskProvider,
            ),

            const SizedBox(height: 14),

            // Category 3: Delegasikan (Delegate)
            _buildCategoryBlock(
              context: context,
              quadrant: PriorityQuadrant.delegate,
              titleKey: 'q3_title',
              subtitleKey: 'q3_subtitle',
              tasks: taskProvider.tasks
                  .where((t) => t.priorityQuadrant == PriorityQuadrant.delegate)
                  .toList(),
              taskProvider: taskProvider,
            ),

            const SizedBox(height: 14),

            // Category 4: Nanti (Later)
            _buildCategoryBlock(
              context: context,
              quadrant: PriorityQuadrant.later,
              titleKey: 'q4_title',
              subtitleKey: 'q4_subtitle',
              tasks: taskProvider.tasks
                  .where((t) => t.priorityQuadrant == PriorityQuadrant.later)
                  .toList(),
              taskProvider: taskProvider,
            ),
          ],
        ),
      ),
    );
  }

  /// Category block container with header and nested timeline items
  Widget _buildCategoryBlock({
    required BuildContext context,
    required PriorityQuadrant quadrant,
    required String titleKey,
    required String subtitleKey,
    required List<TaskModel> tasks,
    required TaskProvider taskProvider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: quadrant.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quadrant.borderColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: quadrant.indicatorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(titleKey),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          context.tr(subtitleKey),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: quadrant.indicatorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: quadrant.borderColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${tasks.length} tugas',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: quadrant.indicatorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: quadrant.borderColor.withValues(alpha: 0.2),
            height: 1,
          ),

          // Nested task items
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Text(
                  context.tr('no_tasks_in_block'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: tasks
                    .map((task) =>
                        _buildTimelineItem(context, task, taskProvider, quadrant))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Reusable timeline item
  Widget _buildTimelineItem(
    BuildContext context,
    TaskModel task,
    TaskProvider taskProvider,
    PriorityQuadrant quadrant,
  ) {
    final isDone = task.isCompleted;

    return InkWell(
      onTap: () {
        // Tap to open reminder modal
        TaskReminderModal.show(context, task);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Target Time on the left (e.g. 09:15)
            SizedBox(
              width: 48,
              child: Text(
                task.targetTime,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
            ),

            // Completion toggle checkbox
            InkWell(
              onTap: () {
                if (task.id != null) {
                  taskProvider.toggleTaskDone(task.id!);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDone ? AppColors.secondary : AppColors.textMuted,
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),

            // Task Name + duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color:
                          isDone ? AppColors.textMuted : AppColors.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${task.durationMinutes} ${context.tr('minutes_short')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 17, color: AppColors.textSecondary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskInputScreen(taskToEdit: task),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
