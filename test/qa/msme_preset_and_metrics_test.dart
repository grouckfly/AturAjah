import 'package:dapur_flow/models/msme_preset.dart';
import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/models/task_model.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/widgets/msme_preset_sheet.dart';
import 'package:dapur_flow/widgets/proposal_metrics_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
  });

  group('Proposal MSME Presets', () {
    test('contains all 5 business archetypes from proposal user interviews', () {
      final presets = MsmePreset.presets;
      expect(presets.length, 5);

      final ids = presets.map((p) => p.id).toSet();
      expect(ids, containsAll(['padang', 'nasi_campur', 'gorengan', 'kopi', 'jus']));

      for (final p in presets) {
        expect(p.title.isNotEmpty, isTrue);
        expect(p.tasks.isNotEmpty, isTrue);
        expect(p.icon, isA<IconData>());
        for (final task in p.tasks) {
          expect(task.title.isNotEmpty, isTrue);
          expect(task.durationMinutes, greaterThan(0));
          expect(task.targetTime, matches(RegExp(r'^\d{2}:\d{2}$')));
        }
      }
    });

    testWidgets('MsmePresetSheet renders Material icon badges with no emoji',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpTestApp(
        tester,
        provider: provider,
        home: const Scaffold(body: MsmePresetSheet()),
      );

      for (final p in MsmePreset.presets) {
        expect(find.text(p.title), findsOneWidget);
        expect(find.byIcon(p.icon), findsOneWidget);
      }
    });

    test('applying an MSME preset adds tasks and preserves Eisenhower quadrants', () async {
      final provider = TaskProvider();
      await provider.loadTasks();

      final padangPreset = MsmePreset.presets.firstWhere((p) => p.id == 'padang');

      for (final pt in padangPreset.tasks) {
        await provider.addTask(
          TaskModel(
            title: pt.title,
            targetTime: pt.targetTime,
            durationMinutes: pt.durationMinutes,
            priorityQuadrant: pt.priorityQuadrant,
            assignee: pt.assignee,
            createdAt: '2026-11-24',
          ),
          makeRecurring: true,
        );
      }

      expect(provider.tasks.length, padangPreset.tasks.length);
      expect(provider.templates.length, padangPreset.tasks.length);

      // Verify Do First and Schedule quadrants exist
      expect(
        provider.tasks.any((t) => t.priorityQuadrant == PriorityQuadrant.doFirst),
        isTrue,
      );
      expect(
        provider.tasks.any((t) => t.priorityQuadrant == PriorityQuadrant.schedule),
        isTrue,
      );
      expect(
        provider.tasks.any((t) => t.assignee == 'Koki'),
        isTrue,
      );
    });
  });

  group('Proposal Section 8 Metrics Card', () {
    testWidgets('renders quiet hour prep rate and delay reduction target', (tester) async {
      final sampleTasks = <TaskModel>[
        sampleTask(
          title: 'Persiapan bumbu',
          targetTime: '09:30', // In quiet hours (09:00 - 11:00)
          isCompleted: true,
        ),
        sampleTask(
          title: 'Potong sayur',
          targetTime: '10:00', // In quiet hours
          isCompleted: true,
        ),
        sampleTask(
          title: 'Layanan pelanggan',
          targetTime: '12:30', // In peak hours
          isCompleted: true,
        ).copyWith(snoozeCount: 1), // Snoozed once
      ];

      await pumpTestApp(
        tester,
        home: ProposalMetricsCard(allTasks: sampleTasks),
      );

      // Card title & proposal target badge
      expect(find.text('Evaluasi Kinerja Operasional'), findsOneWidget);
      expect(find.text('Target Proposal'), findsOneWidget);

      // Quiet prep target: 2 out of 2 completed = 100% (target >= 60%)
      expect(find.text('Persiapan Jam Tenang'), findsOneWidget);
      expect(find.text('Target: ≥ 60%'), findsOneWidget);
      expect(find.textContaining('100% (2/2)'), findsOneWidget);

      // Delay reduction & punctuality target
      expect(find.text('Ketepatan Waktu Layanan'), findsOneWidget);
      expect(find.text('Target: ≥ 80% Tepat Waktu'), findsOneWidget);
    });
  });
}
