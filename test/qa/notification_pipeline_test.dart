import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/services/notification_service.dart';
import 'package:dapur_flow/services/settings_service.dart';
import 'package:dapur_flow/services/vibration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/test_harness.dart';

/// Proposal Feature 4 (reminders):
/// the app must register an exact alarm for every pending task, cancel it when
/// the task is finished, and drive the native alarm/vibration bridge.
///
/// The Android plugin is replaced by a recording fake (see test_harness.dart),
/// so these assertions describe the calls the production code really makes.
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
    platformCalls.clear();
  });

  /// Alarm scheduling always targets *today*, so the suite needs a time later
  /// today. In the last minutes before midnight that is impossible, and the
  /// test is marked skipped instead of failing spuriously.
  String? futureOrSkip() {
    final time = futureToday();
    if (time == null) {
      markTestSkipped('Terlalu dekat tengah malam untuk alarm uji.');
    }
    return time;
  }

  group('NotificationService - exact alarm scheduling', () {
    test('a future task registers a zoned alarm with the task id', () async {
      final targetTime = futureOrSkip();
      if (targetTime == null) return;

      final provider = TaskProvider();
      await provider.loadTasks();

      await provider.addTask(sampleTask(
        title: 'Siapkan isi lemari',
        targetTime: targetTime,
      ));
      final task = provider.tasks.single;

      final scheduled = platformCalls.callsNamed('zonedSchedule').toList();
      expect(scheduled, isNotEmpty);
      expect(scheduled.last.arguments['id'], task.id);
      expect(scheduled.last.arguments['payload'], task.id.toString());
    });

    test('the alarm is registered in the device timezone, not in UTC', () async {
      final targetTime = futureOrSkip();
      if (targetTime == null) return;

      final provider = TaskProvider();
      await provider.loadTasks();

      await provider.addTask(
        sampleTask(title: 'Cek zona waktu', targetTime: targetTime),
      );

      final call = platformCalls.callsNamed('zonedSchedule').last;
      final zoneName = call.arguments['timeZoneName'] as String;
      final zone = tz.getLocation(zoneName);

      // The zone the alarm is registered in must match the phone offset;
      // scheduling in UTC shifted every reminder by hours.
      expect(
        tz.TZDateTime.now(zone).timeZoneOffset,
        DateTime.now().timeZoneOffset,
      );
      expect(zoneName, tz.local.name);
      // WIB must resolve to a real Indonesian zone, not an arbitrary one.
      if (DateTime.now().timeZoneOffset == const Duration(hours: 7)) {
        expect(zoneName, 'Asia/Jakarta');
      }

      // The wall clock sent to Android is exactly the task's target time.
      expect(
        (call.arguments['scheduledDateTime'] as String).endsWith(
          'T$targetTime:00',
        ),
        isTrue,
      );
    });

    test('falls back to an inexact alarm when exact alarms are blocked',
        () async {
      final targetTime = futureOrSkip();
      if (targetTime == null) return;

      final provider = TaskProvider();
      await provider.loadTasks();

      platformCalls.clear();
      platformCalls.throwExactAlarmErrorOnce = true;

      await provider.addTask(sampleTask(
        title: 'Tanpa izin exact alarm',
        targetTime: targetTime,
      ));

      final calls = platformCalls.callsNamed('zonedSchedule').toList();
      expect(calls.length, 2, reason: 'harus mencoba ulang dengan mode inexact');
      final retrySpecifics = calls.last.arguments['platformSpecifics'] as Map;
      expect(retrySpecifics['scheduleMode'], 'inexactAllowWhileIdle');
    });

    test('a task whose time already passed is not scheduled in the past',
        () async {
      final targetTime = pastToday();
      if (targetTime == null) {
        markTestSkipped('Tepat tengah malam: tidak ada jam lampau hari ini.');
        return;
      }

      final provider = TaskProvider();
      await provider.loadTasks();

      await provider.addTask(
        sampleTask(title: 'Tugas lewat', targetTime: targetTime),
      );

      expect(platformCalls.callsNamed('zonedSchedule'), isEmpty);
    });

    test('marking a task done cancels its pending alarm', () async {
      final targetTime = futureOrSkip();
      if (targetTime == null) return;

      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Tugas selesai',
        targetTime: targetTime,
      ));
      final task = provider.tasks.single;

      platformCalls.clear();
      await provider.toggleTaskDone(task.id!);

      final cancelled = platformCalls.callsNamed('cancel').toList();
      expect(cancelled, isNotEmpty);
      expect(_cancelTarget(cancelled.last.arguments), task.id);
    });

    test('snoozing cancels the old alarm and schedules a new one', () async {
      final targetTime = futureOrSkip();
      if (targetTime == null) return;

      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Tunda alarm',
        targetTime: targetTime,
      ));
      final task = provider.tasks.single;

      platformCalls.clear();
      await provider.snoozeTask(task.id!, 5);

      final cancelled = platformCalls.callsNamed('cancel').toList();
      final rescheduled = platformCalls.callsNamed('zonedSchedule').toList();
      expect(cancelled, isNotEmpty);
      expect(rescheduled, isNotEmpty);
      expect(rescheduled.last.arguments['id'], task.id);
    });

    test('deleting a task cancels its alarm', () async {
      final targetTime = futureOrSkip();
      if (targetTime == null) return;

      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Hapus alarm',
        targetTime: targetTime,
      ));
      final task = provider.tasks.single;

      platformCalls.clear();
      await provider.deleteTask(task.id!);

      expect(platformCalls.callsNamed('cancel'), isNotEmpty);
    });

    test('restoring a task re-registers its alarm', () async {
      final targetTime = futureOrSkip();
      if (targetTime == null) return;

      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Batal selesai',
        targetTime: targetTime,
      ));
      final task = provider.tasks.single;

      await provider.toggleTaskDone(task.id!);
      platformCalls.clear();
      await provider.toggleTaskDone(task.id!);

      final rescheduled = platformCalls.callsNamed('zonedSchedule').toList();
      expect(rescheduled, isNotEmpty);
      expect(rescheduled.last.arguments['id'], task.id);
    });
  });

  group('Native alarm bridge', () {
    test('startAlarm and stopAlarm reach the native channel', () async {
      await VibrationService.startAlarm(durationSeconds: 15);
      await VibrationService.stopAlarm();

      final methods = platformCalls.nativeAlarms.map((c) => c.method).toList();
      expect(methods, contains('startAlarm'));
      expect(methods, contains('stopAlarm'));

      final start = platformCalls.nativeAlarms
          .firstWhere((c) => c.method == 'startAlarm')
          .arguments as Map;
      expect(start['durationSeconds'], 15);
      expect(start['withAudio'], isTrue);
    });

    test('vibration is suppressed when the user turns it off', () async {
      await SettingsService.instance.setVibrationEnabled(false);
      await VibrationService.startAlarm(durationSeconds: 15);
      final off = platformCalls.nativeAlarms
          .firstWhere((c) => c.method == 'startAlarm')
          .arguments as Map;
      expect(off['withVibration'], isFalse);

      await SettingsService.instance.setVibrationEnabled(true);
      platformCalls.nativeAlarms.clear();
      await VibrationService.startAlarm(durationSeconds: 15);
      final on = platformCalls.nativeAlarms
          .firstWhere((c) => c.method == 'startAlarm')
          .arguments as Map;
      expect(on['withVibration'], isTrue);
      await VibrationService.stopAlarm();
    });

    test('immediate test notification is shown and then cancelled', () async {
      final task = sampleTask(title: 'Uji alarm', targetTime: 'Sekarang');
      await NotificationService.instance
          .triggerImmediateNotification(task, durationSeconds: 15);

      expect(platformCalls.callsNamed('show'), isNotEmpty);

      await NotificationService.instance.cancelTestAlarms();
      expect(platformCalls.callsNamed('cancel'), isNotEmpty);
    });
  });
}

/// `cancel` is called with either a bare id or a `{id: ...}` map depending on
/// the plugin version; normalise both shapes.
Object? _cancelTarget(Object? arguments) {
  if (arguments is Map) return arguments['id'] ?? arguments['notificationId'];
  return arguments;
}
