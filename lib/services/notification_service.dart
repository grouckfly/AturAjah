import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';
import 'settings_service.dart';
import 'vibration_service.dart';

/// Offline exact alarm and local notification engine for kitchen shift tasks.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  static const String channelIdVibrate = 'flow_alarm_v4_with_vibration';
  static const String channelIdNoVibrate = 'flow_alarm_v4_no_vibration';
  static int _testCounter = 0;
  Timer? _autoCancelTimer;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Stream controller to notify UI when a reminder notification is opened
  final StreamController<int> _onNotificationClickStream =
      StreamController<int>.broadcast();

  Stream<int> get onNotificationClick => _onNotificationClickStream.stream;

  NotificationService._internal();

  /// Initialize local notification channels and timezone database
  Future<void> initialize() async {
    // Initialize timezone database for exact scheduling
    tz.initializeTimeZones();

    // Android notification setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS notification setup
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final taskId = int.tryParse(response.payload!);
          if (taskId != null) {
            _onNotificationClickStream.add(taskId);
          }
        }
      },
    );

    // Request permissions on Android 13+
    await _requestPermissions();

    // Setup separate vibration channels to guarantee Android OS honors user preference
    await _setupNotificationChannels();
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  /// Explicitly create dual channels: with vibration & without vibration
  Future<void> _setupNotificationChannels() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Clean up legacy channels to prevent Android caching old vibration behaviors
      try {
        await androidImplementation.deleteNotificationChannel('flow_alarm_channel');
        await androidImplementation.deleteNotificationChannel('flow_alarm_channel_v1');
        await androidImplementation.deleteNotificationChannel('flow_alarm_channel_v2');
        await androidImplementation.deleteNotificationChannel('flow_alarm_v3_with_vibration');
        await androidImplementation.deleteNotificationChannel('flow_alarm_v3_no_vibration');
      } catch (_) {}

      // Continuous rhythmic alarm pattern: delay 0ms, vibrate 800ms, pause 400ms (repeats for 30s)
      final Int64List alarmVibrationPattern = Int64List.fromList([
        0, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
        800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
        800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
        800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
      ]);

      // Channel 1: With vibration (standard alarm ringtone & continuous repeating alarm vibration)
      final AndroidNotificationChannel vibrateChannel =
          AndroidNotificationChannel(
        channelIdVibrate,
        'Pengingat Tugas AturAjah (Dengan Getar)',
        description:
            'Alarm waktu tugas menggunakan nada dering dan getaran berulang standar perangkat',
        importance: Importance.max,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const UriAndroidNotificationSound(
            'content://settings/system/alarm_alert'),
        enableVibration: true,
        vibrationPattern: alarmVibrationPattern,
      );

      // Channel 2: Without vibration (alarm ringtone with zero vibration)
      final AndroidNotificationChannel noVibrateChannel =
          AndroidNotificationChannel(
        channelIdNoVibrate,
        'Pengingat Tugas AturAjah (Tanpa Getar)',
        description: 'Alarm waktu tugas menggunakan nada dering tanpa getaran',
        importance: Importance.max,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const UriAndroidNotificationSound(
            'content://settings/system/alarm_alert'),
        enableVibration: false,
        vibrationPattern: Int64List.fromList([0]),
      );

      await androidImplementation.createNotificationChannel(vibrateChannel);
      await androidImplementation.createNotificationChannel(noVibrateChannel);
    }
  }

  /// Channel configuration for high-priority alarms using device default alarm sound & vibration
  NotificationDetails _notificationDetails(
      {required String title, required String body}) {
    final settings = SettingsService.instance;
    final isVibrate = settings.vibrationEnabled;

    final String channelId = isVibrate ? channelIdVibrate : channelIdNoVibrate;
    final String channelName = isVibrate
        ? 'Pengingat Tugas AturAjah (Dengan Getar)'
        : 'Pengingat Tugas AturAjah (Tanpa Getar)';

    final Int64List continuousVibrationPattern = Int64List.fromList([
      0, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
      800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
      800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
      800, 400, 800, 400, 800, 400, 800, 400, 800, 400,
    ]);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: isVibrate
          ? 'Alarm waktu tugas menggunakan nada dering dan getar alarm berulang standar perangkat'
          : 'Alarm waktu tugas menggunakan nada dering tanpa getaran',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert'),
      enableVibration: isVibrate,
      vibrationPattern:
          isVibrate ? continuousVibrationPattern : Int64List.fromList([0]),
      fullScreenIntent: true, // Wake device screen for alarm urgency
      visibility: NotificationVisibility.public,
      ticker: 'AturAjah Task Alarm',
      onlyAlertOnce: false, // Ensures repetitive alerts are not silenced
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
  }

  /// Schedule an exact notification for a task at its targetTime
  Future<void> scheduleTaskAlarm(TaskModel task) async {
    if (task.id == null || task.isCompleted) return;

    try {
      final now = DateTime.now();
      final tod = task.timeOfDay;
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        tod.hour,
        tod.minute,
      );

      // If scheduled time has already passed today by more than 1 minute, don't trigger past alarm
      if (scheduledDate.isBefore(now)) {
        // Only schedule if it's within the next few seconds or user rescheduled
        return;
      }

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notificationsPlugin.zonedSchedule(
        task.id!,
        'AturAjah: ${task.title}',
        'Waktunya mengerjakan: ${task.targetTime} • ${task.durationMinutes} menit',
        tzScheduled,
        _notificationDetails(
          title: task.title,
          body: 'Target: ${task.targetTime}',
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  /// Schedule a snooze repeating alarm after N minutes
  Future<void> scheduleSnoozeAlarm(TaskModel task, int snoozeMinutes) async {
    if (task.id == null) return;

    await cancelTaskAlarm(task.id!);

    try {
      final scheduledDate =
          DateTime.now().add(Duration(minutes: snoozeMinutes));
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notificationsPlugin.zonedSchedule(
        task.id!,
        'PENGINGAT BERULANG (Snooze): ${task.title}',
        'Tugas ditunda. Waktu pengerjaan sekarang! (${task.durationMinutes} mnt)',
        tzScheduled,
        _notificationDetails(
          title: task.title,
          body: 'Snoozed alarm',
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling snooze: $e');
      }
    }
  }

  /// Immediately trigger notification (for test alert / preview CTA)
  Future<void> triggerImmediateNotification(TaskModel task,
      {int? durationSeconds}) async {
    _autoCancelTimer?.cancel();

    int id;
    if (task.id == null || task.id == 9998) {
      // Rotating notification ID so Android treats every spam test as a fresh notification
      final prevId = 9900 + (_testCounter % 10);
      try {
        await _notificationsPlugin.cancel(prevId);
      } catch (_) {}
      _testCounter++;
      id = 9900 + (_testCounter % 10);
    } else {
      id = task.id!;
      try {
        await _notificationsPlugin.cancel(id);
      } catch (_) {}
    }

    await _notificationsPlugin.show(
      id,
      'PERINGATAN WAKTU: ${task.title}',
      'Target: ${task.targetTime} • Durasi: ${task.durationMinutes} menit',
      _notificationDetails(
        title: task.title,
        body: 'Target: ${task.targetTime}',
      ),
      payload: id.toString(),
    );

    // Auto dismiss notification and stop vibration when alarm duration finishes
    // If duration <= 0, it rings continuously until user taps stop button
    final duration =
        durationSeconds ?? SettingsService.instance.alarmDurationSeconds;
    if (duration > 0) {
      _autoCancelTimer = Timer(Duration(seconds: duration), () {
        cancelTaskAlarm(id);
        VibrationService.cancel();
      });
    }
  }

  /// Cancel all test notifications and stop test vibration
  Future<void> cancelTestAlarms() async {
    _autoCancelTimer?.cancel();
    _autoCancelTimer = null;
    for (int i = 0; i < 15; i++) {
      try {
        await _notificationsPlugin.cancel(9900 + i);
      } catch (_) {}
    }
    try {
      await _notificationsPlugin.cancel(9998);
    } catch (_) {}
    await VibrationService.cancel();
  }

  /// Cancel notification for a task (when marked as done or deleted)
  Future<void> cancelTaskAlarm(int taskId) async {
    try {
      await _notificationsPlugin.cancel(taskId);
      await VibrationService.cancel();
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling notification: $e');
      }
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAll() async {
    _autoCancelTimer?.cancel();
    _autoCancelTimer = null;
    await _notificationsPlugin.cancelAll();
    await VibrationService.cancel();
  }

  void dispose() {
    _autoCancelTimer?.cancel();
    _autoCancelTimer = null;
    _onNotificationClickStream.close();
  }
}
