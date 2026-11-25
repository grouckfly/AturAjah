import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/task_provider.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'daily_dashboard_screen.dart';
import 'schedule_timeline_screen.dart';
import 'task_reminder_modal.dart';
import 'weekly_overview_screen.dart';

/// Main navigation shell managing the 2-tab layout.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DailyDashboardScreen(),
    ScheduleTimelineScreen(),
    WeeklyOverviewScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingReminder();
      _checkAutoUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-register alarms whenever the app comes back to the foreground: some
    // devices drop scheduled alarms after a reboot or aggressive battery saver.
    if (state == AppLifecycleState.resumed) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    }
  }

  Future<void> _checkAutoUpdate() async {
    final updateInfo = await UpdateService.instance.checkForUpdate();
    if (updateInfo != null && mounted) {
      UpdateDialog.show(context, updateInfo);
    }
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 640;

    final Widget appShell = Scaffold(
      backgroundColor: AppColors.background,
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
            BottomNavigationBarItem(
              icon: const Icon(Icons.insights_outlined),
              activeIcon: const Icon(Icons.insights),
              label: context.tr('tab_weekly'),
            ),
          ],
        ),
      ),
    );

    if (isWide) {
      return Container(
        color: const Color(0xFFF2EFE9), // Desktop canvas backdrop
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRect(child: appShell),
          ),
        ),
      );
    }

    return appShell;
  }
}
