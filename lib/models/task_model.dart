import 'package:flutter/material.dart';
import 'priority_quadrant.dart';

/// Database entity for daily kitchen tasks.
class TaskModel {
  final int? id;
  final String title;
  final String targetTime; // "HH:mm"
  final int durationMinutes;
  final String? assignee;
  final PriorityQuadrant priorityQuadrant;
  final bool isCompleted;
  final int snoozeCount;
  final String createdAt; // "YYYY-MM-DD"

  const TaskModel({
    this.id,
    required this.title,
    required this.targetTime,
    required this.durationMinutes,
    this.assignee,
    required this.priorityQuadrant,
    this.isCompleted = false,
    this.snoozeCount = 0,
    required this.createdAt,
  });

  /// Parse "HH:mm" to TimeOfDay
  TimeOfDay get timeOfDay {
    try {
      final parts = targetTime.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  /// Convert targetTime to today's DateTime
  DateTime get targetDateTimeToday {
    final now = DateTime.now();
    final tod = timeOfDay;
    return DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  }

  /// Minutes since midnight for chronological sorting
  int get minutesSinceMidnight {
    final tod = timeOfDay;
    return tod.hour * 60 + tod.minute;
  }

  /// SQLite serialisation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_time': targetTime,
      'duration_minutes': durationMinutes,
      'assignee': assignee,
      'priority_quadrant': priorityQuadrant.value,
      'is_completed': isCompleted ? 1 : 0,
      'snooze_count': snoozeCount,
      'created_at': createdAt,
    };
  }

  /// Deserialisation from SQLite
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      targetTime: map['target_time'] as String,
      durationMinutes: map['duration_minutes'] as int,
      assignee: map['assignee'] as String?,
      priorityQuadrant: PriorityQuadrant.fromInt(map['priority_quadrant'] as int),
      isCompleted: (map['is_completed'] as int) == 1,
      snoozeCount: (map['snooze_count'] as int?) ?? 0,
      createdAt: map['created_at'] as String,
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? targetTime,
    int? durationMinutes,
    String? assignee,
    PriorityQuadrant? priorityQuadrant,
    bool? isCompleted,
    int? snoozeCount,
    String? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetTime: targetTime ?? this.targetTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      assignee: assignee ?? this.assignee,
      priorityQuadrant: priorityQuadrant ?? this.priorityQuadrant,
      isCompleted: isCompleted ?? this.isCompleted,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
