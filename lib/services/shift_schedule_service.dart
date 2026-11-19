import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_phase.dart';
import '../models/task_model.dart';

/// Shift manager that classifies time windows, persists the user's own
/// peak/quiet hours and suggests moving preparation work out of peak hours.
///
/// It is a [ChangeNotifier] so screens showing the current phase (dashboard
/// banner, schedule summary) refresh as soon as the owner edits the windows.
class ShiftScheduleService extends ChangeNotifier {
  static final ShiftScheduleService instance = ShiftScheduleService._internal();

  TimeOfDay quietStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay quietEnd = const TimeOfDay(hour: 11, minute: 0);

  TimeOfDay peakStart = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay peakEnd = const TimeOfDay(hour: 14, minute: 0);

  ShiftScheduleService._internal();

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  /// Rules: quietStart < quietEnd <= peakStart < peakEnd (same day).
  static bool isValidWindows({
    required TimeOfDay quietStart,
    required TimeOfDay quietEnd,
    required TimeOfDay peakStart,
    required TimeOfDay peakEnd,
  }) {
    final qs = _minutes(quietStart);
    final qe = _minutes(quietEnd);
    final ps = _minutes(peakStart);
    final pe = _minutes(peakEnd);
    return qs < qe && qe <= ps && ps < pe;
  }

  /// Load the windows the user configured, ignoring invalid/partial data so a
  /// corrupted preference can never break the classification.
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

    if (qStartH == null ||
        qStartM == null ||
        qEndH == null ||
        qEndM == null ||
        pStartH == null ||
        pStartM == null ||
        pEndH == null ||
        pEndM == null) {
      return;
    }

    final candidateQuietStart = TimeOfDay(hour: qStartH, minute: qStartM);
    final candidateQuietEnd = TimeOfDay(hour: qEndH, minute: qEndM);
    final candidatePeakStart = TimeOfDay(hour: pStartH, minute: pStartM);
    final candidatePeakEnd = TimeOfDay(hour: pEndH, minute: pEndM);

    if (!isValidWindows(
      quietStart: candidateQuietStart,
      quietEnd: candidateQuietEnd,
      peakStart: candidatePeakStart,
      peakEnd: candidatePeakEnd,
    )) {
      return;
    }

    quietStart = candidateQuietStart;
    quietEnd = candidateQuietEnd;
    peakStart = candidatePeakStart;
    peakEnd = candidatePeakEnd;
    notifyListeners();
  }

  /// Persist a new set of windows. Returns false (and keeps the old values)
  /// when the order is invalid.
  Future<bool> updateWindows({
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
    TimeOfDay? peakStart,
    TimeOfDay? peakEnd,
  }) async {
    final nextQuietStart = quietStart ?? this.quietStart;
    final nextQuietEnd = quietEnd ?? this.quietEnd;
    final nextPeakStart = peakStart ?? this.peakStart;
    final nextPeakEnd = peakEnd ?? this.peakEnd;

    if (!isValidWindows(
      quietStart: nextQuietStart,
      quietEnd: nextQuietEnd,
      peakStart: nextPeakStart,
      peakEnd: nextPeakEnd,
    )) {
      return false;
    }

    this.quietStart = nextQuietStart;
    this.quietEnd = nextQuietEnd;
    this.peakStart = nextPeakStart;
    this.peakEnd = nextPeakEnd;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiet_start_h', nextQuietStart.hour);
    await prefs.setInt('quiet_start_m', nextQuietStart.minute);
    await prefs.setInt('quiet_end_h', nextQuietEnd.hour);
    await prefs.setInt('quiet_end_m', nextQuietEnd.minute);
    await prefs.setInt('peak_start_h', nextPeakStart.hour);
    await prefs.setInt('peak_start_m', nextPeakStart.minute);
    await prefs.setInt('peak_end_h', nextPeakEnd.hour);
    await prefs.setInt('peak_end_m', nextPeakEnd.minute);

    notifyListeners();
    return true;
  }

  /// Get current active ShiftPhaseType
  ShiftPhaseType getCurrentPhase([TimeOfDay? customTime]) {
    final time = customTime ?? TimeOfDay.now();
    final minutes = _minutes(time);

    final qStartMin = _minutes(quietStart);
    final qEndMin = _minutes(quietEnd);

    final pStartMin = _minutes(peakStart);
    final pEndMin = _minutes(peakEnd);

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

  /// Check if a given task falls within the quiet (prep) window
  bool isTaskInQuietHours(TaskModel task) {
    final minutes = task.minutesSinceMidnight;
    return minutes >= _minutes(quietStart) && minutes < _minutes(quietEnd);
  }

  /// Check if a given task falls within the peak (rush) window
  bool isTaskInPeakHours(TaskModel task) {
    final minutes = task.minutesSinceMidnight;
    return minutes >= _minutes(peakStart) && minutes < _minutes(peakEnd);
  }

  /// Check if a task falls in transition period
  bool isTaskInTransition(TaskModel task) {
    final minutes = task.minutesSinceMidnight;
    return minutes >= _minutes(quietEnd) && minutes < _minutes(peakStart);
  }

  /// Same as [isTaskInPeakHours] but for a raw time (used by the task form
  /// before the task exists).
  bool isTimeInPeakWindow(TimeOfDay time) {
    final minutes = _minutes(time);
    return minutes >= _minutes(peakStart) && minutes < _minutes(peakEnd);
  }

  /// True when [time] sits inside the quiet (prep) window.
  bool isTimeInQuietWindow(TimeOfDay time) {
    final minutes = _minutes(time);
    return minutes >= _minutes(quietStart) && minutes < _minutes(quietEnd);
  }

  /// Proposal feature 3: a task scheduled inside peak hours should be moved to
  /// the quieter prep window so products are ready before customers arrive.
  bool shouldSuggestQuietWindow(TaskModel task) => isTaskInPeakHours(task);

  /// Time suggested instead of [task]'s slot: the start of the quiet window.
  TimeOfDay suggestedQuietTime(TaskModel task) => quietStart;

  /// "09:00-11:00" style label for a window.
  String formatWindow(TimeOfDay start, TimeOfDay end) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)}-${two(end.hour)}:${two(end.minute)}';
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
