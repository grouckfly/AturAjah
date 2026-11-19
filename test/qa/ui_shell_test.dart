import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/daily_dashboard_screen.dart';
import 'package:dapur_flow/screens/main_navigation_screen.dart';
import 'package:dapur_flow/screens/task_reminder_modal.dart';
import 'package:dapur_flow/services/shift_schedule_service.dart';
import 'package:dapur_flow/widgets/live_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

/// Shell-level behaviour: the three tabs, the automatic reminder modal and the
/// live phase banner driven by the user's own operating hours.
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
  });

  testWidgets('main shell exposes the three tabs and opens the weekly view',
      (tester) async {
    final provider = TaskProvider();
    await provider.loadTasks();

    await pumpTestApp(tester, home: const MainNavigationScreen(), provider: provider);

    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Jadwal'), findsOneWidget);
    expect(find.text('Mingguan'), findsOneWidget);
    expect(find.text('Tugas Hari Ini'), findsOneWidget);

    await tester.tap(find.text('Mingguan'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Mingguan'), findsOneWidget);
    expect(find.text('Total tugas'), findsOneWidget);
  });

  testWidgets('a due task opens the reminder modal automatically',
      (tester) async {
    final provider = TaskProvider();
    await provider.loadTasks();
    await provider.addTask(sampleTask(title: 'Buka warung', targetTime: '09:00'));

    await pumpTestApp(tester, home: const MainNavigationScreen(), provider: provider);

    // Simulate the in-app reminder timer firing.
    provider.setActiveReminderTask(provider.tasks.single);
    await tester.pumpAndSettle();

    expect(find.byType(TaskReminderModal), findsOneWidget);
    expect(find.text('Tandai Selesai'), findsOneWidget);
    expect(find.text('Tunda / Jadwal Ulang'), findsOneWidget);
  });

  testWidgets('live banner shows the quiet window from the user settings',
      (tester) async {
    // A quiet window that covers essentially the whole day (and still satisfies
    // quietEnd <= peakStart), so the banner is deterministic.
    final saved = await ShiftScheduleService.instance.updateWindows(
      quietStart: const TimeOfDay(hour: 0, minute: 0),
      quietEnd: const TimeOfDay(hour: 23, minute: 58),
      peakStart: const TimeOfDay(hour: 23, minute: 58),
      peakEnd: const TimeOfDay(hour: 23, minute: 59),
    );
    expect(saved, isTrue);

    final provider = TaskProvider();
    await provider.loadTasks();

    await pumpTestApp(tester, home: const DailyDashboardScreen(), provider: provider);

    expect(find.byType(LiveStatusBanner), findsOneWidget);
    expect(find.textContaining('Jam Tenang (Persiapan) • 00:00-23:58'),
        findsOneWidget);
  });

  testWidgets('setting an invalid window order is rejected by the service',
      (tester) async {
    final accepted = await ShiftScheduleService.instance.updateWindows(
      quietStart: const TimeOfDay(hour: 18, minute: 0),
      quietEnd: const TimeOfDay(hour: 19, minute: 0),
      // Peak starts before quiet ends -> invalid.
      peakStart: const TimeOfDay(hour: 18, minute: 30),
      peakEnd: const TimeOfDay(hour: 20, minute: 0),
    );

    expect(accepted, isFalse);
    expect(ShiftScheduleService.instance.peakStart,
        const TimeOfDay(hour: 12, minute: 0));
  });
}
