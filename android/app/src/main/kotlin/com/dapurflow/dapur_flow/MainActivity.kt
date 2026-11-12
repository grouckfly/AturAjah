package com.dapurflow.dapur_flow

import android.content.Context
import android.media.AudioAttributes
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
    private var stopVibrationRunnable: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarmVibration" -> {
                    val durationSeconds = call.argument<Int>("durationSeconds") ?: 30
                    startAlarmVibration(durationSeconds)
                    result.success(true)
                }
                "vibrate" -> {
                    val durationMs = (call.argument<Int>("duration") ?: 400).toLong()
                    if (durationMs > 1000) {
                        startAlarmVibration((durationMs / 1000).toInt())
                    } else {
                        triggerShortVibration(durationMs)
                    }
                    result.success(true)
                }
                "cancel" -> {
                    cancelVibration()
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

    private fun startAlarmVibration(durationSeconds: Int) {
        try {
            cancelVibration()

            val vibrator = getVibrator()
            if (!vibrator.hasVibrator()) return

            val audioAttributes = getAlarmAudioAttributes()
            // Rhythmic alarm vibration: delay 0ms, vibrate 800ms, pause 400ms (repeats indefinitely)
            val timings = longArrayOf(0, 800, 400)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(timings, 0)
                vibrator.vibrate(effect, audioAttributes)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(timings, 0, audioAttributes)
            }

            if (durationSeconds > 0) {
                val runnable = Runnable {
                    cancelVibration()
                }
                stopVibrationRunnable = runnable
                mainHandler.postDelayed(runnable, durationSeconds.toLong() * 1000L)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun triggerShortVibration(durationMs: Long) {
        try {
            cancelVibration()

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

    private fun cancelVibration() {
        try {
            stopVibrationRunnable?.let { mainHandler.removeCallbacks(it) }
            stopVibrationRunnable = null
            val vibrator = getVibrator()
            vibrator.cancel()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        cancelVibration()
        super.onDestroy()
    }
}
