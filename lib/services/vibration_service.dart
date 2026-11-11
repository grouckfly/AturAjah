import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

/// Direct hardware vibration service using native Android Vibrator/VibratorManager.
/// Completely bypasses OS notification rate limiters and OEM touch haptic throttles.
class VibrationService {
  static const MethodChannel _channel =
      MethodChannel('com.aturajah.app/vibrate');

  /// Trigger a strong hardware vibration if vibration is enabled by user.
  /// When called repeatedly (spam testing), each call cancels previous vibration
  /// and immediately fires anew.
  static Future<void> vibrate({int durationMs = 400}) async {
    final enabled = SettingsService.instance.vibrationEnabled;
    if (!enabled) return;

    try {
      await _channel.invokeMethod('vibrate', {'duration': durationMs});
    } catch (e) {
      if (kDebugMode) {
        print('Native vibration error: $e');
      }
    }
  }

  /// Cancel any active vibration
  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }
}
