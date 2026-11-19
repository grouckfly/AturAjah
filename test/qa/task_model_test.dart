import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proposal Feature 1 (Task input) + Feature 2 (Prioritization):
/// the data model must carry title, target time, duration, priority quadrant
/// and survive a SQLite round-trip unchanged.
void main() {
  group('TaskModel - field mapping required by proposal feature 1 & 2', () {
    test('exposes title, target time, duration and priority quadrant', () {
      const task = TaskModel(
        title: 'Siapkan bumbu',
        targetTime: '09:15',
        durationMinutes: 45,
        priorityQuadrant: PriorityQuadrant.schedule,
        createdAt: '2026-11-18',
      );

      expect(task.title, 'Siapkan bumbu');
      expect(task.targetTime, '09:15');
      expect(task.durationMinutes, 45);
      expect(task.priorityQuadrant, PriorityQuadrant.schedule);
      expect(task.isCompleted, isFalse);
      expect(task.snoozeCount, 0);
    });

    test('toMap/fromMap round-trip keeps every column', () {
      const task = TaskModel(
        id: 7,
        title: 'Cuci piring',
        targetTime: '13:05',
        durationMinutes: 20,
        assignee: 'Sari',
        priorityQuadrant: PriorityQuadrant.delegate,
        isCompleted: true,
        snoozeCount: 2,
        createdAt: '2026-11-18',
      );

      final restored = TaskModel.fromMap(task.toMap());

      expect(restored.id, 7);
      expect(restored.title, 'Cuci piring');
      expect(restored.targetTime, '13:05');
      expect(restored.durationMinutes, 20);
      expect(restored.assignee, 'Sari');
      expect(restored.priorityQuadrant, PriorityQuadrant.delegate);
      expect(restored.isCompleted, isTrue);
      expect(restored.snoozeCount, 2);
      expect(restored.createdAt, '2026-11-18');
    });

    test('legacy rows without snooze_count default to 0', () {
      final restored = TaskModel.fromMap({
        'id': 1,
        'title': 'Restock gula',
        'target_time': '16:00',
        'duration_minutes': 15,
        'assignee': null,
        'priority_quadrant': 2,
        'is_completed': 0,
        'snooze_count': null,
        'created_at': '2026-11-18',
      });

      expect(restored.snoozeCount, 0);
      expect(restored.priorityQuadrant, PriorityQuadrant.schedule);
    });
  });

  group('TaskModel - time helpers used for scheduling', () {
    test('timeOfDay parses HH:mm', () {
      const task = TaskModel(
        title: 'x',
        targetTime: '07:40',
        durationMinutes: 10,
        priorityQuadrant: PriorityQuadrant.doFirst,
        createdAt: '2026-11-18',
      );

      expect(task.timeOfDay, const TimeOfDay(hour: 7, minute: 40));
      expect(task.minutesSinceMidnight, 7 * 60 + 40);
    });

    test('malformed target time falls back to 09:00 instead of crashing', () {
      const task = TaskModel(
        title: 'x',
        targetTime: 'not-a-time',
        durationMinutes: 10,
        priorityQuadrant: PriorityQuadrant.doFirst,
        createdAt: '2026-11-18',
      );

      expect(task.timeOfDay, const TimeOfDay(hour: 9, minute: 0));
    });

    test('copyWith only changes the requested fields', () {
      const task = TaskModel(
        id: 3,
        title: 'Asli',
        targetTime: '10:00',
        durationMinutes: 30,
        assignee: 'Budi',
        priorityQuadrant: PriorityQuadrant.later,
        createdAt: '2026-11-18',
      );

      final updated = task.copyWith(
        title: 'Diubah',
        priorityQuadrant: PriorityQuadrant.doFirst,
      );

      expect(updated.id, 3);
      expect(updated.title, 'Diubah');
      expect(updated.priorityQuadrant, PriorityQuadrant.doFirst);
      expect(updated.assignee, 'Budi');
      expect(updated.targetTime, '10:00');
      expect(updated.durationMinutes, 30);
    });
  });

  group('PriorityQuadrant - Eisenhower matrix mapping (feature 2)', () {
    test('maps the four proposal categories to stable integer values', () {
      expect(PriorityQuadrant.doFirst.value, 1);
      expect(PriorityQuadrant.schedule.value, 2);
      expect(PriorityQuadrant.delegate.value, 3);
      expect(PriorityQuadrant.later.value, 4);
    });

    test('fromInt round-trips and clamps unknown ids', () {
      for (final quadrant in PriorityQuadrant.values) {
        expect(PriorityQuadrant.fromInt(quadrant.value), quadrant);
      }
      expect(PriorityQuadrant.fromInt(99), PriorityQuadrant.doFirst);
      expect(PriorityQuadrant.fromInt(0), PriorityQuadrant.doFirst);
    });
  });
}
