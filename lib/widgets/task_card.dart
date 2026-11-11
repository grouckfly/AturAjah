import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';

/// Task Card item for dashboard and schedule list.
/// Clean, touch-friendly, high-contrast, with no emoji.
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<bool?> onToggleDone;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleDone,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;
    final mntUnit = context.tr('minutes_short');

    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (_) {
        onDelete?.call();
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDone ? AppColors.secondaryLight.withValues(alpha: 0.4) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone ? AppColors.secondaryBorder : AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox with enlarged hit area
              SizedBox(
                height: 36,
                width: 36,
                child: Checkbox(
                  value: isDone,
                  activeColor: AppColors.secondary,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: const BorderSide(color: AppColors.textMuted, width: 1.5),
                  onChanged: onToggleDone,
                ),
              ),
              const SizedBox(width: 8),

              // Title & metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Time, duration, assignee tags
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: isDone ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.targetTime} • ${task.durationMinutes} $mntUnit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDone ? AppColors.textMuted : AppColors.textSecondary,
                          ),
                        ),

                        // Snooze indicator if task was snoozed
                        if (task.snoozeCount > 0 && !isDone) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFFFB74D),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${task.snoozeCount}x snooze',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.snoozeOrange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Edit button for Full CRUD
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  onPressed: onEdit,
                  splashRadius: 18,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),

              const SizedBox(width: 4),

              // Color-coded priority dot on the right
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.secondary
                      : task.priorityQuadrant.indicatorColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
