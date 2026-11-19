import 'package:dapur_flow/models/priority_quadrant.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/task_input_screen.dart';
import 'package:dapur_flow/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

/// Proposal Feature 1 (task input: name, target time, duration) and
/// Feature 2 (priority selection through the Eisenhower matrix),
/// plus the CRUD guarantees the app advertises (create / edit / delete).
void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await clearTasks();
    resetShiftWindows();
  });

  Future<List<Map<String, Object?>>> rows() async {
    final db = await DatabaseHelper.instance.database;
    return db.query('tasks');
  }

  group('Task input screen - create', () {
    testWidgets('saves name, duration and selected quadrant', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpPushedScreen(tester, const TaskInputScreen(), provider: provider);

      expect(find.text('Tugas Baru'), findsOneWidget);
      expect(find.text('Nama Tugas'), findsOneWidget);
      expect(find.text('Target Waktu'), findsOneWidget);
      expect(find.text('Durasi (Menit)'), findsOneWidget);
      expect(find.text('Matriks Prioritas (Eisenhower)'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Siapkan bumbu');
      await tester.enterText(find.byType(TextFormField).at(1), '45');

      // Feature 2: pick the "Delegate" quadrant from the 2x2 matrix.
      await tester.tap(find.text('Delegasikan'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('✓ Simpan Tugas'));
      await tester.tap(find.text('✓ Simpan Tugas'));
      await tester.pumpAndSettle();

      expect(provider.tasks.length, 1);
      final saved = provider.tasks.first;
      expect(saved.id, isNotNull);
      expect(saved.title, 'Siapkan bumbu');
      expect(saved.durationMinutes, 45);
      expect(saved.priorityQuadrant, PriorityQuadrant.delegate);
      expect(saved.targetTime, '09:30'); // default target time
      expect(saved.isCompleted, isFalse);

      final persisted = await rows();
      expect(persisted.length, 1);
      expect(persisted.first['title'], 'Siapkan bumbu');
      expect(find.text('Siapkan bumbu disimpan.'), findsOneWidget);
    });

    testWidgets('blocks empty task name', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpPushedScreen(tester, const TaskInputScreen(), provider: provider);
      await tester.tap(find.text('✓ Simpan Tugas'));
      await tester.pumpAndSettle();

      expect(find.text('Nama tugas tidak boleh kosong'), findsOneWidget);
      expect(provider.tasks, isEmpty);
      expect(await rows(), isEmpty);
    });

    testWidgets('blocks non-positive duration', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpPushedScreen(tester, const TaskInputScreen(), provider: provider);
      await tester.enterText(find.byType(TextFormField).at(0), 'Cuci gelas');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.tap(find.text('✓ Simpan Tugas'));
      await tester.pumpAndSettle();

      expect(find.text('Durasi harus lebih dari 0 menit'), findsOneWidget);
      expect(provider.tasks, isEmpty);
    });

    testWidgets('defaults to the Do First quadrant with a 30 minute duration',
        (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();

      await pumpPushedScreen(tester, const TaskInputScreen(), provider: provider);
      await tester.enterText(find.byType(TextFormField).at(0), 'Buka warung');
      await tester.tap(find.text('✓ Simpan Tugas'));
      await tester.pumpAndSettle();

      final saved = provider.tasks.single;
      expect(saved.priorityQuadrant, PriorityQuadrant.doFirst);
      expect(saved.durationMinutes, 30);
      expect(saved.targetTime, '09:30');
    });
  });

  group('Task input screen - edit & delete', () {
    testWidgets('pre-fills the form and updates the existing row', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(
        title: 'Nama lama',
        targetTime: '10:00',
        durationMinutes: 20,
      ));
      final existing = provider.tasks.single;

      await pumpPushedScreen(
        tester,
        TaskInputScreen(taskToEdit: existing),
        provider: provider,
      );

      expect(find.text('Edit Tugas'), findsOneWidget);
      expect(find.text('Nama lama'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Nama baru');
      await tester.enterText(find.byType(TextFormField).at(1), '75');
      await tester.tap(find.text('Jadwalkan'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('✓ Simpan Perubahan'));
      await tester.tap(find.text('✓ Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(provider.tasks.length, 1);
      final updated = provider.tasks.single;
      expect(updated.id, existing.id);
      expect(updated.title, 'Nama baru');
      expect(updated.durationMinutes, 75);
      expect(updated.priorityQuadrant, PriorityQuadrant.schedule);

      final persisted = await rows();
      expect(persisted.single['title'], 'Nama baru');
      expect(persisted.single['duration_minutes'], 75);
      expect(find.text('Nama baru berhasil diperbarui.'), findsOneWidget);
    });

    testWidgets('deletes the task after confirmation', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Hapus saya'));

      await pumpPushedScreen(
        tester,
        TaskInputScreen(taskToEdit: provider.tasks.single),
        provider: provider,
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Tugas'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin menghapus tugas ini?'),
          findsOneWidget);

      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();

      expect(provider.tasks, isEmpty);
      expect(await rows(), isEmpty);
    });

    testWidgets('keeps the task when deletion is cancelled', (tester) async {
      final provider = TaskProvider();
      await provider.loadTasks();
      await provider.addTask(sampleTask(title: 'Pertahankan saya'));

      await pumpPushedScreen(
        tester,
        TaskInputScreen(taskToEdit: provider.tasks.single),
        provider: provider,
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(provider.tasks.length, 1);
      expect((await rows()).length, 1);
    });
  });
}
