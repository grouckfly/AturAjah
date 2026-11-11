import 'package:flutter/material.dart';

/// Centralized, high-contrast, touch-friendly Light Palette for Dapur Flow.
/// Designed for high visibility in busy kitchen/operational environments.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF7F7F2); // Warm off-white / light cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E4E8);

  // Primary Accent (Vibrant Kitchen Orange)
  static const Color primary = Color(0xFFF4511E);
  static const Color primaryDark = Color(0xFFD84315);
  static const Color primaryLight = Color(0xFFFFCCBC);
  static const Color primaryContainer = Color(0xFFFBE9E7);

  // Secondary Accent (Forest / Emerald Green for Completed & Quiet Hours)
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryDark = Color(0xFF1B5E20);
  static const Color secondaryLight = Color(0xFFE8F5E9);
  static const Color secondaryBorder = Color(0xFFA5D6A7);

  // Peak Hours Accent
  static const Color peakHours = Color(0xFFFF5722);
  static const Color peakHoursContainer = Color(0xFFFBE9E7);
  static const Color peakHoursBorder = Color(0xFFFFAB91);

  // Quiet Hours Accent
  static const Color quietHours = Color(0xFF2E7D32);
  static const Color quietHoursContainer = Color(0xFFE8F5E9);
  static const Color quietHoursBorder = Color(0xFFA5D6A7);

  // Text Colors (High Contrast Dark Charcoal)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textMuted = Color(0xFF888888);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // 2x2 Priority Matrix Colors
  // Quadrant 1: Urgent & Important (Do First / Kerjakan Dahulu)
  static const Color q1Background = Color(0xFFFFECE0);
  static const Color q1Border = Color(0xFFF4511E);
  static const Color q1Indicator = Color(0xFFD84315);

  // Quadrant 2: Not Urgent & Important (Schedule / Jadwalkan)
  static const Color q2Background = Color(0xFFE3F2FD);
  static const Color q2Border = Color(0xFF1E88E5);
  static const Color q2Indicator = Color(0xFF1565C0);

  // Quadrant 3: Urgent & Not Important (Delegate / Delegasikan)
  static const Color q3Background = Color(0xFFFFF8E1);
  static const Color q3Border = Color(0xFFFFB300);
  static const Color q3Indicator = Color(0xFFF57F17);

  // Quadrant 4: Not Urgent & Not Important (Later / Nanti)
  static const Color q4Background = Color(0xFFF5F5F5);
  static const Color q4Border = Color(0xFFB0BEC5);
  static const Color q4Indicator = Color(0xFF78909C);

  // Alert & Snooze
  static const Color snoozeOrange = Color(0xFFE65100);
  static const Color doneGreen = Color(0xFF2E7D32);
}
