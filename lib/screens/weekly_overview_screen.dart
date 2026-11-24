import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../providers/locale_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/proposal_metrics_card.dart';

/// Weekly overview (proposal objective 4: "a clear overview of daily and
/// weekly tasks", plus the evaluation metrics of section 8).
class WeeklyOverviewScreen extends StatefulWidget {
  const WeeklyOverviewScreen({super.key});

  @override
  State<WeeklyOverviewScreen> createState() => _WeeklyOverviewScreenState();
}

class _WeeklyOverviewScreenState extends State<WeeklyOverviewScreen> {
  late Future<Map<String, List<TaskModel>>> _weeklyFuture;

  @override
  void initState() {
    super.initState();
    _weeklyFuture =
        Provider.of<TaskProvider>(context, listen: false).loadWeeklyTasks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registers a dependency on TaskProvider (listening) so the weekly numbers
    // refresh whenever a task is completed, snoozed or deleted.
    final provider = Provider.of<TaskProvider>(context);
    _weeklyFuture = provider.loadWeeklyTasks();
  }

  Future<void> _reload() async {
    final future =
        Provider.of<TaskProvider>(context, listen: false).loadWeeklyTasks();
    setState(() {
      _weeklyFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localeCode = localeProvider.isIndonesian ? 'id_ID' : 'en_US';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('weekly_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('weekly_subtitle'),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, List<TaskModel>>>(
          future: _weeklyFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final byDay = snapshot.data!;
            final entries = byDay.entries.toList();
            final allTasks = byDay.values.expand((tasks) => tasks).toList();
            final totalTasks = allTasks.length;
            final completed = allTasks.where((t) => t.isCompleted).length;
            final snoozed = allTasks.where((t) => t.snoozeCount > 0).length;

            return RefreshIndicator(
              onRefresh: _reload,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    context.tr('weekly_subtitle'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: context.tr('weekly_total_tasks'),
                          value: '$totalTasks',
                          color: AppColors.primary,
                          icon: Icons.list_alt,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: context.tr('weekly_completed'),
                          value: '$completed',
                          color: AppColors.secondary,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: context.tr('weekly_snoozed'),
                          value: '$snoozed',
                          color: AppColors.snoozeOrange,
                          icon: Icons.snooze,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Proposal Section 8 Evaluation Metrics Card
                  ProposalMetricsCard(allTasks: allTasks),
                  const SizedBox(height: 18),

                  ...entries.reversed.map((entry) {
                    final date = DateTime.parse(entry.key);
                    final tasks = entry.value;
                    final done = tasks.where((t) => t.isCompleted).length;
                    final isToday = _isToday(date);
                    final dayLabel =
                        DateFormat('EEE, d MMM', localeCode).format(date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday
                              ? AppColors.primaryLight
                              : AppColors.divider,
                          width: isToday ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: tasks.isEmpty
                                  ? AppColors.background
                                  : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: tasks.isEmpty
                                      ? AppColors.textMuted
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dayLabel,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${context.tr('weekly_today')}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tasks.isEmpty
                                      ? context.tr('weekly_no_tasks')
                                      : '${context.tr('weekly_completed')}: $done/${tasks.length}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tasks.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: done == tasks.length
                                    ? AppColors.secondaryLight
                                    : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$done/${tasks.length}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: done == tasks.length
                                      ? AppColors.secondaryDark
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
