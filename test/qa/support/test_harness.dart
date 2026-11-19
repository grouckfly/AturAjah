import 'dart:io';
import 'dart:isolate';

import 'package:dapur_flow/constants/app_theme.dart';
import 'package:dapur_flow/l10n/app_localizations.dart';
import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/models/task_model.dart';
import 'package:dapur_flow/providers/locale_provider.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:dapur_flow/services/notification_service.dart';
import 'package:dapur_flow/services/settings_service.dart';
import 'package:dapur_flow/services/shift_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Channel names used by the app's native bridges.
const String notificationChannelName = 'dexterous.com/flutter/local_notifications';
const String nativeAlarmChannelName = 'com.aturajah.app/vibrate';

/// Records every platform-channel call the app makes so the tests can verify
/// that alarms/notifications are actually requested by the production code.
class PlatformCallRecorder {
  final List<MethodCall> notifications = [];
  final List<MethodCall> nativeAlarms = [];

  /// Simulates an Android device where exact alarms are not permitted: the next
  /// exact `zonedSchedule` call fails with `exact_alarms_not_permitted`.
  bool throwExactAlarmErrorOnce = false;

  void clear() {
    notifications.clear();
    nativeAlarms.clear();
    throwExactAlarmErrorOnce = false;
  }

  Iterable<MethodCall> callsNamed(String method) =>
      notifications.where((call) => call.method == method);
}

final PlatformCallRecorder platformCalls = PlatformCallRecorder();

/// Replaces the Android/iOS plugins with in-memory fakes so the app can run on
/// the Dart VM (no device required) while still exercising the real code paths.
void installMockPlatformChannels() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel(notificationChannelName),
    (call) async {
      platformCalls.notifications.add(call);
      switch (call.method) {
        case 'zonedSchedule':
          final specifics = call.arguments['platformSpecifics'] as Map?;
          final mode = specifics?['scheduleMode'] as String?;
          if (platformCalls.throwExactAlarmErrorOnce &&
              mode == 'exactAllowWhileIdle') {
            platformCalls.throwExactAlarmErrorOnce = false;
            throw PlatformException(
              code: 'exact_alarms_not_permitted',
              message: 'Exact alarms are not permitted',
            );
          }
          return null;
        case 'initialize':
          return true;
        case 'getNotificationAppLaunchDetails':
          return <String, Object?>{'notificationLaunchedApp': false};
        case 'getActiveNotifications':
        case 'pendingNotificationRequests':
        case 'pendingNotificationRequestCount':
          return <Object?>[];
        case 'canScheduleExactNotifications':
          return true;
        case 'requestNotificationsPermission':
        case 'requestExactAlarmsPermission':
          return true;
        default:
          return null;
      }
    },
  );

  messenger.setMockMethodCallHandler(
    const MethodChannel(nativeAlarmChannelName),
    (call) async {
      platformCalls.nativeAlarms.add(call);
      return null;
    },
  );
}

/// Boots sqflite on the Dart VM and gives this test isolate its own database
/// directory, so `flutter test` can run several files in parallel without them
/// fighting over the same SQLite file.
Future<void> configureTestDatabase() async {
  sqfliteFfiInit();
  // The no-isolate factory runs sqlite3 synchronously in the current isolate.
  // That matters for widget tests: their FakeAsync zone never completes futures
  // that depend on a background isolate, which would hang `pumpAndSettle`.
  databaseFactory = databaseFactoryFfiNoIsolate;

  final dir = Directory(
    '${Directory.current.path}/.dart_tool/qa_db/${pid}_${Isolate.current.hashCode}',
  );
  await dir.create(recursive: true);
  await databaseFactory.setDatabasesPath(dir.path);
}

