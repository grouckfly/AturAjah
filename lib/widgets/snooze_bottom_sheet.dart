import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

/// Modal bottom sheet for quick snooze options (+5m, +10m, +15m) or custom reschedule.
class SnoozeBottomSheet extends StatelessWidget {
  final TaskModel task;

  const SnoozeBottomSheet({
    super.key,
    required this.task,
  });

  static Future<void> show(BuildContext context, TaskModel task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SnoozeBottomSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Row(
              children: [
                const Icon(
                  Icons.snooze,
                  color: AppColors.snoozeOrange,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('snooze_sheet_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              task.title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Preset Snooze Buttons (+5, +10, +15 min)
            Row(
              children: [
                Expanded(
                  child: _buildSnoozeButton(
                    context: context,
                    label: context.tr('snooze_5m'),
                    minutes: 5,
                    onTap: () async {
                      if (task.id != null) {
                        await taskProvider.snoozeTask(task.id!, 5);
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('snooze_success', ['5'])),
                            backgroundColor: AppColors.snoozeOrange,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSnoozeButton(
                    context: context,
                    label: context.tr('snooze_10m'),
                    minutes: 10,
                    onTap: () async {
                      if (task.id != null) {
                        await taskProvider.snoozeTask(task.id!, 10);
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('snooze_success', ['10'])),
                            backgroundColor: AppColors.snoozeOrange,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSnoozeButton(
                    context: context,
                    label: context.tr('snooze_15m'),
                    minutes: 15,
                    onTap: () async {
                      if (task.id != null) {
                        await taskProvider.snoozeTask(task.id!, 15);
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('snooze_success', ['15'])),
                            backgroundColor: AppColors.snoozeOrange,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pick New Target Time
            OutlinedButton.icon(
              onPressed: () async {
                final tod = await showTimePicker(
                  context: context,
                  initialTime: task.timeOfDay,
                );

                if (tod != null && context.mounted) {
                  final timeStr =
                      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
                  if (task.id != null) {
                    await taskProvider.rescheduleTask(task.id!, timeStr);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('reschedule_success', [timeStr])),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.schedule, size: 18),
              label: Text(context.tr('pick_new_time')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.divider, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeButton({
    required BuildContext context,
    required String label,
    required int minutes,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFF3E0),
        foregroundColor: AppColors.snoozeOrange,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFFCC80), width: 1.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
