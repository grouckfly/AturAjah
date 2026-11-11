import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/shift_schedule_service.dart';

/// Central state provider for daily tasks and shift operations.
class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final ShiftScheduleService _shiftService = ShiftScheduleService.instance;

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  TaskModel? _activeReminderTask;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  TaskModel? get activeReminderTask => _activeReminderTask;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  /// Progress representation: e.g. "1/4"
  String get progressFraction => '$completedCount/$totalCount';

  /// Tasks in Quiet Hours (09:00 - 11:00)
  List<TaskModel> get quietHoursTasks =>
      _tasks.where((t) => _shiftService.isTaskInQuietHours(t)).toList();

  /// Tasks in Mid-Day Transition (11:00 - 12:00)
  List<TaskModel> get transitionTasks =>
      _tasks.where((t) => _shiftService.isTaskInTransition(t)).toList();

  /// Tasks in Peak Hours (12:00 - 14:00)
  List<TaskModel> get peakHoursTasks =>
      _tasks.where((t) => _shiftService.isTaskInPeakHours(t)).toList();

  /// Other tasks
  List<TaskModel> get otherTasks => _tasks
      .where((t) =>
          !_shiftService.isTaskInQuietHours(t) &&
          !_shiftService.isTaskInTransition(t) &&
          !_shiftService.isTaskInPeakHours(t))
      .toList();

  TaskProvider() {
    loadTasks();
    _listenToNotificationClicks();
  }

  void _listenToNotificationClicks() {
    _notificationService.onNotificationClick.listen((taskId) {
      if (_tasks.isEmpty) return;
      final matches = _tasks.where((t) => t.id == taskId).toList();
      if (matches.isNotEmpty) {
        setActiveReminderTask(matches.first);
      } else {
        setActiveReminderTask(_tasks.first);
      }
    });
  }

  void setActiveReminderTask(TaskModel? task) {
    _activeReminderTask = task;
    notifyListeners();
  }

  /// Load tasks from SQLite and re-sort chronologically
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _dbHelper.getTodayTasks();
      _sortTasks();

      // Ensure alarms are registered for pending tasks
      for (final task in _tasks) {
        if (!task.isCompleted) {
          await _notificationService.scheduleTaskAlarm(task);
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sort tasks chronologically by target time
  void _sortTasks() {
    _tasks.sort((a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight));
  }

  /// Add new task, persist to SQLite, and register exact alarm
  Future<void> addTask(TaskModel task) async {
    final id = await _dbHelper.insertTask(task);
    final savedTask = task.copyWith(id: id);
    _tasks.add(savedTask);
    _sortTasks();
    notifyListeners();

    await _notificationService.scheduleTaskAlarm(savedTask);
  }

  /// Toggle completion status
  Future<void> toggleTaskDone(int taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final currentTask = _tasks[index];
    final updatedStatus = !currentTask.isCompleted;

    await _dbHelper.markTaskCompleted(taskId, updatedStatus);

    _tasks[index] = currentTask.copyWith(isCompleted: updatedStatus);
    notifyListeners();

    if (updatedStatus) {
      // Cancel pending reminders once marked done
      await _notificationService.cancelTaskAlarm(taskId);
      if (_activeReminderTask?.id == taskId) {
        _activeReminderTask = null;
        notifyListeners();
      }
    } else {
      // Re-schedule alarm if unmarked
      await _notificationService.scheduleTaskAlarm(_tasks[index]);
    }
  }

  /// Snooze task (+5, +10, +15 minutes) - Triggers repeating alarm loop
  Future<void> snoozeTask(int taskId, int minutesToAdd) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final currentTask = _tasks[index];
    final now = DateTime.now().add(Duration(minutes: minutesToAdd));
    final newTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    await _dbHelper.snoozeTask(taskId, newTimeStr);

    final updatedTask = currentTask.copyWith(
      targetTime: newTimeStr,
      snoozeCount: currentTask.snoozeCount + 1,
    );

    _tasks[index] = updatedTask;
    _sortTasks();
    if (_activeReminderTask?.id == taskId) {
      _activeReminderTask = null;
    }
    notifyListeners();

    // Register repeating snooze alarm
    await _notificationService.scheduleSnoozeAlarm(updatedTask, minutesToAdd);
  }

  /// Reschedule task to a specific HH:mm
  Future<void> rescheduleTask(int taskId, String newTime) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final currentTask = _tasks[index];
    await _dbHelper.snoozeTask(taskId, newTime);

    final updatedTask = currentTask.copyWith(
      targetTime: newTime,
      snoozeCount: currentTask.snoozeCount + 1,
    );

    _tasks[index] = updatedTask;
    _sortTasks();
    if (_activeReminderTask?.id == taskId) {
      _activeReminderTask = null;
    }
    notifyListeners();

    await _notificationService.scheduleTaskAlarm(updatedTask);
  }

  /// Update existing task (Full CRUD: Update)
  Future<void> updateTask(TaskModel updatedTask) async {
    if (updatedTask.id == null) return;
    await _dbHelper.updateTask(updatedTask);
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _sortTasks();
      notifyListeners();
    }
    // Reschedule alarm for updated task
    await _notificationService.cancelTaskAlarm(updatedTask.id!);
    if (!updatedTask.isCompleted) {
      await _notificationService.scheduleTaskAlarm(updatedTask);
    }
  }

  /// Delete task from SQLite and cancel alarm
  Future<void> deleteTask(int taskId) async {
    await _dbHelper.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    if (_activeReminderTask?.id == taskId) {
      _activeReminderTask = null;
    }
    notifyListeners();
    await _notificationService.cancelTaskAlarm(taskId);
  }
}