/// Shared test environment for the AturAjah QA suite.
///
/// Runs the real widget tree against a real SQLite database (sqlite3 via FFI)
/// so that the checks exercise production code instead of hand-written mocks.
Future<void> initTestEnvironment({Map<String, Object>? prefs}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await configureTestDatabase();
  installMockPlatformChannels();
  // Production runs this inside NotificationService.initialize() on the splash
  // screen; tests need it too or `tz.local` throws LateInitializationError.
  tzdata.initializeTimeZones();

  SharedPreferences.setMockInitialValues(prefs ?? <String, Object>{});
  await SettingsService.instance.loadSettings();
  await clearTasks();
  resetShiftWindows();
  platformCalls.clear();
  // Never leave long one-shot timers behind in fake-async widget tests.
  TaskProvider.inAppReminderTimersEnabled = false;
  // Alarm tests must run against the real clock: the notification plugin
  // validates that the scheduled instant is in the future.
  NotificationService.instance.nowProvider = DateTime.now;
}

Future<void> clearTasks() async {
  final db = await DatabaseHelper.instance.database;
  await db.delete('tasks');
}

void resetShiftWindows() {
  final shift = ShiftScheduleService.instance;
  shift.quietStart = const TimeOfDay(hour: 9, minute: 0);
  shift.quietEnd = const TimeOfDay(hour: 11, minute: 0);
  shift.peakStart = const TimeOfDay(hour: 12, minute: 0);
  shift.peakEnd = const TimeOfDay(hour: 14, minute: 0);
}

String todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// `HH:mm` of a moment a little later **today** (null when the day is too short).
///
/// Alarm scheduling always targets today's date, so tests must pick a time that
/// is still in the future on the same calendar day.
String? futureToday([Duration offset = const Duration(minutes: 2)]) {
  final now = DateTime.now();
  final moment = now.add(offset);
  if (moment.day != now.day) return null;
  return '${moment.hour.toString().padLeft(2, '0')}:'
      '${moment.minute.toString().padLeft(2, '0')}';
}

/// `HH:mm` of a moment a little earlier **today** (null at exactly 00:00).
String? pastToday([Duration offset = const Duration(minutes: 2)]) {
  final now = DateTime.now();
  final moment = now.subtract(offset);
  if (moment.day != now.day) return null;
  return '${moment.hour.toString().padLeft(2, '0')}:'
      '${moment.minute.toString().padLeft(2, '0')}';
}

TaskModel sampleTask({
  String title = 'Potong sayuran',
  String targetTime = '09:30',
  int durationMinutes = 30,
  PriorityQuadrant quadrant = PriorityQuadrant.doFirst,
  bool isCompleted = false,
  String? assignee,
}) {
  return TaskModel(
    title: title,
    targetTime: targetTime,
    durationMinutes: durationMinutes,
    assignee: assignee,
    priorityQuadrant: quadrant,
    isCompleted: isCompleted,
    createdAt: todayIso(),
  );
}

/// Boots a MaterialApp wired with the same providers/delegates as `main.dart`.
Widget buildTestApp({
  required Widget home,
  TaskProvider? provider,
  Locale locale = const Locale('id', 'ID'),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider<TaskProvider>.value(value: provider ?? TaskProvider()),
      ChangeNotifierProvider<SettingsService>.value(value: SettingsService.instance),
    ],
    child: MaterialApp(
      title: 'AturAjah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

/// Pumps [buildTestApp] on a 520x1000 dp viewport. The extra width keeps the
/// platform-default font fallback (square-glyph Ahem inside flutter_test) from
/// reporting overflows that real device fonts never produce.
Future<void> pumpTestApp(
  WidgetTester tester, {
  required Widget home,
  TaskProvider? provider,
  Locale locale = const Locale('id', 'ID'),
}) async {
  tester.view.physicalSize = const Size(1560, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    buildTestApp(home: home, provider: provider, locale: locale),
  );
  await tester.pumpAndSettle();
}

/// Pushes [screen] on top of a placeholder route so `Navigator.pop()` works.
Future<void> pumpPushedScreen(
  WidgetTester tester,
  Widget screen, {
  TaskProvider? provider,
}) async {
  tester.view.physicalSize = const Size(1560, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    buildTestApp(
      provider: provider,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => screen),
              ),
              child: const Text('__open__'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('__open__'));
  await tester.pumpAndSettle();
}

/// Deletes the on-disk test database (used by the slow integration checks).
Future<void> deleteTestDatabase() async {
  try {
    final path = await databaseFactory.getDatabasesPath();
    final file = File('$path/atur_ajah.db');
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Best effort only.
  }
}
