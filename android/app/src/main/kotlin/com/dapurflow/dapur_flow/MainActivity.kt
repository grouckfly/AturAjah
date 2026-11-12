package com.dapurflow.dapur_flow

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.aturajah.app/vibrate"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var stopAlarmRunnable: Runnable? = null
    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarm" -> {
                    val durationSeconds = call.argument<Int>("durationSeconds") ?: 30
                    val withVibration = call.argument<Boolean>("withVibration") ?: true
                    val withAudio = call.argument<Boolean>("withAudio") ?: true
                    startAlarm(durationSeconds, withVibration, withAudio)
                    result.success(true)
                }
                "startAlarmVibration" -> {
                    val durationSeconds = call.argument<Int>("durationSeconds") ?: 30
                    startAlarm(durationSeconds, withVibration = true, withAudio = true)
                    result.success(true)
                }
                "vibrate" -> {
                    val durationMs = (call.argument<Int>("duration") ?: 400).toLong()
                    if (durationMs > 1000) {
                        startAlarm((durationMs / 1000).toInt(), withVibration = true, withAudio = false)
                    } else {
                        triggerShortVibration(durationMs)
                    }
                    result.success(true)
                }
                "stopAlarm", "cancel" -> {
                    stopAlarm()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun getAlarmAudioAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
            .build()
    }

    private fun startAlarm(durationSeconds: Int, withVibration: Boolean, withAudio: Boolean) {
        try {
            stopAlarm()

            val audioAttributes = getAlarmAudioAttributes()

            // 1. Loop alarm sound continuously (isLooping = true) so sound never expires before duration
            if (withAudio) {
                try {
                    val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                        ?: android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI

                    mediaPlayer = MediaPlayer().apply {
                        setDataSource(applicationContext, alarmUri)
                        setAudioAttributes(audioAttributes)
                        isLooping = true // Continuous seamless replay of alarm sound
                        prepare()
                        start()
                    }
                } catch (audioEx: Exception) {
                    audioEx.printStackTrace()
                }
            }

            // 2. Continuous rhythmic alarm vibration
            if (withVibration) {
                val vibrator = getVibrator()
                if (vibrator.hasVibrator()) {
                    val timings = longArrayOf(0, 800, 400)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val effect = VibrationEffect.createWaveform(timings, 0)
                        vibrator.vibrate(effect, audioAttributes)
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(timings, 0, audioAttributes)
                    }
                }
            }

            // 3. Auto-stop after durationSeconds (if > 0). If <= 0, continues until stopAlarm() is called.
            if (durationSeconds > 0) {
                val runnable = Runnable {
                    stopAlarm()
                }
                stopAlarmRunnable = runnable
                mainHandler.postDelayed(runnable, durationSeconds.toLong() * 1000L)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun triggerShortVibration(durationMs: Long) {
        try {
            stopAlarm()

            val vibrator = getVibrator()
            if (!vibrator.hasVibrator()) return

            val audioAttributes = getAlarmAudioAttributes()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
                vibrator.vibrate(effect, audioAttributes)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(durationMs, audioAttributes)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopAlarm() {
        try {
            stopAlarmRunnable?.let { mainHandler.removeCallbacks(it) }
            stopAlarmRunnable = null

            // Stop and release audio player
            mediaPlayer?.let {
                try {
                    if (it.isPlaying) {
                        it.stop()
                    }
                } catch (_: Exception) {}
                try {
                    it.reset()
                    it.release()
                } catch (_: Exception) {}
            }
            mediaPlayer = null

            // Stop vibrator
            val vibrator = getVibrator()
            vibrator.cancel()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }
}
