import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_phase.dart';
import '../models/task_model.dart';

/// Shift manager that classifies time windows and validates kitchen task allocations.
class ShiftScheduleService {
  static final ShiftScheduleService instance = ShiftScheduleService._internal();

  TimeOfDay quietStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay quietEnd = const TimeOfDay(hour: 11, minute: 0);

  TimeOfDay peakStart = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay peakEnd = const TimeOfDay(hour: 14, minute: 0);

  ShiftScheduleService._internal();

  Future<void> loadCustomWindows() async {
    final prefs = await SharedPreferences.getInstance();
    final qStartH = prefs.getInt('quiet_start_h');
    final qStartM = prefs.getInt('quiet_start_m');
    final qEndH = prefs.getInt('quiet_end_h');
    final qEndM = prefs.getInt('quiet_end_m');

    final pStartH = prefs.getInt('peak_start_h');
    final pStartM = prefs.getInt('peak_start_m');
    final pEndH = prefs.getInt('peak_end_h');
    final pEndM = prefs.getInt('peak_end_m');

    if (qStartH != null && qStartM != null) {
      quietStart = TimeOfDay(hour: qStartH, minute: qStartM);
    }
    if (qEndH != null && qEndM != null) {
      quietEnd = TimeOfDay(hour: qEndH, minute: qEndM);
    }
    if (pStartH != null && pStartM != null) {
      peakStart = TimeOfDay(hour: pStartH, minute: pStartM);
    }
    if (pEndH != null && pEndM != null) {
      peakEnd = TimeOfDay(hour: pEndH, minute: pEndM);
    }
  }

  /// Get current active ShiftPhaseType
  ShiftPhaseType getCurrentPhase([TimeOfDay? customTime]) {
    final time = customTime ?? TimeOfDay.now();
    final minutes = time.hour * 60 + time.minute;

    final qStartMin = quietStart.hour * 60 + quietStart.minute;
    final qEndMin = quietEnd.hour * 60 + quietEnd.minute;

    final pStartMin = peakStart.hour * 60 + peakStart.minute;
    final pEndMin = peakEnd.hour * 60 + peakEnd.minute;

    if (minutes >= qStartMin && minutes < qEndMin) {
      return ShiftPhaseType.quietHours;
    } else if (minutes >= qEndMin && minutes < pStartMin) {
      return ShiftPhaseType.transition;
    } else if (minutes >= pStartMin && minutes < pEndMin) {
      return ShiftPhaseType.peakHours;
    } else {
      return ShiftPhaseType.standard;
    }
  }

  /// Check if a given task falls within Quiet Hours (09:00 - 11:00)
  bool isTaskInQuietHours(TaskModel task) {
    final minutes = task.minutesSinceMidnight;
    final qStartMin = quietStart.hour * 60 + quietStart.minute;
    final qEndMin = quietEnd.hour * 60 + quietEnd.minute;
    return minutes >= qStartMin && minutes < qEndMin;
  }

  /// Check if a given task falls within Peak Hours (12:00 - 14:00)
  bool isTaskInPeakHours(TaskModel task) {
    final minutes = task.minutesSinceMidnight;
    final pStartMin = peakStart.hour * 60 + peakStart.minute;
    final pEndMin = peakEnd.hour * 60 + peakEnd.minute;
    return minutes >= pStartMin && minutes < pEndMin;
  }

  /// Check if a task falls in transition period
  bool isTaskInTransition(TaskModel task) {
    final minutes = task.minutesSinceMidnight;
    final qEndMin = quietEnd.hour * 60 + quietEnd.minute;
    final pStartMin = peakStart.hour * 60 + peakStart.minute;
    return minutes >= qEndMin && minutes < pStartMin;
  }

  /// Formatted total duration (e.g. "4j 20m" or "4h 20m")
  String calculateTotalDuration(List<TaskModel> tasks, {required bool isIndonesian}) {
    final totalMinutes = tasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    final hUnit = isIndonesian ? 'j' : 'h';
    final mUnit = isIndonesian ? 'm' : 'm';

    if (hours > 0 && mins > 0) {
      return '$hours$hUnit $mins$mUnit';
    } else if (hours > 0) {
      return '$hours$hUnit';
    } else {
      return '$mins$mUnit';
    }
  }
}
