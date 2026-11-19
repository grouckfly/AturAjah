import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/shift_phase.dart';
import '../services/shift_schedule_service.dart';

/// Live Status Banner displaying the current operational phase using the
/// user's own quiet/peak windows (proposal feature 3).
class LiveStatusBanner extends StatelessWidget {
  const LiveStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final shiftService = ShiftScheduleService.instance;
    final phase = shiftService.getCurrentPhase();

    // Standard hours stay unobtrusive: nothing is announced.
    if (phase == ShiftPhaseType.standard) {
      return const SizedBox.shrink();
    }

    final quietWindow = shiftService.formatWindow(
      shiftService.quietStart,
      shiftService.quietEnd,
    );
    final peakWindow = shiftService.formatWindow(
      shiftService.peakStart,
      shiftService.peakEnd,
    );

    Color bannerColor;
    Color textColor;
    Color iconColor;
    IconData iconData;
    String statusText;

    switch (phase) {
      case ShiftPhaseType.quietHours:
        bannerColor = AppColors.quietHoursContainer;
        textColor = AppColors.secondaryDark;
        iconColor = AppColors.secondary;
        iconData = Icons.soup_kitchen_outlined;
        statusText =
            '${context.tr('quiet_hours_label')} • $quietWindow — ${context.tr('banner_quiet_now')}';
        break;

      case ShiftPhaseType.peakHours:
        bannerColor = AppColors.peakHours;
        textColor = Colors.white;
        iconColor = Colors.white;
        iconData = Icons.local_fire_department_outlined;
        statusText =
            '${context.tr('peak_hours_label')} • $peakWindow — ${context.tr('banner_peak_now')}';
        break;

      case ShiftPhaseType.transition:
        bannerColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        iconColor = const Color(0xFFE65100);
        iconData = Icons.swap_horiz_outlined;
        statusText =
            '${context.tr('banner_transition')} • $peakWindow — ${context.tr('banner_transition_desc')}';
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
