import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../services/shift_schedule_service.dart';

/// Proposal Section 8 Evaluation Metrics Card
/// Directly measures and visualizes the 4 expected outcomes from the proposal:
/// 1. >= 60% prep tasks completed in quiet hours before peak hours
/// 2. >= 20% reduction in delayed tasks (snooze/reschedule rate vs on-time completion)
/// 3. Reduction in task arrangement time & total operational hours
class ProposalMetricsCard extends StatelessWidget {
  final List<TaskModel> allTasks;

  const ProposalMetricsCard({
    super.key,
    required this.allTasks,
  });

  @override
  Widget build(BuildContext context) {
    final shiftService = ShiftScheduleService.instance;

    // Prep tasks during quiet hours
    final quietTasks = allTasks.where((t) => shiftService.isTaskInQuietHours(t)).toList();
    final quietCompleted = quietTasks.where((t) => t.isCompleted).length;
    final quietRate = quietTasks.isEmpty
        ? 0.0
        : (quietCompleted / quietTasks.length);

    // On-time completion (never snoozed)
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();
    final onTimeTasks = completedTasks.where((t) => t.snoozeCount == 0).length;
    final punctualityRate = completedTasks.isEmpty
        ? 0.0
        : (onTimeTasks / completedTasks.length);

    final totalMinutes = allTasks
        .where((t) => t.isCompleted)
        .fold<int>(0, (sum, t) => sum + t.durationMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    // Target checks
    final quietTargetMet = quietRate >= 0.60;
    final onTimeTargetMet = punctualityRate >= 0.80; // Represents <= 20% delays

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with proposal badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.assessment_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('proposal_metrics_title'),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.tr('proposal_target_badge'),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric 1: Quiet Hours Prep Tasks (Proposal Target: >= 60%)
          _buildMetricRow(
            context: context,
            icon: Icons.soup_kitchen_outlined,
            title: context.tr('metric_quiet_prep_title'),
            subtitle: context.tr('metric_quiet_prep_desc'),
            percentage: quietRate,
            targetText: 'Target: ≥ 60%',
            isTargetMet: quietTargetMet,
            fractionText: '$quietCompleted/${quietTasks.length}',
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),

          // Metric 2: On-time rate / Delay reduction (Proposal Target: >= 20% delay reduction)
          _buildMetricRow(
            context: context,
            icon: Icons.timer_outlined,
            title: context.tr('metric_delay_reduction_title'),
            subtitle: context.tr('metric_delay_reduction_desc'),
            percentage: punctualityRate,
            targetText: 'Target: ≥ 80% Tepat Waktu',
            isTargetMet: onTimeTargetMet,
            fractionText: '$onTimeTasks/${completedTasks.length}',
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),

          // Metric 3: Total productive working time completed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('metric_productive_hours_title'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        context.tr('metric_productive_hours_desc'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalHours ${context.tr('hours_short')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required double percentage,
    required String targetText,
    required bool isTargetMet,
    required String fractionText,
  }) {
    final pctInt = (percentage * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pctInt% ($fractionText)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isTargetMet ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: isTargetMet ? AppColors.secondary : AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              targetText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isTargetMet ? AppColors.secondaryDark : AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              isTargetMet ? AppColors.secondary : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
