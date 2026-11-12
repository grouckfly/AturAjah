import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/shift_schedule_service.dart';
import '../services/vibration_service.dart';
import '../widgets/snooze_bottom_sheet.dart';

/// Screen 4: Task Reminder Modal (Full-Screen Alert Overlay)
/// Triggered when scheduled task alarm fires or tapped from notification.
class TaskReminderModal extends StatelessWidget {
  final TaskModel task;

  const TaskReminderModal({
    super.key,
    required this.task,
  });

  static Future<void> show(BuildContext context, TaskModel task) {
    final durationSec = SettingsService.instance.alarmDurationSeconds;
    VibrationService.startAlarmVibration(durationSeconds: durationSec);
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'TaskReminder',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => TaskReminderModal(task: task),
    ).then((_) {
      VibrationService.cancel();
      if (task.id != null) {
        NotificationService.instance.cancelTaskAlarm(task.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final shiftService = ShiftScheduleService.instance;
    final isQuiet = shiftService.isTaskInQuietHours(task);
    final isPeak = shiftService.isTaskInPeakHours(task);

    String shiftNote;
    if (isQuiet) {
      shiftNote = context.tr('reminder_quiet_note', [task.durationMinutes.toString()]);
    } else if (isPeak) {
      shiftNote = context.tr('reminder_peak_note');
    } else {
      shiftNote = context.tr('reminder_standard_note', [task.durationMinutes.toString()]);
    }

    final priorityLabel = '${task.targetTime} • ${context.tr('q${task.priorityQuadrant.value}_title').toUpperCase()}';

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.65), // Focus dim overlay
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: AppColors.surface, // Clean Light Theme Card
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: task.priorityQuadrant.borderColor,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top close icon
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Large Timer Beacon Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: task.priorityQuadrant.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.priorityQuadrant.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.alarm_on,
                    size: 42,
                    color: task.priorityQuadrant.indicatorColor,
                  ),
                ),
                const SizedBox(height: 18),

                // Target Time + Priority Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.priorityQuadrant.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: task.priorityQuadrant.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: task.priorityQuadrant.indicatorColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Large Task Title
                Text(
                  task.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Shift Window Note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isPeak ? const Color(0xFFFFEBEE) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPeak ? Colors.red.shade300 : AppColors.divider,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPeak ? Icons.warning_amber_rounded : Icons.info_outline,
                        size: 18,
                        color: isPeak ? Colors.red : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shiftNote,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isPeak ? Colors.red.shade900 : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Snooze count if snoozed
                if (task.snoozeCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.tr('snoozed_times_label', [task.snoozeCount.toString()]),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.snoozeOrange,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Decision Node Action Buttons (Touch-friendly, >= 50px height)
                // 1. Green Button: Mark as Done
                ElevatedButton.icon(
                  onPressed: () async {
                    if (task.id != null) {
                      await taskProvider.toggleTaskDone(task.id!);
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tugas "${task.title}" ditandai selesai.'),
                          backgroundColor: AppColors.doneGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(context.tr('mark_done_cta')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.doneGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Orange Button: Snooze or Reschedule
                ElevatedButton.icon(
                  onPressed: () {
                    // Close the reminder modal first, then show snooze bottom sheet
                    Navigator.of(context).pop();
                    SnoozeBottomSheet.show(context, task);
                  },
                  icon: const Icon(Icons.snooze, size: 22),
                  label: Text(context.tr('snooze_reschedule_cta')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF3E0),
                    foregroundColor: AppColors.snoozeOrange,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                        color: Color(0xFFFFB74D),
                        width: 1.5,
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
