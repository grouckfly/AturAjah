import 'dart:js_interop';

@JS('startAturAjahWebAlarm')
external void _jsStartWebAlarm(int durationSeconds);

@JS('stopAturAjahWebAlarm')
external void _jsStopWebAlarm();

/// Web implementation triggering the browser Web Audio API oscillator alarm.
void triggerWebAlarm(int durationSeconds) {
  try {
    _jsStartWebAlarm(durationSeconds);
  } catch (_) {}
}

void stopWebAlarm() {
  try {
    _jsStopWebAlarm();
  } catch (_) {}
}
