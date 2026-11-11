import 'package:flutter/material.dart';

enum ShiftPhaseType {
  quietHours,
  transition,
  peakHours,
  standard,
}

/// Represents current or scheduled shift period in kitchen operations.
class ShiftPhase {
  final ShiftPhaseType type;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String labelId;
  final String labelEn;
  final String descriptionId;
  final String descriptionEn;

  const ShiftPhase({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.labelId,
    required this.labelEn,
    required this.descriptionId,
    required this.descriptionEn,
  });

  bool containsTime(TimeOfDay time) {
    final nowMinutes = time.hour * 60 + time.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  static const ShiftPhase defaultQuietHours = ShiftPhase(
    type: ShiftPhaseType.quietHours,
    startTime: TimeOfDay(hour: 9, minute: 0),
    endTime: TimeOfDay(hour: 11, minute: 0),
    labelId: 'Jam Tenang (Quiet Hours)',
    labelEn: 'Quiet Hours (Prep Time)',
    descriptionId: 'Waktu terbaik persiapan hingga 11:00',
    descriptionEn: 'Optimal prep time until 11:00',
  );

  static const ShiftPhase defaultPeakHours = ShiftPhase(
    type: ShiftPhaseType.peakHours,
    startTime: TimeOfDay(hour: 12, minute: 0),
    endTime: TimeOfDay(hour: 14, minute: 0),
    labelId: 'Jam Sibuk (Peak Hours)',
    labelEn: 'Peak Hours (Rush Time)',
    descriptionId: 'Fokus layanan pelanggan hingga 14:00',
    descriptionEn: 'Focus on customer service until 14:00',
  );
}
