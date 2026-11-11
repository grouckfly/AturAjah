import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Eisenhower 2x2 Priority Matrix Quadrants.
enum PriorityQuadrant {
  doFirst(1),
  schedule(2),
  delegate(3),
  later(4);

  final int value;
  const PriorityQuadrant(this.value);

  static PriorityQuadrant fromInt(int value) {
    switch (value) {
      case 1:
        return PriorityQuadrant.doFirst;
      case 2:
        return PriorityQuadrant.schedule;
      case 3:
        return PriorityQuadrant.delegate;
      case 4:
        return PriorityQuadrant.later;
      default:
        return PriorityQuadrant.doFirst;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PriorityQuadrant.doFirst:
        return AppColors.q1Background;
      case PriorityQuadrant.schedule:
        return AppColors.q2Background;
      case PriorityQuadrant.delegate:
        return AppColors.q3Background;
      case PriorityQuadrant.later:
        return AppColors.q4Background;
    }
  }

  Color get borderColor {
    switch (this) {
      case PriorityQuadrant.doFirst:
        return AppColors.q1Border;
      case PriorityQuadrant.schedule:
        return AppColors.q2Border;
      case PriorityQuadrant.delegate:
        return AppColors.q3Border;
      case PriorityQuadrant.later:
        return AppColors.q4Border;
    }
  }

  Color get indicatorColor {
    switch (this) {
      case PriorityQuadrant.doFirst:
        return AppColors.q1Indicator;
      case PriorityQuadrant.schedule:
        return AppColors.q2Indicator;
      case PriorityQuadrant.delegate:
        return AppColors.q3Indicator;
      case PriorityQuadrant.later:
        return AppColors.q4Indicator;
    }
  }
}
