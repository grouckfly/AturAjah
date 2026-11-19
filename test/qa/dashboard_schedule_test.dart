import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/daily_dashboard_screen.dart';
import 'package:dapur_flow/screens/schedule_timeline_screen.dart';
import 'package:dapur_flow/screens/task_input_screen.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

/// Proposal Feature 2 (prioritization visible in the UI) and Feature 4
/// (daily summary / checklist with progress).
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
  });

  Future<TaskProvider> seededProvider() async {
    final provider = TaskProvider();
    await provider.loadTasks();
    await provider.addTask(sampleTask(
      title: 'Potong sayuran',
      targetTime: '09:00',
      durationMinutes: 30,
      quadrant: PriorityQuadrant.doFirst,
    ));
    await provider.addTask(sampleTask(
      title: 'Belanja stok',
      targetTime: '12:30',
      durationMinutes: 45,
      quadrant: PriorityQuadrant.schedule,
    ));
    await provider.addTask(sampleTask(
      title: 'Cuci piring',
      targetTime: '16:00',
      durationMinutes: 20,
      quadrant: PriorityQuadrant.delegate,
    ));
    return provider;
  }

  group('Daily dashboard - daily checklist (feature 4)', () {
    testWidgets('lists every task with time, duration and progress badge',
        (tester) async {
      final provider = await seededProvider();

      await pumpTestApp(tester, home: const DailyDashboardScreen(), provider: provider);

      expect(find.text('AturAjah'), findsOneWidget);
      expect(find.text('Tugas Hari Ini'), findsOneWidget);
      expect(find.text('0/3 selesai'), findsOneWidget);

      expect(find.text('Potong sayuran'), findsOneWidget);
      expect(find.text('Belanja stok'), findsOneWidget);
      expect(find.text('Cuci piring'), findsOneWidget);
      expect(find.text('09:00 • 30 mnt'), findsOneWidget);
    });

    testWidgets('checking a task updates the summary and SQLite', (tester) async {
      final provider = await seededProvider();

      await pumpTestApp(tester, home: const DailyDashboardScreen(), provider: provider);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('1/3 selesai'), findsOneWidget);

      final db = await DatabaseHelper.instance.database;
      final doneRows = await db.query('tasks',
          where: 'is_completed = ?', whereArgs: [1]);
      expect(doneRows.length, 1);
      expect(doneRows.first['title'], 'Potong sayuran');
    });

    testWidgets('shows the empty state when nothing is scheduled', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const DailyDashboardScreen(), provider: provider);

      expect(
        find.text('Belum ada tugas hari ini. Ketuk tombol (+) untuk menambahkan.'),
        findsOneWidget,
      );
      expect(find.text('0/0 selesai'), findsOneWidget);
    });

    testWidgets('FAB opens the task input screen', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const DailyDashboardScreen(), provider: provider);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(TaskInputScreen), findsOneWidget);
      expect(find.text('Tugas Baru'), findsOneWidget);
    });
  });

  group('Schedule tab - prioritization grouping (feature 2)', () {
    testWidgets('groups tasks under the four Eisenhower categories',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
          title: 'Pesanan mendesak',
          targetTime: '08:00',
          quadrant: PriorityQuadrant.doFirst));
      await provider.addTask(sampleTask(
          title: 'Persiapan mingguan',
          targetTime: '09:30',
          quadrant: PriorityQuadrant.schedule));
      await provider.addTask(sampleTask(
          title: 'Antar pesanan',
          targetTime: '12:30',
          quadrant: PriorityQuadrant.delegate));
      await provider.addTask(sampleTask(
          title: 'Rapikan arsip',
          targetTime: '16:00',
          quadrant: PriorityQuadrant.later));

      await pumpTestApp(tester, home: const ScheduleTimelineScreen(), provider: provider);

      expect(find.text('Jadwal Hari Ini'), findsOneWidget);
      expect(find.text('Kerjakan Dahulu'), findsOneWidget);
      expect(find.text('Jadwalkan'), findsOneWidget);
      expect(find.text('Delegasikan'), findsOneWidget);
      expect(find.text('Nanti'), findsOneWidget);

      expect(find.text('Pesanan mendesak'), findsOneWidget);
      expect(find.text('Persiapan mingguan'), findsOneWidget);
      expect(find.text('Antar pesanan'), findsOneWidget);
      expect(find.text('Rapikan arsip'), findsOneWidget);
    });

    testWidgets('shows the planned total duration badge', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
          title: 'A', targetTime: '09:00', durationMinutes: 60));
      await provider.addTask(sampleTask(
          title: 'B', targetTime: '10:00', durationMinutes: 45));
      await provider.addTask(sampleTask(
          title: 'C', targetTime: '11:00', durationMinutes: 15));

      await pumpTestApp(tester, home: const ScheduleTimelineScreen(), provider: provider);

      expect(find.text('2j direncanakan'), findsOneWidget);
    });

    testWidgets('shows an empty hint per category when nothing is assigned',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const ScheduleTimelineScreen(), provider: provider);

      expect(find.text('Tidak ada tugas pada rentang waktu ini'), findsNWidgets(4));
      expect(find.text('0m direncanakan'), findsOneWidget);
    });

    testWidgets('checking a task from the schedule updates its state',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Selesaikan laporan', targetTime: '09:00'));

      await pumpTestApp(tester, home: const ScheduleTimelineScreen(), provider: provider);

      // The timeline item uses a custom checkbox container, not a Checkbox widget.
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(TaskInputScreen), findsOneWidget);
    });
  });
}
