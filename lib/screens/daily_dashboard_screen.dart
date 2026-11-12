import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../providers/locale_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'settings_screen.dart';
import 'task_input_screen.dart';
import 'task_reminder_modal.dart';

/// Screen 1: Daily Dashboard (Tab 1 - "Hari Ini" / "Today")
class DailyDashboardScreen extends StatelessWidget {
  const DailyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Current formatted date based on locale
    final now = DateTime.now();
    final localeCode = localeProvider.isIndonesian ? 'id_ID' : 'en_US';
    final formattedDate = DateFormat('EEEE, d MMMM', localeCode).format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => taskProvider.loadTasks(),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Date & App Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'AturAjah',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      // Actions: Language Toggle & Settings
                      Row(
                        children: [
                          // Language Switcher Badge (ID | EN)
                          InkWell(
                            onTap: () => localeProvider.toggleLocale(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.divider, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: localeProvider.isIndonesian
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: localeProvider.isIndonesian
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '|',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'EN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: !localeProvider.isIndonesian
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: !localeProvider.isIndonesian
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Settings Button (Replaces DF Circle)
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                            tooltip: context.tr('settings_title'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Daily Summary & Checklist Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('today_tasks'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),

                      // Progress pill badge (e.g. 1/4 selesai / 1/4 done)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: taskProvider.completedCount ==
                                      taskProvider.totalCount &&
                                  taskProvider.totalCount > 0
                              ? AppColors.secondaryLight
                              : AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${taskProvider.progressFraction} ${context.tr('done')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: taskProvider.completedCount ==
                                        taskProvider.totalCount &&
                                    taskProvider.totalCount > 0
                                ? AppColors.secondaryDark
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Task Checklist List
              if (taskProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                )
              else if (taskProvider.tasks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('no_tasks_today'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = taskProvider.tasks[index];
                        return TaskCard(
                          task: task,
                          onToggleDone: (_) {
                            if (task.id != null) {
                              taskProvider.toggleTaskDone(task.id!);
                            }
                          },
                          onTap: () {
                            // Tap card to inspect or trigger reminder preview
                            _showTaskDetails(context, task);
                          },
                          onEdit: () {
                            // Full CRUD: Edit task
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TaskInputScreen(taskToEdit: task),
                              ),
                            );
                          },
                          onDelete: () {
                            if (task.id != null) {
                              taskProvider.deleteTask(task.id!);
                            }
                          },
                        );
                      },
                      childCount: taskProvider.tasks.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaskInputScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${task.targetTime} • ${task.durationMinutes} mnt'),
            const SizedBox(height: 6),
            Text('Prioritas: Q${task.priorityQuadrant.value}'),
            if (task.snoozeCount > 0) ...[
              const SizedBox(height: 6),
              Text('Jumlah Penundaan (Snooze): ${task.snoozeCount}x'),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskInputScreen(taskToEdit: task),
                ),
              );
            },
            label: const Text('Edit Tugas'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              TaskReminderModal.show(context, task);
            },
            child: const Text('Buka Modal Pengingat'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }
}
