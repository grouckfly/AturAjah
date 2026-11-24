import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'alarm_audio_stub.dart'
    if (dart.library.js_interop) 'alarm_audio_web.dart';
import 'settings_service.dart';

/// Direct hardware alarm playback & vibration service using native Android MediaPlayer and Vibrator.
/// On Web platforms, gracefully falls back to Web Audio API alarm oscillator via conditional import.
class VibrationService {
  static const MethodChannel _channel =
      MethodChannel('com.aturajah.app/vibrate');

  /// Start continuous alarm sound & vibration for [durationSeconds].
  /// On Android: The audio loops seamlessly (isLooping = true) so the alarm sound never ends
  /// before the specified alarm duration finishes.
  /// On Web: Plays continuous rhythmic beeps via Web Audio API.
  static Future<void> startAlarm({
    int? durationSeconds,
    bool withAudio = true,
    bool withVibration = true,
  }) async {
    final vibrationEnabled = SettingsService.instance.vibrationEnabled;
    final duration =
        durationSeconds ?? SettingsService.instance.alarmDurationSeconds;

    if (kIsWeb) {
      triggerWebAlarm(duration);
      return;
    }

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
  static Future<void> startAlarmVibration({int? durationSeconds}) async {
    await startAlarm(
      durationSeconds: durationSeconds,
      withAudio: true,
      withVibration: true,
    );
  }

  /// Stop both alarm audio and vibration immediately
  static Future<void> stopAlarm() async {
    if (kIsWeb) {
      stopWebAlarm();
      return;
    }

    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (_) {}
  }

  /// Trigger a strong hardware vibration if vibration is enabled by user.
  static Future<void> vibrate({int durationMs = 400}) async {
    final enabled = SettingsService.instance.vibrationEnabled;
    if (!enabled) return;

    if (kIsWeb) {
      // On web, navigator.vibrate is handled in JS helper if supported
      return;
    }

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
