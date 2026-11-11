import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/task_provider.dart';
import 'daily_dashboard_screen.dart';
import 'schedule_timeline_screen.dart';
import 'task_reminder_modal.dart';

/// Main navigation shell managing the 2-tab layout.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DailyDashboardScreen(),
    ScheduleTimelineScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingReminder();
    });
  }

  void _checkPendingReminder() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (taskProvider.activeReminderTask != null) {
      TaskReminderModal.show(context, taskProvider.activeReminderTask!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to active reminder updates if notification clicked while app running
    final taskProvider = Provider.of<TaskProvider>(context);
    if (taskProvider.activeReminderTask != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final task = taskProvider.activeReminderTask;
        if (task != null && mounted) {
          taskProvider.setActiveReminderTask(null);
          TaskReminderModal.show(context, task);
        }
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.check_circle_outline),
              activeIcon: const Icon(Icons.check_circle),
              label: context.tr('tab_today'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.view_timeline_outlined),
              activeIcon: const Icon(Icons.view_timeline),
              label: context.tr('tab_schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
