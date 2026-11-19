import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/models/shift_phase.dart';
import 'package:dapur_flow/models/task_model.dart';
import 'package:dapur_flow/services/shift_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

TaskModel _taskAt(String time, {int duration = 30}) => TaskModel(
      title: 'Tugas $time',
      targetTime: time,
      durationMinutes: duration,
      priorityQuadrant: PriorityQuadrant.schedule,
      createdAt: todayIso(),
    );

/// Proposal Feature 3 (Time-based scheduling):
/// the app classifies the working day into low-traffic (quiet), transition and
/// peak windows, and can read user-defined windows from preferences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetShiftWindows();
  });

  group('ShiftScheduleService - default windows', () {
    final service = ShiftScheduleService.instance;

    test('09:00-11:00 is quiet hours (prep window)', () {
      expect(service.getCurrentPhase(const TimeOfDay(hour: 8, minute: 59)),
          ShiftPhaseType.standard);
      expect(service.getCurrentPhase(const TimeOfDay(hour: 9, minute: 0)),
          ShiftPhaseType.quietHours);
      expect(service.getCurrentPhase(const TimeOfDay(hour: 10, minute: 59)),
          ShiftPhaseType.quietHours);
    });

    test('11:00-12:00 is the transition window', () {
      expect(service.getCurrentPhase(const TimeOfDay(hour: 11, minute: 0)),
          ShiftPhaseType.transition);
      expect(service.getCurrentPhase(const TimeOfDay(hour: 11, minute: 59)),
          ShiftPhaseType.transition);
    });

    test('12:00-14:00 is peak hours', () {
      expect(service.getCurrentPhase(const TimeOfDay(hour: 12, minute: 0)),
          ShiftPhaseType.peakHours);
      expect(service.getCurrentPhase(const TimeOfDay(hour: 13, minute: 59)),
          ShiftPhaseType.peakHours);
      expect(service.getCurrentPhase(const TimeOfDay(hour: 14, minute: 0)),
          ShiftPhaseType.standard);
    });

    test('task-level classification matches the window boundaries', () {
      expect(service.isTaskInQuietHours(_taskAt('09:30')), isTrue);
      expect(service.isTaskInQuietHours(_taskAt('11:00')), isFalse);
      expect(service.isTaskInTransition(_taskAt('11:30')), isTrue);
      expect(service.isTaskInPeakHours(_taskAt('12:30')), isTrue);
      expect(service.isTaskInPeakHours(_taskAt('14:00')), isFalse);
    });
  });

  group('ShiftScheduleService - user-defined windows (feature 3)', () {
    test('loadCustomWindows applies stored quiet/peak hours', () async {
      SharedPreferences.setMockInitialValues({
        'quiet_start_h': 8,
        'quiet_start_m': 30,
        'quiet_end_h': 10,
        'quiet_end_m': 15,
        'peak_start_h': 11,
        'peak_start_m': 45,
        'peak_end_h': 13,
        'peak_end_m': 30,
      });

      final service = ShiftScheduleService.instance;
      await service.loadCustomWindows();

      expect(service.quietStart, const TimeOfDay(hour: 8, minute: 30));
      expect(service.quietEnd, const TimeOfDay(hour: 10, minute: 15));
      expect(service.peakStart, const TimeOfDay(hour: 11, minute: 45));
      expect(service.peakEnd, const TimeOfDay(hour: 13, minute: 30));

      // Classification now follows the user's own traffic pattern.
      expect(service.getCurrentPhase(const TimeOfDay(hour: 9, minute: 0)),
          ShiftPhaseType.quietHours);
      expect(service.getCurrentPhase(const TimeOfDay(hour: 12, minute: 0)),
          ShiftPhaseType.peakHours);

      // Empty preferences keep the defaults (no partial override).
      SharedPreferences.setMockInitialValues({});
      resetShiftWindows();
      await service.loadCustomWindows();
      expect(service.quietStart, const TimeOfDay(hour: 9, minute: 0));
      expect(service.peakStart, const TimeOfDay(hour: 12, minute: 0));
    });
  });

  group('ShiftScheduleService - total planned duration', () {
    final service = ShiftScheduleService.instance;

    test('formats hours and minutes in Indonesian and English', () {
      final tasks = [
        _taskAt('09:00', duration: 60),
        _taskAt('10:00', duration: 45),
        _taskAt('11:00', duration: 20),
      ];

      expect(service.calculateTotalDuration(tasks, isIndonesian: true),
          '2j 5m');
      expect(service.calculateTotalDuration(tasks, isIndonesian: false),
          '2h 5m');
    });

    test('handles whole hours and minute-only totals', () {
      expect(
        service.calculateTotalDuration(
          [_taskAt('09:00', duration: 120)],
          isIndonesian: false,
        ),
        '2h',
      );
      expect(
        service.calculateTotalDuration(
          [_taskAt('09:00', duration: 25)],
          isIndonesian: true,
        ),
        '25m',
      );
      expect(service.calculateTotalDuration(const [], isIndonesian: true), '0m');
    });
  });

  group('ShiftScheduleService - saving user windows (feature 3)', () {
    test('updateWindows persists a valid window set', () async {
      SharedPreferences.setMockInitialValues({});
      resetShiftWindows();

      final service = ShiftScheduleService.instance;
      final saved = await service.updateWindows(
        quietStart: const TimeOfDay(hour: 8, minute: 0),
        quietEnd: const TimeOfDay(hour: 10, minute: 0),
        peakStart: const TimeOfDay(hour: 11, minute: 30),
        peakEnd: const TimeOfDay(hour: 13, minute: 0),
      );

      expect(saved, isTrue);
      expect(service.quietStart, const TimeOfDay(hour: 8, minute: 0));
      expect(service.peakEnd, const TimeOfDay(hour: 13, minute: 0));

      // Reload from preferences (what the splash screen does on next launch).
      resetShiftWindows();
      await service.loadCustomWindows();
      expect(service.quietStart, const TimeOfDay(hour: 8, minute: 0));
      expect(service.peakStart, const TimeOfDay(hour: 11, minute: 30));
    });

    test('updateWindows rejects invalid ordering and keeps the old values',
        () async {
      SharedPreferences.setMockInitialValues({});
      resetShiftWindows();

      final service = ShiftScheduleService.instance;
      final saved = await service.updateWindows(
        // Quiet window would end after the peak window starts.
        quietEnd: const TimeOfDay(hour: 13, minute: 0),
      );

      expect(saved, isFalse);
      expect(service.quietEnd, const TimeOfDay(hour: 11, minute: 0));
      expect(service.peakStart, const TimeOfDay(hour: 12, minute: 0));
    });

    test('loadCustomWindows ignores stored windows with invalid ordering',
        () async {
      SharedPreferences.setMockInitialValues({
        'quiet_start_h': 12,
        'quiet_start_m': 0,
        'quiet_end_h': 13,
        'quiet_end_m': 0,
        'peak_start_h': 9,
        'peak_start_m': 0,
        'peak_end_h': 10,
        'peak_end_m': 0,
      });

      resetShiftWindows();
      final service = ShiftScheduleService.instance;
      await service.loadCustomWindows();

      // Defaults survive a corrupted/misordered preference set.
      expect(service.quietStart, const TimeOfDay(hour: 9, minute: 0));
      expect(service.peakStart, const TimeOfDay(hour: 12, minute: 0));
    });

    test('formatWindow and peak/quiet helpers use the active windows', () async {
      SharedPreferences.setMockInitialValues({});
      resetShiftWindows();
      final service = ShiftScheduleService.instance;

      expect(service.formatWindow(service.quietStart, service.quietEnd),
          '09:00-11:00');
      expect(service.isTimeInPeakWindow(const TimeOfDay(hour: 12, minute: 30)),
          isTrue);
      expect(service.isTimeInPeakWindow(const TimeOfDay(hour: 11, minute: 59)),
          isFalse);
      expect(service.isTimeInQuietWindow(const TimeOfDay(hour: 9, minute: 59)),
          isTrue);
      expect(service.isTimeInQuietWindow(const TimeOfDay(hour: 11, minute: 0)),
          isFalse);
    });
  });

  group('ShiftPhase - default presets', () {
    test('quiet and peak presets match the documented windows', () {
      expect(ShiftPhase.defaultQuietHours.containsTime(
          const TimeOfDay(hour: 9, minute: 30)), isTrue);
      expect(ShiftPhase.defaultQuietHours.containsTime(
          const TimeOfDay(hour: 11, minute: 30)), isFalse);
      expect(ShiftPhase.defaultPeakHours.containsTime(
          const TimeOfDay(hour: 13, minute: 0)), isTrue);
      expect(ShiftPhase.defaultPeakHours.containsTime(
          const TimeOfDay(hour: 15, minute: 0)), isFalse);
    });
  });
}
