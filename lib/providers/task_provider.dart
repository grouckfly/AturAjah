import 'dart:async';

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/task_template.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/shift_schedule_service.dart';

/// Central state provider for daily tasks and shift operations.
class TaskProvider extends ChangeNotifier {
  /// When true (production), the provider triggers the in-app reminder modal as
  /// soon as a task's target time arrives while the app is open. Tests disable
  /// it because long timers never settle inside fake-async widget tests.
  static bool inAppReminderTimersEnabled = true;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final ShiftScheduleService _shiftService = ShiftScheduleService.instance;

  List<TaskModel> _tasks = [];
  List<TaskTemplate> _templates = [];
  bool _isLoading = false;
  TaskModel? _activeReminderTask;
  Future<void>? _pendingLoad;
  Timer? _reminderTimer;

  List<TaskModel> get tasks => _tasks;
  List<TaskTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  TaskModel? get activeReminderTask => _activeReminderTask;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  /// Progress representation: e.g. "1/4"
  String get progressFraction => '$completedCount/$totalCount';

  /// Tasks in Quiet Hours (user-defined, default 09:00 - 11:00)
  List<TaskModel> get quietHoursTasks =>
      _tasks.where((t) => _shiftService.isTaskInQuietHours(t)).toList();

  /// Tasks in Mid-Day Transition (between quiet and peak window)
  List<TaskModel> get transitionTasks =>
      _tasks.where((t) => _shiftService.isTaskInTransition(t)).toList();

  /// Tasks in Peak Hours (user-defined, default 12:00 - 14:00)
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

  /// Load tasks from SQLite and re-sort chronologically.
  ///
  /// Active recurring templates are materialised into real tasks for today
  /// first, so the daily checklist is never empty for repetitive MSME work.
  /// Concurrent calls share one in-flight load, preventing a double
  /// materialisation when the constructor and a pull-to-refresh overlap.
  Future<void> loadTasks() {
    final pending = _pendingLoad;
    if (pending != null) return pending;

    final future = _loadTasksInternal();
    _pendingLoad = future.whenComplete(() => _pendingLoad = null);
    return _pendingLoad!;
  }

