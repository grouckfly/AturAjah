import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

/// Proposal Feature 1 & 4: task records must be persisted, editable and
/// deletable (full CRUD), completion state must be tracked for the checklist,
/// and snoozing/rescheduling must move the task in time.
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
  });

  Future<List<Map<String, Object?>>> rawRows() async {
    final db = await DatabaseHelper.instance.database;
    return db.query('tasks', orderBy: 'target_time ASC');
  }

  group('TaskProvider - create & read', () {
    test('addTask persists the task and keeps the list time-ordered', () async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await provider.addTask(sampleTask(title: 'Restock bahan', targetTime: '14:00'));
      await provider.addTask(sampleTask(title: 'Siapkan bumbu', targetTime: '08:15'));
      await provider.addTask(sampleTask(title: 'Buka warung', targetTime: '07:00'));

      expect(provider.tasks.map((t) => t.title).toList(),
          ['Buka warung', 'Siapkan bumbu', 'Restock bahan']);
      expect(provider.tasks.every((t) => t.id != null), isTrue);

      final rows = await rawRows();
      expect(rows.length, 3);
      expect(rows.first['title'], 'Buka warung');
    });

    test('loadTasks only returns rows created today', () async {
      final db = await DatabaseHelper.instance.database;
      final yesterday = sampleTask(title: 'Tugas kemarin');
      await db.insert('tasks', {
        'title': yesterday.title,
        'target_time': yesterday.targetTime,
        'duration_minutes': yesterday.durationMinutes,
        'assignee': null,
        'priority_quadrant': yesterday.priorityQuadrant.value,
        'is_completed': 0,
        'snooze_count': 0,
        'created_at': '2020-01-01',
      });
      await DatabaseHelper.instance.insertTask(sampleTask(title: 'Tugas hari ini'));

      final provider = TaskProvider();
      await provider.loadTasks();

      expect(provider.tasks.map((t) => t.title), ['Tugas hari ini']);
    });

    test('empty database yields the empty checklist state', () async {
      final provider = TaskProvider();
      await provider.loadTasks();

      expect(provider.tasks, isEmpty);
      expect(provider.totalCount, 0);
      expect(provider.progressFraction, '0/0');
    });
  });

  group('TaskProvider - update & completion', () {
    test('toggleTaskDone flips state in memory and in SQLite', () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Potong sayur', targetTime: '09:00'));

      final id = provider.tasks.first.id!;
      expect(provider.progressFraction, '0/1');

      await provider.toggleTaskDone(id);
      expect(provider.tasks.first.isCompleted, isTrue);
      expect(provider.progressFraction, '1/1');

      var rows = await rawRows();
      expect(rows.first['is_completed'], 1);

      await provider.toggleTaskDone(id);
      expect(provider.tasks.first.isCompleted, isFalse);
      rows = await rawRows();
      expect(rows.first['is_completed'], 0);
    });

    test('updateTask rewrites title, time, duration and quadrant', () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Lama', targetTime: '09:00'));

      final original = provider.tasks.first;
      await provider.updateTask(original.copyWith(
        title: 'Baru',
        targetTime: '16:45',
        durationMinutes: 55,
        priorityQuadrant: PriorityQuadrant.delegate,
      ));

      final updated = provider.tasks.first;
      expect(updated.title, 'Baru');
      expect(updated.targetTime, '16:45');
      expect(updated.durationMinutes, 55);
      expect(updated.priorityQuadrant, PriorityQuadrant.delegate);

      final rows = await rawRows();
      expect(rows.first['title'], 'Baru');
      expect(rows.first['target_time'], '16:45');
      expect(rows.first['duration_minutes'], 55);
      expect(rows.first['priority_quadrant'], 3);
    });

    test('updateTask on an unsaved task is ignored', () async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await provider.updateTask(sampleTask(title: 'Tanpa id'));
      expect(provider.tasks, isEmpty);
      expect(await rawRows(), isEmpty);
    });
  });

  group('TaskProvider - snooze & reschedule (reminders, feature 4)', () {
    test('snoozeTask moves the target time forward and counts the snooze', () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Angkat cucian', targetTime: '09:00'));

      final id = provider.tasks.first.id!;
      final before = DateTime.now().add(const Duration(minutes: 10));

      await provider.snoozeTask(id, 10);

      final snoozed = provider.tasks.first;
      expect(snoozed.snoozeCount, 1);
      expect(snoozed.targetTime, isNot('09:00'));

      final parts = snoozed.targetTime.split(':');
      final movedTo = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      expect(movedTo.difference(before).inMinutes.abs() <= 1, isTrue);

      final rows = await rawRows();
      expect(rows.first['snooze_count'], 1);
      expect(rows.first['target_time'], snoozed.targetTime);
    });

    test('rescheduleTask pins an explicit time without counting a snooze',
        () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'A', targetTime: '09:00'));
      await provider.addTask(sampleTask(title: 'B', targetTime: '10:00'));

      final second = provider.tasks.last;
      await provider.rescheduleTask(second.id!, '06:30');

      expect(provider.tasks.first.title, 'B');
      expect(provider.tasks.first.targetTime, '06:30');
      // Moving a task is not a snooze (finding G10): the counter must stay 0.
      expect(provider.tasks.first.snoozeCount, 0);

      final rows = await rawRows();
      expect(rows.first['title'], 'B');
      expect(rows.first['target_time'], '06:30');
      expect(rows.first['snooze_count'], 0);
    });
  });

  group('TaskProvider - delete', () {
    test('deleteTask removes the row from SQLite and memory', () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Hapus saya'));
      await provider.addTask(sampleTask(title: 'Sisakan saya', targetTime: '10:00'));

      final target = provider.tasks.firstWhere((t) => t.title == 'Hapus saya');
      await provider.deleteTask(target.id!);

      expect(provider.tasks.map((t) => t.title), ['Sisakan saya']);
      final rows = await rawRows();
      expect(rows.length, 1);
      expect(rows.first['title'], 'Sisakan saya');
    });
  });

  group('TaskProvider - time-window grouping (feature 3)', () {
    test('tasks are bucketed into quiet / transition / peak / other', () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Prep', targetTime: '09:30'));
      await provider.addTask(sampleTask(title: 'Siang', targetTime: '11:30'));
      await provider.addTask(sampleTask(title: 'Sibuk', targetTime: '12:30'));
      await provider.addTask(sampleTask(title: 'Sore', targetTime: '16:00'));

      expect(provider.quietHoursTasks.map((t) => t.title), ['Prep']);
      expect(provider.transitionTasks.map((t) => t.title), ['Siang']);
      expect(provider.peakHoursTasks.map((t) => t.title), ['Sibuk']);
      expect(provider.otherTasks.map((t) => t.title), ['Sore']);
    });

    test('total planned duration adds every task in the day', () async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'A', targetTime: '09:00', durationMinutes: 30));
      await provider.addTask(sampleTask(title: 'B', targetTime: '12:30', durationMinutes: 45));

      final total = provider.tasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);
      expect(total, 75);
    });
  });
}
