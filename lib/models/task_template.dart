import 'package:flutter/material.dart';
import 'priority_quadrant.dart';

/// A daily repetitive task (e.g. "siapkan bumbu setiap pagi").
///
/// Templates are the proposal's answer to repetitive MSME preparation work:
/// every time the app opens, active templates are materialised into real
/// tasks for the current day, so the owner does not retype the same list.
class TaskTemplate {
  final int? id;
  final String title;
  final String targetTime; // "HH:mm"
  final int durationMinutes;
  final String? assignee;
  final PriorityQuadrant priorityQuadrant;
  final bool isActive;

  const TaskTemplate({
    this.id,
    required this.title,
    required this.targetTime,
    required this.durationMinutes,
    this.assignee,
    required this.priorityQuadrant,
    this.isActive = true,
  });

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

  int get minutesSinceMidnight {
    final tod = timeOfDay;
    return tod.hour * 60 + tod.minute;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_time': targetTime,
      'duration_minutes': durationMinutes,
      'assignee': assignee,
      'priority_quadrant': priorityQuadrant.value,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory TaskTemplate.fromMap(Map<String, dynamic> map) {
    return TaskTemplate(
      id: map['id'] as int?,
      title: map['title'] as String,
      targetTime: map['target_time'] as String,
      durationMinutes: map['duration_minutes'] as int,
      assignee: map['assignee'] as String?,
      priorityQuadrant:
          PriorityQuadrant.fromInt((map['priority_quadrant'] as int?) ?? 1),
      isActive: ((map['is_active'] as int?) ?? 1) == 1,
    );
  }

  TaskTemplate copyWith({
    int? id,
    String? title,
    String? targetTime,
    int? durationMinutes,
    String? assignee,
    PriorityQuadrant? priorityQuadrant,
    bool? isActive,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      targetTime: targetTime ?? this.targetTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      assignee: assignee ?? this.assignee,
      priorityQuadrant: priorityQuadrant ?? this.priorityQuadrant,
      isActive: isActive ?? this.isActive,
    );
  }
}
