import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/priority_quadrant.dart';

/// 100% Offline SQLite database manager for Dapur Flow.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dapur_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
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
        created_at $textNotNull
      )
    ''');

    // Populate realistic kitchen shift tasks for immediate operational experience
    final today = _getTodayDateString();
    await db.insert('tasks', {
      'title': 'Potong sayuran & bahan salad segar',
      'target_time': '09:15',
      'duration_minutes': 45,
      'assignee': null,
      'priority_quadrant': PriorityQuadrant.doFirst.value,
      'is_completed': 0,
      'snooze_count': 0,
      'created_at': today,
    });

    await db.insert('tasks', {
      'title': 'Cek stok bumbu dasar & kaldu ayam',
      'target_time': '10:00',
      'duration_minutes': 30,
      'assignee': null,
      'priority_quadrant': PriorityQuadrant.schedule.value,
      'is_completed': 1,
      'snooze_count': 0,
      'created_at': today,
    });

    await db.insert('tasks', {
      'title': 'Restock packaging & cup take-away',
      'target_time': '11:00',
      'duration_minutes': 20,
      'assignee': null,
      'priority_quadrant': PriorityQuadrant.delegate.value,
      'is_completed': 0,
      'snooze_count': 0,
      'created_at': today,
    });

    await db.insert('tasks', {
      'title': 'Briefing cepat tim jelang Jam Sibuk (Rush)',
      'target_time': '11:45',
      'duration_minutes': 15,
      'assignee': null,
      'priority_quadrant': PriorityQuadrant.doFirst.value,
      'is_completed': 0,
      'snooze_count': 0,
      'created_at': today,
    });
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Insert a new task
  Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  /// Retrieve tasks for today sorted chronologically by target_time
  Future<List<TaskModel>> getTodayTasks([String? dateIso]) async {
    final db = await database;
    final date = dateIso ?? _getTodayDateString();

    final result = await db.query(
      'tasks',
      where: 'created_at = ?',
      whereArgs: [date],
      orderBy: 'target_time ASC',
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

  /// Delete a task
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Close DB
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
