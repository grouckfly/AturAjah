import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/models/task_template.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_harness.dart';

/// Users upgrading from the previous release already have a schema-v1 database.
/// Opening it through [DatabaseHelper] must migrate in place (new template
/// table + `template_id` column) without losing a single task.
void main() {
  // Fresh isolate: the migration must be the first thing that opens the file.
  setUpAll(() async {
    await configureTestDatabase();
  });

  test('v1 database is upgraded to v2 and keeps existing tasks', () async {
    final directory = await databaseFactory.getDatabasesPath();
    final path = '$directory/atur_ajah.db';

    await databaseFactory.deleteDatabase(path);

    // --- legacy schema (version 1, no templates, no template_id) ------------
    final legacy = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              target_time TEXT NOT NULL,
              duration_minutes INTEGER NOT NULL,
              assignee TEXT,
              priority_quadrant INTEGER NOT NULL,
              is_completed INTEGER NOT NULL DEFAULT 0,
              snooze_count INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    final today = DatabaseHelper.todayDateString();
    await legacy.insert('tasks', {
      'title': 'Tugas lama pengguna',
      'target_time': '08:30',
      'duration_minutes': 20,
      'assignee': 'Sari',
      'priority_quadrant': 2,
      'is_completed': 0,
      'snooze_count': 1,
      'created_at': today,
    });
    await legacy.close();

    // --- open through the app helper (runs onUpgrade 1 -> 3) ----------------
    final db = await DatabaseHelper.instance.database;
    final version = await db.getVersion();
    expect(version, 3);

    final tasks = await DatabaseHelper.instance.getTodayTasks();
    expect(tasks, hasLength(1));
    final migrated = tasks.single;
    expect(migrated.title, 'Tugas lama pengguna');
    expect(migrated.assignee, 'Sari');
    expect(migrated.snoozeCount, 1);
    expect(migrated.templateId, isNull);

    // The new recurring-template table must exist and be usable.
    expect(await DatabaseHelper.instance.getTemplates(), isEmpty);
    final templateId = await DatabaseHelper.instance.insertTemplate(
      const TaskTemplate(
        title: 'Template setelah migrasi',
        targetTime: '09:00',
        durationMinutes: 15,
        priorityQuadrant: PriorityQuadrant.schedule,
      ),
    );
    expect(templateId, greaterThan(0));
    expect(await DatabaseHelper.instance.getTemplates(), hasLength(1));

    // Skip markers table (schema v3) must exist too.
    await DatabaseHelper.instance.markTemplateSkipped(templateId, today);
    expect(await DatabaseHelper.instance.isTemplateSkipped(templateId, today),
        isTrue);
    await DatabaseHelper.instance.pruneTemplateSkips('2999-01-01');
    expect(await DatabaseHelper.instance.isTemplateSkipped(templateId, today),
        isFalse);
  });
}
