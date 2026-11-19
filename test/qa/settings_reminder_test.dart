import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/settings_screen.dart';
import 'package:dapur_flow/screens/task_reminder_modal.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:dapur_flow/services/settings_service.dart';
import 'package:dapur_flow/widgets/snooze_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

/// Proposal Feature 4 (reminders, daily summary, snooze) plus the alarm
/// configuration screen the app ships with.
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
    await SettingsService.instance.setAlarmDuration(30);
    await SettingsService.instance.setVibrationEnabled(true);
  });

  group('Settings screen - alarm configuration', () {
    testWidgets('the four duration presets persist the choice', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const SettingsScreen(), provider: provider);

      expect(find.text('Lama Bunyi Alarm'), findsOneWidget);

      await tester.tap(find.text('1 mnt'));
      await tester.pumpAndSettle();
      expect(SettingsService.instance.alarmDurationSeconds, 60);

      await tester.tap(find.text('15 detik'));
      await tester.pumpAndSettle();
      expect(SettingsService.instance.alarmDurationSeconds, 15);
    });

    testWidgets('"always ring until stopped" sets an infinite alarm (0 seconds)',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const SettingsScreen(), provider: provider);

      await tester.tap(find.text('Selalu Bunyi (Hingga Dihentikan)'));
      await tester.pumpAndSettle();

      expect(SettingsService.instance.alarmDurationSeconds, 0);
    });

    testWidgets('vibration switch toggles the stored preference', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const SettingsScreen(), provider: provider);

      expect(SettingsService.instance.vibrationEnabled, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(SettingsService.instance.vibrationEnabled, isFalse);
    });

    testWidgets('language switch flips the label without restarting',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const SettingsScreen(), provider: provider);

      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      await tester.tap(find.text('Switch to English'));
      await tester.pumpAndSettle();

      expect(find.text('English (US)'), findsOneWidget);
      expect(find.text('Ubah ke Indonesia'), findsOneWidget);
    });
  });

  group('Reminder modal - scheduled task alert (feature 4)', () {
    testWidgets('quiet-hour task shows the prep note', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Potong sayuran',
        targetTime: '09:30',
        durationMinutes: 30,
      ));

      await pumpPushedScreen(
        tester,
        TaskReminderModal(task: provider.tasks.single),
        provider: provider,
      );

      expect(find.text('09:30 • KERJAKAN DAHULU'), findsOneWidget);
      expect(find.text('Direncanakan untuk jam tenang • Estimasi: 30 menit'),
          findsOneWidget);
      expect(find.text('Tandai Selesai'), findsOneWidget);
      expect(find.text('Tunda / Jadwal Ulang'), findsOneWidget);
    });

    testWidgets('peak-hour task shows the warning note', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Antar pesanan',
        targetTime: '12:30',
        durationMinutes: 15,
        quadrant: PriorityQuadrant.delegate,
      ));

      await pumpPushedScreen(
        tester,
        TaskReminderModal(task: provider.tasks.single),
        provider: provider,
      );

      expect(find.text('Peringatan: Jadwal jatuh pada jam sibuk layanan'),
          findsOneWidget);
    });

    testWidgets('"mark as done" completes the task in SQLite', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Matikan kompor', targetTime: '13:00'));

      await pumpPushedScreen(
        tester,
        TaskReminderModal(task: provider.tasks.single),
        provider: provider,
      );

      await tester.tap(find.text('Tandai Selesai'));
      await tester.pumpAndSettle();

      expect(provider.tasks.single.isCompleted, isTrue);
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('tasks', where: 'is_completed = ?', whereArgs: [1]);
      expect(rows.single['title'], 'Matikan kompor');
    });

    testWidgets('snoozed counter is displayed', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Angkat gorengan', targetTime: '09:30'));
      await provider.snoozeTask(provider.tasks.single.id!, 5);

      await pumpPushedScreen(
        tester,
        TaskReminderModal(task: provider.tasks.single),
        provider: provider,
      );

      expect(find.text('Ditunda: 1 kali'), findsOneWidget);
    });
  });

  group('Snooze bottom sheet', () {
    testWidgets('+5 minutes moves the reminder and stores the snooze count',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Tunda saya', targetTime: '09:30'));

      await pumpPushedScreen(
        tester,
        Scaffold(body: SnoozeBottomSheet(task: provider.tasks.single)),
        provider: provider,
      );

      expect(find.text('Tunda atau Jadwalkan Ulang'), findsOneWidget);
      expect(find.text('+5 Menit'), findsOneWidget);
      expect(find.text('+10 Menit'), findsOneWidget);
      expect(find.text('+15 Menit'), findsOneWidget);
      expect(find.text('Pilih Waktu Baru'), findsOneWidget);

      await tester.tap(find.text('+5 Menit'));
      await tester.pumpAndSettle();

      final updated = provider.tasks.single;
      expect(updated.snoozeCount, 1);
      expect(updated.targetTime, isNot('09:30'));
      expect(find.textContaining('Tugas ditunda selama 5 menit'), findsOneWidget);
    });
  });
}
