import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages alarm duration, vibration, and user preferences.
class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();

  int _alarmDurationSeconds = 30; // 15, 30, 60, 120 seconds
  bool _vibrationEnabled = true;

  int get alarmDurationSeconds => _alarmDurationSeconds;
  bool get vibrationEnabled => _vibrationEnabled;

  SettingsService._internal();

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _alarmDurationSeconds = prefs.getInt('alarm_duration_sec') ?? 30;
    _vibrationEnabled = prefs.getBool('alarm_vibrate_enabled') ?? true;
    notifyListeners();
  }

  Future<void> setAlarmDuration(int seconds) async {
    _alarmDurationSeconds = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarm_duration_sec', seconds);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_vibrate_enabled', enabled);
  }
}
