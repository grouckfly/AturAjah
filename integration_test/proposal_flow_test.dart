import 'package:dapur_flow/main.dart' as app;
import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/models/task_model.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/task_input_screen.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

/// End-to-end run of the real app on a real Android device/emulator:
/// real sqflite database, real notification plugin, real native alarm bridge.
///
/// Run with:
///   flutter test integration_test/proposal_flow_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A reinstall keeps the previous data, so start every scenario from an empty
  // database (otherwise assertions like "exactly one task" become flaky).
  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks');
    await db.delete('task_templates');
  });

  Future<void> bootApp(WidgetTester tester) async {
    app.main();
    await tester.pump();
    // Splash screen keeps a 1.2 s branded delay.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  }

  testWidgets('E2E: tambah tugas -> checklist -> simulasi jadwal selesai',
      (tester) async {
    await bootApp(tester);

    // Dashboard is up.
    expect(find.text('AturAjah'), findsWidgets);
    expect(find.text('Tugas Hari Ini'), findsOneWidget);

    // Feature 1 + 2: create a task through the form and pick a quadrant.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(TaskInputScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'E2E: potong sayuran');
    await tester.enterText(find.byType(TextFormField).at(1), '25');
    await tester.enterText(find.byType(TextFormField).at(2), 'Sari');

    // The form is taller now (assignee + recurring + suggestion), so scroll to
    // each control before tapping it.
    await tester.scrollUntilVisible(
      find.text('Jadwalkan'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwalkan'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('✓ Simpan Tugas'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('✓ Simpan Tugas'));
    await tester.pumpAndSettle();

    // Back on the dashboard, the task is listed exactly once.
    expect(find.text('E2E: potong sayuran'), findsOneWidget);
    expect(find.text('0/1 selesai'), findsOneWidget);

    // The task really landed in the on-device SQLite database.
    final provider = Provider.of<TaskProvider>(
      tester.element(find.text('Tugas Hari Ini')),
      listen: false,
    );
    expect(provider.tasks.length, 1);
    expect(provider.tasks.single.title, 'E2E: potong sayuran');
    expect(provider.tasks.single.durationMinutes, 25);
    expect(provider.tasks.single.assignee, 'Sari');
    expect(provider.tasks.single.priorityQuadrant, PriorityQuadrant.schedule);
    expect(provider.tasks.single.id, isNotNull);

    // Feature 4: daily checklist toggles and the progress badge follows.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1/1 selesai'), findsOneWidget);
    expect(provider.tasks.single.isCompleted, isTrue);

    // Feature 2: the schedule tab groups the task under "Jadwalkan".
    await tester.tap(find.text('Jadwal').last);
    await tester.pumpAndSettle();
    expect(find.text('Jadwal Hari Ini'), findsOneWidget);
    expect(find.text('E2E: potong sayuran'), findsOneWidget);
    expect(find.text('Kerjakan Dahulu'), findsOneWidget);

    // Objective 4: the weekly tab renders today's completion.
    await tester.tap(find.text('Mingguan'));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan Mingguan'), findsOneWidget);
    expect(find.text('Total tugas'), findsOneWidget);
    expect(find.textContaining('Hari ini'), findsWidgets);
  });

  testWidgets('E2E: tugas masa depan mendaftarkan alarm nyata ke OS',
      (tester) async {
    await bootApp(tester);

    final provider = Provider.of<TaskProvider>(
      tester.element(find.text('Tugas Hari Ini')),
      listen: false,
    );

    final soon = DateTime.now().add(const Duration(minutes: 30));
    final timeStr = '${soon.hour.toString().padLeft(2, '0')}:'
        '${soon.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await provider.addTask(TaskModel(
      title: 'E2E: alarm 30 menit lagi',
      targetTime: timeStr,
      durationMinutes: 15,
      priorityQuadrant: PriorityQuadrant.doFirst,
      createdAt: today,
    ));
    await tester.pumpAndSettle();

    // The row exists in SQLite with the requested time.
    final stored = provider.tasks.firstWhere(
      (t) => t.title == 'E2E: alarm 30 menit lagi',
    );
    expect(stored.targetTime, timeStr);
    expect(stored.id, isNotNull);

    // Feature 4: the real Android notification service really holds the alarm.
    final plugin = FlutterLocalNotificationsPlugin();
    final pending = await plugin.pendingNotificationRequests();
    expect(
      pending.any((request) => request.id == stored.id),
      isTrue,
      reason: 'Android harus menyimpan alarm untuk tugas ${stored.id}',
    );

    // Exact-alarm capability on this device (SCHEDULE_EXACT_ALARM /
    // USE_EXACT_ALARM in the manifest).
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications();
    expect(canExact, isTrue);
  });
}
