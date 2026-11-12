import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/priority_quadrant.dart';
import '../models/task_model.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/vibration_service.dart';

/// Settings Screen for Alarm Duration, Vibration, and Language
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isTestingAlarm = false;
  Timer? _testResetTimer;

  @override
  void dispose() {
    _testResetTimer?.cancel();
    if (_isTestingAlarm) {
      NotificationService.instance.cancelTestAlarms();
    }
    super.dispose();
  }

  Future<void> _stopAlarmTest() async {
    _testResetTimer?.cancel();
    _testResetTimer = null;
    await NotificationService.instance.cancelTestAlarms();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _isTestingAlarm = false;
      });
    }
  }

  Future<void> _startAlarmTest(SettingsService settings) async {
    _testResetTimer?.cancel();
    final durationSec = settings.alarmDurationSeconds;

    setState(() {
      _isTestingAlarm = true;
    });

    // Continuous rhythmic alarm audio & vibration loop (0 = loop indefinitely)
    await VibrationService.startAlarm(durationSeconds: durationSec);

    const dummyTask = TaskModel(
      id: 9998,
      title: 'Uji Coba Alarm & Getar AturAjah',
      targetTime: 'Sekarang',
      durationMinutes: 1,
      priorityQuadrant: PriorityQuadrant.doFirst,
      createdAt: '2026-11-11',
    );

    await NotificationService.instance.triggerImmediateNotification(
      dummyTask,
      durationSeconds: durationSec,
    );

    if (durationSec > 0) {
      _testResetTimer = Timer(Duration(seconds: durationSec), () {
        if (mounted) {
          setState(() {
            _isTestingAlarm = false;
          });
        }
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('test_alarm_success')),
          backgroundColor: AppColors.secondary,
          duration: durationSec > 0
              ? Duration(seconds: durationSec.clamp(3, 10))
              : const Duration(minutes: 5),
          action: SnackBarAction(
            label: context.tr('stop').toUpperCase(),
            textColor: Colors.white,
            onPressed: () async {
              await _stopAlarmTest();
            },
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('settings_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Alarm Duration Section
            _buildSectionHeader(
              title: context.tr('alarm_section'),
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('alarm_duration'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('alarm_duration_desc'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Preset Duration Chips (15s, 30s, 60s, 120s)
                  Row(
                    children: [15, 30, 60, 120].map((sec) {
                      final isSelected = settings.alarmDurationSeconds == sec;
                      String label = sec >= 60
                          ? '${sec ~/ 60} ${context.tr('minutes_short')}'
                          : '$sec ${context.tr('seconds_short')}';

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () async {
                              await settings.setAlarmDuration(sec);
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // Option: Always ring until stopped (0 seconds)
                  Builder(
                    builder: (context) {
                      final isAlwaysSelected =
                          settings.alarmDurationSeconds == 0;
                      return InkWell(
                        onTap: () async {
                          await settings.setAlarmDuration(0);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 11, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isAlwaysSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAlwaysSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: isAlwaysSelected ? 1.8 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAlwaysSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 19,
                                color: isAlwaysSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.tr('alarm_always_until_stopped'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isAlwaysSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isAlwaysSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isAlwaysSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Aktif',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Vibration Section
            _buildSectionHeader(
              title: context.tr('vibration_section'),
              icon: Icons.vibration,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vibration Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('vibration_enabled'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Switch(
                        value: settings.vibrationEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) async {
                          await settings.setVibrationEnabled(val);
                          if (!val) {
                            await VibrationService.cancel();
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Language & Localization
            _buildSectionHeader(
              title: context.tr('language_switch'),
              icon: Icons.language,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localeProvider.isIndonesian
                        ? 'Bahasa Indonesia'
                        : 'English (US)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => localeProvider.toggleLocale(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 36),
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                    ),
                    child: Text(
                      localeProvider.isIndonesian
                          ? 'Switch to English'
                          : 'Ubah ke Indonesia',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. Test Alarm & Vibration Button
            ElevatedButton.icon(
              onPressed: () async {
                if (_isTestingAlarm) {
                  await _stopAlarmTest();
                } else {
                  await _startAlarmTest(settings);
                }
              },
              icon: Icon(
                _isTestingAlarm ? Icons.stop_circle : Icons.notifications_active,
                size: 20,
              ),
              label: Text(
                _isTestingAlarm
                    ? context.tr('stop_alarm_btn')
                    : context.tr('test_alarm_btn'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTestingAlarm
                    ? const Color(0xFFD32F2F)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
