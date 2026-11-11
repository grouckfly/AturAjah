import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/shift_phase.dart';
import '../services/shift_schedule_service.dart';

/// Live Status Banner displaying current kitchen shift phase.
/// High contrast, touch-friendly, uses Material symbols (no emoji).
class LiveStatusBanner extends StatelessWidget {
  const LiveStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final shiftService = ShiftScheduleService.instance;
    final phase = shiftService.getCurrentPhase();

    Color bannerColor;
    Color textColor;
    Color iconColor;
    IconData iconData;
    String statusText;

    // User requested to remove the standard operational hours banner.
    // The banner only displays during active shift windows (Quiet Hours & Peak Hours).
    if (phase == ShiftPhaseType.standard) {
      return const SizedBox.shrink();
    }

    switch (phase) {
      case ShiftPhaseType.quietHours:
        bannerColor = AppColors.quietHoursContainer;
        textColor = AppColors.secondaryDark;
        iconColor = AppColors.secondary;
        iconData = Icons.soup_kitchen_outlined;
        statusText = context.tr('live_quiet_hours');
        break;

      case ShiftPhaseType.peakHours:
        bannerColor = AppColors.peakHours;
        textColor = Colors.white;
        iconColor = Colors.white;
        iconData = Icons.local_fire_department_outlined;
        statusText = context.tr('live_peak_hours');
        break;

      case ShiftPhaseType.transition:
        bannerColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        iconColor = const Color(0xFFE65100);
        iconData = Icons.swap_horiz_outlined;
        statusText = 'Transisi ke Jam Sibuk (12:00)';
        break;

      case ShiftPhaseType.standard:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: phase == ShiftPhaseType.peakHours
              ? AppColors.primaryDark
              : AppColors.divider,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: phase == ShiftPhaseType.peakHours
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
