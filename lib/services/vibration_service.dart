import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

/// Direct hardware alarm playback & vibration service using native Android MediaPlayer and Vibrator.
/// Completely bypasses OS notification rate limiters and ensures sound loops seamlessly.
class VibrationService {
  static const MethodChannel _channel =
      MethodChannel('com.aturajah.app/vibrate');

  /// Start continuous alarm sound & vibration for [durationSeconds].
  /// The audio loops seamlessly (isLooping = true) so the alarm sound never ends
  /// before the specified alarm duration finishes.
  static Future<void> startAlarm({
    int? durationSeconds,
    bool withAudio = true,
    bool withVibration = true,
  }) async {
    final vibrationEnabled = SettingsService.instance.vibrationEnabled;
    final duration =
        durationSeconds ?? SettingsService.instance.alarmDurationSeconds;

    try {
      await _channel.invokeMethod('startAlarm', {
        'durationSeconds': duration,
        'withAudio': withAudio,
        'withVibration': withVibration && vibrationEnabled,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Native startAlarm error: $e');
      }
    }
  }

  /// Start repeating rhythmic alarm vibration and sound for [durationSeconds].
  /// Keeps vibrating rhythmically and playing audio as long as the alarm is active.
  static Future<void> startAlarmVibration({int? durationSeconds}) async {
    await startAlarm(
      durationSeconds: durationSeconds,
      withAudio: true,
      withVibration: true,
    );
  }

  /// Stop both alarm audio and vibration immediately
  static Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (_) {}
  }

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

  /// Cancel any active vibration and audio immediately
  static Future<void> cancel() async {
    await stopAlarm();
  }
}
