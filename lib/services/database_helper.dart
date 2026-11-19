import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/task_template.dart';

/// 100% Offline SQLite database manager for AturAjah.
///
/// Schema v2 menambahkan tabel `task_templates` (tugas berulang harian) dan
/// kolom `template_id` pada `tasks`, sehingga pekerjaan persiapan yang sama
/// tidak perlu diketik ulang setiap pagi.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const int schemaVersion = 3;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('atur_ajah.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: schemaVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textNotNull = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerNotNull = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textNotNull,
        target_time $textNotNull,
        duration_minutes $integerNotNull,
        assignee $textNullable,
        priority_quadrant $integerNotNull,
        is_completed $integerNotNull DEFAULT 0,
        snooze_count $integerNotNull DEFAULT 0,
        created_at $textNotNull,
        template_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE task_templates (
        id $idType,
        title $textNotNull,
        target_time $textNotNull,
        duration_minutes $integerNotNull,
        assignee $textNullable,
        priority_quadrant $integerNotNull,
        is_active $integerNotNull DEFAULT 1
      )
    ''');

    // One generated task per template per day, enforced by the database.
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_template_day
      ON tasks(template_id, created_at)
      WHERE template_id IS NOT NULL
    ''');

    // Days the owner deliberately skipped for a recurring template, so a
    // deleted occurrence does not silently come back on the next refresh.
    await db.execute('''
      CREATE TABLE template_skips (
        template_id INTEGER NOT NULL,
        skip_date TEXT NOT NULL,
        PRIMARY KEY (template_id, skip_date)
      )
    ''');
    // Fresh installation starts with clean empty task list
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN template_id INTEGER');
      await db.execute('''
        CREATE TABLE task_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          target_time TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL,
          assignee TEXT,
          priority_quadrant INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_template_day
        ON tasks(template_id, created_at)
        WHERE template_id IS NOT NULL
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE template_skips (
          template_id INTEGER NOT NULL,
          skip_date TEXT NOT NULL,
          PRIMARY KEY (template_id, skip_date)
        )
      ''');
    }
  }

  static String todayDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Insert a new task.
  /// [ignoreConstraints] makes duplicate rows (same template + day) a no-op,
  /// which keeps recurring materialisation idempotent.
  Future<int> insertTask(TaskModel task, {bool ignoreConstraints = false}) async {
    final db = await database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm:
          ignoreConstraints ? ConflictAlgorithm.ignore : ConflictAlgorithm.abort,
    );
  }

  /// Retrieve tasks for today sorted chronologically by target_time
  Future<List<TaskModel>> getTodayTasks([String? dateIso]) async {
    final db = await database;
    final date = dateIso ?? todayDateString();

    final result = await db.query(
      'tasks',
      where: 'created_at = ?',
      whereArgs: [date],
      orderBy: 'target_time ASC',
    );

    return result.map((json) => TaskModel.fromMap(json)).toList();
  }

  /// Every task between two ISO dates (inclusive), oldest day first.
  /// Used by the weekly overview.
  Future<List<TaskModel>> getTasksBetween(String startIso, String endIso) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startIso, endIso],
      orderBy: 'created_at ASC, target_time ASC',
    );
    return result.map((json) => TaskModel.fromMap(json)).toList();
  }

  /// Retrieve single task by id
  Future<TaskModel?> getTaskById(int id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return TaskModel.fromMap(maps.first);
    }
    return null;
  }

  /// Update an existing task
  Future<int> updateTask(TaskModel task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Mark task status as completed or incomplete
  Future<int> markTaskCompleted(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Record a snooze event: increment snooze_count and update target_time
  Future<int> snoozeTask(int id, String newTargetTime) async {
    final db = await database;
    return await db.rawUpdate('''
      UPDATE tasks 
      SET snooze_count = snooze_count + 1,
          target_time = ?
      WHERE id = ?
    ''', [newTargetTime, id]);
  }

  /// Move a task to a different hour without counting it as a snooze
  Future<int> moveTask(int id, String newTargetTime) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'target_time': newTargetTime},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a task
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Recurring task templates
  // ---------------------------------------------------------------------------

  Future<int> insertTemplate(TaskTemplate template) async {
    final db = await database;
    return await db.insert('task_templates', template.toMap());
  }

  Future<List<TaskTemplate>> getTemplates({bool onlyActive = false}) async {
    final db = await database;
    final result = await db.query(
      'task_templates',
      where: onlyActive ? 'is_active = ?' : null,
      whereArgs: onlyActive ? [1] : null,
      orderBy: 'target_time ASC',
    );
    return result.map((json) => TaskTemplate.fromMap(json)).toList();
  }

  Future<int> setTemplateActive(int id, bool isActive) async {
    final db = await database;
    return await db.update(
      'task_templates',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTemplate(int id) async {
    final db = await database;
    return await db.delete(
      'task_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Remember that the owner removed a generated occurrence for [date], so the
  /// recurring template does not recreate it during the same day.
  Future<void> markTemplateSkipped(int templateId, String date) async {
    final db = await database;
    await db.insert(
      'template_skips',
      {'template_id': templateId, 'skip_date': date},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<bool> isTemplateSkipped(int templateId, String date) async {
    final db = await database;
    final rows = await db.query(
      'template_skips',
      where: 'template_id = ? AND skip_date = ?',
      whereArgs: [templateId, date],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Drops skip markers older than [beforeDate] (keeps the table tiny).
  Future<void> pruneTemplateSkips(String beforeDate) async {
    final db = await database;
    await db.delete(
      'template_skips',
      where: 'skip_date < ?',
      whereArgs: [beforeDate],
    );
  }

  /// Close DB
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