  Future<void> _loadTasksInternal() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _materializeRecurringTasks();
      _tasks = await _dbHelper.getTodayTasks();
      _sortTasks();
      _templates = await _dbHelper.getTemplates();

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
      _armInAppReminder();
      notifyListeners();
    }
  }

  /// Arms a one-shot timer for the nearest pending task so the reminder modal
  /// (and its looping alarm sound) opens exactly when the time arrives, even if
  /// the system notification is suppressed by the device.
  void _armInAppReminder() {
    if (!inAppReminderTimersEnabled) return;

    _reminderTimer?.cancel();
    _reminderTimer = null;

    final now = DateTime.now();
    TaskModel? nextTask;
    DateTime? nextMoment;

    for (final task in _tasks) {
      if (task.isCompleted) continue;
      final moment = task.targetDateTimeToday;
      if (!moment.isAfter(now)) continue;
      if (nextMoment == null || moment.isBefore(nextMoment)) {
        nextMoment = moment;
        nextTask = task;
      }
    }

    if (nextTask == null || nextMoment == null) return;

    _reminderTimer = Timer(nextMoment.difference(now), () {
      setActiveReminderTask(nextTask);
      _armInAppReminder();
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  /// Create today's tasks from every active template that has not been
  /// materialised yet today.
  Future<void> _materializeRecurringTasks() async {
    final activeTemplates = await _dbHelper.getTemplates(onlyActive: true);
    if (activeTemplates.isEmpty) return;

    final today = DatabaseHelper.todayDateString();
    // Keep the skip table small: only today's markers matter.
    await _dbHelper.pruneTemplateSkips(today);

    final todayTasks = await _dbHelper.getTodayTasks(today);
    final alreadyCreated = todayTasks
        .map((task) => task.templateId)
        .whereType<int>()
        .toSet();

    for (final template in activeTemplates) {
      if (template.id == null || alreadyCreated.contains(template.id)) continue;
      // The owner deleted today's occurrence on purpose: do not resurrect it.
      if (await _dbHelper.isTemplateSkipped(template.id!, today)) continue;

      await _dbHelper.insertTask(TaskModel(
        title: template.title,
        targetTime: template.targetTime,
        durationMinutes: template.durationMinutes,
        assignee: template.assignee,
        priorityQuadrant: template.priorityQuadrant,
        createdAt: today,
        templateId: template.id,
      ), ignoreConstraints: true);
      alreadyCreated.add(template.id!);
    }
  }

  /// Sort tasks chronologically by target time
  void _sortTasks() {
    _tasks.sort((a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight));
  }

  /// Add new task, persist to SQLite, and register exact alarm.
  /// When [makeRecurring] is true the task is also saved as a daily template.
  Future<void> addTask(TaskModel task, {bool makeRecurring = false}) async {
    final id = await _dbHelper.insertTask(task);
    var savedTask = task.copyWith(id: id);

    if (makeRecurring) {
      final templateId = await _dbHelper.insertTemplate(TaskTemplate(
        title: task.title,
        targetTime: task.targetTime,
        durationMinutes: task.durationMinutes,
        assignee: task.assignee,
        priorityQuadrant: task.priorityQuadrant,
      ));
      savedTask = savedTask.copyWith(templateId: templateId);
      await _dbHelper.updateTask(savedTask);
      _templates = await _dbHelper.getTemplates();
    }

    _tasks.add(savedTask);
    _sortTasks();
    notifyListeners();

    await _notificationService.scheduleTaskAlarm(savedTask);
    _armInAppReminder();
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
    _armInAppReminder();
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
    _armInAppReminder();
  }

  /// Move a task to an explicit HH:mm.
  ///
  /// Rescheduling is not a snooze, so [TaskModel.snoozeCount] stays untouched
  /// (the "Ditunda: Nx" label would otherwise lie).
  Future<void> rescheduleTask(int taskId, String newTime) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final currentTask = _tasks[index];
    await _dbHelper.moveTask(taskId, newTime);

    final updatedTask = currentTask.copyWith(targetTime: newTime);

    _tasks[index] = updatedTask;
    _sortTasks();
    if (_activeReminderTask?.id == taskId) {
      _activeReminderTask = null;
    }
    notifyListeners();

    await _notificationService.cancelTaskAlarm(taskId);
    if (!updatedTask.isCompleted) {
      await _notificationService.scheduleTaskAlarm(updatedTask);
    }
    _armInAppReminder();
  }

  /// Apply the quiet-hours suggestion (proposal feature 3) for a task that is
  /// currently planned inside the peak window.
  Future<void> moveTaskToQuietWindow(int taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final suggested = _shiftService.suggestedQuietTime(_tasks[index]);
    final timeStr =
        '${suggested.hour.toString().padLeft(2, '0')}:${suggested.minute.toString().padLeft(2, '0')}';
    await rescheduleTask(taskId, timeStr);
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
    _armInAppReminder();
  }

  /// Delete task from SQLite and cancel alarm.
  ///
  /// When the task came from a recurring template, today's occurrence is
  /// remembered as skipped so a refresh does not recreate it.
  Future<void> deleteTask(int taskId) async {
    final removed = _tasks.where((t) => t.id == taskId).toList();
    await _dbHelper.deleteTask(taskId);
    if (removed.isNotEmpty && removed.first.templateId != null) {
      await _dbHelper.markTemplateSkipped(
        removed.first.templateId!,
        DatabaseHelper.todayDateString(),
      );
    }
    _tasks.removeWhere((t) => t.id == taskId);
    if (_activeReminderTask?.id == taskId) {
      _activeReminderTask = null;
    }
    notifyListeners();
    await _notificationService.cancelTaskAlarm(taskId);
    _armInAppReminder();
  }

  // ---------------------------------------------------------------------------
  // Recurring templates
  // ---------------------------------------------------------------------------

  Future<void> reloadTemplates() async {
    _templates = await _dbHelper.getTemplates();
    notifyListeners();
  }

  Future<void> toggleTemplateActive(TaskTemplate template) async {
    if (template.id == null) return;
    await _dbHelper.setTemplateActive(template.id!, !template.isActive);
    await reloadTemplates();
  }

  Future<void> deleteTemplate(int templateId) async {
    await _dbHelper.deleteTemplate(templateId);
    await reloadTemplates();
  }

  // ---------------------------------------------------------------------------
  // Weekly overview (proposal objective 4: daily and weekly overview)
  // ---------------------------------------------------------------------------

  /// Tasks of the last 7 days (today included), keyed by "YYYY-MM-DD",
  /// oldest day first. Days without tasks map to an empty list.
  Future<Map<String, List<TaskModel>>> loadWeeklyTasks() async {
    String iso(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    final stored = await _dbHelper.getTasksBetween(iso(start), iso(now));

    final byDay = <String, List<TaskModel>>{};
    for (var offset = 6; offset >= 0; offset--) {
      byDay[iso(now.subtract(Duration(days: offset)))] = <TaskModel>[];
    }
    for (final task in stored) {
      byDay.putIfAbsent(task.createdAt, () => <TaskModel>[]).add(task);
    }
    return byDay;
  }
}
