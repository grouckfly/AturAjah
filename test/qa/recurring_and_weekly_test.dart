import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/models/task_model.dart';
import 'package:dapur_flow/models/task_template.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/recurring_tasks_screen.dart';
import 'package:dapur_flow/screens/weekly_overview_screen.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

/// Proposal gaps that are now implemented:
///  * recurring daily templates (repetitive prep work is not retyped),
///  * weekly overview with per-day completion (objective 4 + evaluation §8).
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
    final db = await DatabaseHelper.instance.database;
    await db.delete('task_templates');
    await db.delete('template_skips');
  });

  String isoDaysAgo(int days) {
    final date = DateTime.now().subtract(Duration(days: days));
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  group('Recurring templates', () {
    test('addTask(makeRecurring: true) stores an active template', () async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await provider.addTask(
        sampleTask(title: 'Siapkan bumbu', targetTime: '08:00'),
        makeRecurring: true,
      );

      expect(provider.templates.length, 1);
      expect(provider.templates.single.title, 'Siapkan bumbu');
      expect(provider.templates.single.isActive, isTrue);
      expect(provider.tasks.single.templateId, provider.templates.single.id);

      // Persisted across a fresh provider (i.e. next app start).
      final reloaded = TaskProvider();
      await reloaded.loadTasks();
      expect(reloaded.templates.single.title, 'Siapkan bumbu');
    });

    test('active templates materialise into today tasks exactly once', () async {
      await DatabaseHelper.instance.insertTemplate(const TaskTemplate(
        title: 'Cuci piring pagi',
        targetTime: '07:30',
        durationMinutes: 15,
        priorityQuadrant: PriorityQuadrant.delegate,
        assignee: 'Sari',
      ));

      final provider = TaskProvider();
      await provider.loadTasks();

      expect(provider.tasks.length, 1);
      final generated = provider.tasks.single;
      expect(generated.title, 'Cuci piring pagi');
      expect(generated.targetTime, '07:30');
      expect(generated.assignee, 'Sari');
      expect(generated.templateId, isNotNull);

      // Loading again must not duplicate the task.
      await provider.loadTasks();
      expect(provider.tasks.length, 1);
    });

    test('deleting a generated occurrence does not resurrect it today',
        () async {
      final templateId = await DatabaseHelper.instance.insertTemplate(
        const TaskTemplate(
          title: 'Sarapan stok',
          targetTime: '07:00',
          durationMinutes: 10,
          priorityQuadrant: PriorityQuadrant.later,
        ),
      );

      final provider = TaskProvider();
      await provider.loadTasks();
      expect(provider.tasks.single.templateId, templateId);

      await provider.deleteTask(provider.tasks.single.id!);
      expect(provider.tasks, isEmpty);

      // A refresh (pull-to-refresh, app restart) must not bring it back today.
      await provider.loadTasks();
      expect(provider.tasks, isEmpty);
    });

    test('inactive templates are skipped', () async {
      await DatabaseHelper.instance.insertTemplate(const TaskTemplate(
        title: 'Tugas nonaktif',
        targetTime: '10:00',
        durationMinutes: 10,
        priorityQuadrant: PriorityQuadrant.later,
        isActive: false,
      ));

      final provider = TaskProvider();
      await provider.loadTasks();

      expect(provider.tasks, isEmpty);
      expect(provider.templates.length, 1);
    });

    test('toggleTemplateActive flips the stored flag', () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(
        sampleTask(title: 'Restock harian', targetTime: '16:00'),
        makeRecurring: true,
      );

      await provider.toggleTemplateActive(provider.templates.single);
      expect(provider.templates.single.isActive, isFalse);

      await provider.toggleTemplateActive(provider.templates.single);
      expect(provider.templates.single.isActive, isTrue);
    });

    testWidgets('recurring screen lists, toggles and deletes templates',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(
        sampleTask(title: 'Siapkan isi lemari', targetTime: '08:15'),
        makeRecurring: true,
      );

      await pumpPushedScreen(tester, const RecurringTasksScreen(), provider: provider);

      expect(find.text('Tugas Berulang'), findsOneWidget);
      expect(find.text('Siapkan isi lemari'), findsOneWidget);

      // Toggle off.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(provider.templates.single.isActive, isFalse);

      // Delete with confirmation.
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(
        find.text('Hapus tugas berulang ini? Tugas hari ini tidak ikut terhapus.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();

      expect(provider.templates, isEmpty);
      expect(find.text('Siapkan isi lemari'), findsNothing);
    });
  });

  group('Weekly overview', () {
    test('loadWeeklyTasks buckets tasks per day including empty days', () async {
      final db = await DatabaseHelper.instance.database;

      Future<void> seed(int daysAgo, String title, {bool done = false}) async {
        final task = TaskModel(
          title: title,
          targetTime: '09:00',
          durationMinutes: 30,
          priorityQuadrant: PriorityQuadrant.doFirst,
          isCompleted: done,
          createdAt: isoDaysAgo(daysAgo),
        );
        await db.insert('tasks', task.toMap());
      }

      await seed(0, 'Hari ini', done: true);
      await seed(2, 'Dua hari lalu');
      await seed(2, 'Dua hari lalu #2', done: true);

      final provider = TaskProvider();
      await provider.loadTasks();
      final weekly = await provider.loadWeeklyTasks();

      expect(weekly.length, 7);
      expect(weekly[isoDaysAgo(0)]!.length, 1);
      expect(weekly[isoDaysAgo(0)]!.single.isCompleted, isTrue);
      expect(weekly[isoDaysAgo(2)]!.length, 2);
      expect(weekly[isoDaysAgo(4)], isEmpty);
    });

    testWidgets('weekly screen shows totals and the seven day rows',
        (tester) async {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'tasks',
        TaskModel(
          title: 'Tugas selesai',
          targetTime: '09:00',
          durationMinutes: 30,
          priorityQuadrant: PriorityQuadrant.doFirst,
          isCompleted: true,
          createdAt: isoDaysAgo(0),
        ).toMap(),
      );

      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const WeeklyOverviewScreen(), provider: provider);

      expect(find.text('Ringkasan Mingguan'), findsOneWidget);
      expect(find.text('Total tugas'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Pernah ditunda'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // total + completed counters
      expect(find.textContaining('Hari ini'), findsWidgets);
      expect(find.text('Tidak ada tugas'), findsNWidgets(6));
    });
  });
}
