import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/schedule_timeline_screen.dart';
import 'package:dapur_flow/screens/settings_screen.dart';
import 'package:dapur_flow/screens/task_input_screen.dart';
import 'package:dapur_flow/services/shift_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

/// Proposal conformance checks for the three gaps that used to exist:
///  * users can now enter their own quiet/peak hours (proposal §4.3),
///  * the schedule tab shows those time windows (proposal §4.3),
///  * tasks can be assigned to a staff member (proposal §4.4).
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
  });

  testWidgets(
    'proposal 4.3: settings let the owner set quiet and peak hours',
    (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(tester, home: const SettingsScreen(), provider: provider);

      expect(find.text('Jam Operasional'), findsOneWidget);
      expect(find.text('Jam Tenang (Persiapan)'), findsOneWidget);
      expect(find.text('Jam Sibuk (Layanan)'), findsOneWidget);
      // Both windows are editable: start/end buttons for each.
      expect(find.textContaining('Mulai 09:00'), findsOneWidget);
      expect(find.textContaining('Selesai 11:00'), findsOneWidget);
      expect(find.textContaining('Mulai 12:00'), findsOneWidget);
      expect(find.textContaining('Selesai 14:00'), findsOneWidget);
    },
  );

  testWidgets(
    'proposal 4.3: schedule tab summarises tasks per quiet/peak window',
    (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Siapkan sambal',
        targetTime: '09:30',
        quadrant: PriorityQuadrant.schedule,
      ));
      await provider.addTask(sampleTask(
        title: 'Layani pesanan',
        targetTime: '12:30',
        quadrant: PriorityQuadrant.doFirst,
      ));

      await pumpTestApp(tester, home: const ScheduleTimelineScreen(), provider: provider);

      expect(find.text('Jam Operasional'), findsOneWidget);
      expect(find.textContaining('Jam Tenang (Persiapan) • 09:00-11:00'), findsOneWidget);
      expect(find.textContaining('Jam Sibuk (Layanan) • 12:00-14:00'), findsOneWidget);
      // One task in the quiet window, one in the peak window.
      expect(find.text('1 tugas'), findsWidgets);
    },
  );

  testWidgets(
    'proposal 4.4: tasks can be assigned to a staff member',
    (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpPushedScreen(tester, const TaskInputScreen(), provider: provider);

      // Title, duration and assignee are editable fields.
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Ditugaskan Kepada (opsional)'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Cuci gelas');
      await tester.enterText(find.byType(TextFormField).at(2), 'Sari');
      await tester.tap(find.text('✓ Simpan Tugas'));
      await tester.pumpAndSettle();

      expect(provider.tasks.single.assignee, 'Sari');
    },
  );

  testWidgets(
    'proposal 4.3: planning prep work inside peak hours shows a suggestion '
    'and one tap moves it to the quiet window',
    (tester) async {
      // Make the form's default 09:30 fall inside the peak window.
      final saved = await ShiftScheduleService.instance.updateWindows(
        quietStart: const TimeOfDay(hour: 7, minute: 0),
        quietEnd: const TimeOfDay(hour: 8, minute: 0),
        peakStart: const TimeOfDay(hour: 9, minute: 0),
        peakEnd: const TimeOfDay(hour: 10, minute: 0),
      );
      expect(saved, isTrue);

      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpPushedScreen(tester, const TaskInputScreen(), provider: provider);

      // 09:30 is now peak time -> suggestion card appears.
      expect(find.text('Jadwal ini jatuh di jam sibuk'), findsOneWidget);
      expect(
        find.textContaining('Pindahkan ke jam tenang (07:00-08:00)'),
        findsOneWidget,
      );

      await tester.tap(find.text('Pindahkan ke 07:00'));
      await tester.pumpAndSettle();

      // Suggestion disappears because the slot is now inside quiet hours.
      expect(find.text('Jadwal ini jatuh di jam sibuk'), findsNothing);
      expect(find.text('07:00'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Siapkan bumbu');
      await tester.tap(find.text('✓ Simpan Tugas'));
      await tester.pumpAndSettle();

      expect(provider.tasks.single.targetTime, '07:00');
    },
  );
}
