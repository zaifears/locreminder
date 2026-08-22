package com.zaifears.locreminder

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat


/**
 * Rings the alarm. Runs as a foreground service so Android won't kill it
 * mid-ring, plays audio on STREAM_ALARM (separate from the ringer/media
 * volume, so it sounds even if the phone is on silent/vibrate), and shows a
 * full-screen notification that pulls [AlarmActivity] on top of the lock
 * screen. Entirely native: it is started by [LocationWatchService]
 * whether or not the Flutter engine is running.
 */
class AlarmForegroundService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var autoStopRunnable: Runnable? = null

    /** Every destination this ring covers, in arrival order. */
    private val ringingLabels = mutableListOf<String>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A null intent means the system restarted this service on its own.
        // There is no alarm to resume in that case, and ringing with default
        // values would be a phantom alarm the user never set, so bail out.
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        if (intent.action == ACTION_STOP) {
            stopAlarm()
            return START_NOT_STICKY
        }

        val label = intent.getStringExtra(EXTRA_LABEL)
            ?: getString(R.string.alarm_default_destination)
        val alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: ""
        startAlarm(alarmId, label)

        // If the system kills us mid-ring it redelivers this same intent, so
        // the alarm resumes with the right destination instead of defaults.
        return START_REDELIVER_INTENT
    }

    private fun startAlarm(alarmId: String, label: String) {
        // A second arrival landing mid-ring used to be dropped here, and
        // because the entry is consumed further down it was left armed too.
        // Two alarms close enough together that the first was still ringing
        // therefore lost the second outright: it stayed silent for the rest
        // of the journey and only went off on the way back past it, once the
        // user had left its radius and re-entered. Fold it into the ring that
        // is already happening instead of discarding it.
        if (isRinging) {
            Log.i(TAG, "Already ringing; folding in $label")
            if (label !in ringingLabels) ringingLabels.add(label)
            consumeAlarm(alarmId)
            startForeground(NOTIFICATION_ID, buildNotification(ringingLabel(), alarmId))
            // Re-delivered to the activity too, so the screen names both
            // stops instead of only the one that got there first.
            launchAlarmActivity(ringingLabel(), alarmId)
            // The user has only just arrived somewhere new, so give them the
            // full ten minutes from *this* arrival rather than the first.
            // Both timers, not just the visible one: the wake lock was taken
            // out when the first alarm began, so a fold nine minutes in would
            // otherwise let the CPU sleep a minute later with the alarm
            // still ringing.
            autoStopRunnable?.let { handler.removeCallbacks(it) }
            scheduleAutoStop()
            acquireWakeLock()
            return
        }

        isRinging = true
        ringingLabels.clear()
        ringingLabels.add(label)

        NotificationHelper.ensureAlarmChannel(this)
        startForeground(NOTIFICATION_ID, buildNotification(ringingLabel(), alarmId))
        acquireWakeLock()
        launchAlarmActivity(label, alarmId)
        playAlarmSound()
        startVibration()
        scheduleAutoStop()
        consumeAlarm(alarmId)
    }

    /** What the notification calls this ring, once it may cover more than one stop. */
    private fun ringingLabel(): String = when (ringingLabels.size) {
        0 -> getString(R.string.alarm_default_destination)
        1 -> ringingLabels.first()
        else -> ringingLabels.joinToString(getString(R.string.alarm_label_joiner))
    }

    /**
     * An unattended alarm must not ring forever — if the user misses it
     * entirely it would drain the battery flat. Ten minutes matches the
     * wake lock's own timeout.
     */
    private fun scheduleAutoStop() {
        autoStopRunnable = Runnable {
            Log.i(TAG, "Auto-stopping alarm after $AUTO_STOP_MILLIS ms")
            stopAlarm()
        }.also { handler.postDelayed(it, AUTO_STOP_MILLIS) }
    }

    /** An arrival alarm is one-shot: consume it so re-entering doesn't re-fire it. */
    private fun consumeAlarm(alarmId: String) {
        if (alarmId.isEmpty()) return
        AlarmStore(this).remove(alarmId)
    }

    private fun stopAlarm() {
        autoStopRunnable?.let { handler.removeCallbacks(it) }
        autoStopRunnable = null

        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
        } catch (e: IllegalStateException) {
            Log.w(TAG, "MediaPlayer already stopped", e)
        }
        mediaPlayer = null

        vibrator?.cancel()
        vibrator = null

        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null

        isRinging = false
        ringingLabels.clear()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        if (isRinging) stopAlarm()
        super.onDestroy()
    }

    /** Takes the wake lock, replacing any already held so the timeout restarts. */
    private fun acquireWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "locreminder:AlarmWakeLock",
        ).apply { acquire(10 * 60 * 1000L) }
    }

    private fun playAlarmSound() {
        val settings = AlarmSettings(this)
        // resolvePlayableUri already falls back to the system alarm tone if
        // the user's chosen file has become unreadable.
        if (!startPlayer(settings.resolvePlayableUri())) {
            // Even the resolved URI failed. Try the stock alarm tone outright
            // rather than leaving the user with a silent "alarm".
            val fallback = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            if (!startPlayer(fallback)) {
                Log.e(TAG, "No alarm sound could be played at all")
            }
        }
    }

    private fun startPlayer(uri: android.net.Uri?): Boolean {
        if (uri == null) return false
        return try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(this@AlarmForegroundService, uri)
                isLooping = true
                setVolume(1f, 1f)
                prepare()
                start()
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play alarm sound from $uri", e)
            try {
                mediaPlayer?.release()
            } catch (_: Exception) {
                // Already torn down.
            }
            mediaPlayer = null
            false
        }
    }

    private fun startVibration() {
        if (!AlarmSettings(this).vibrationEnabled()) return

        // VIBRATOR_SERVICE still resolves on Android 12+, but through a
        // compatibility shim; VibratorManager is the real accessor there.
        val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

        if (device == null || !device.hasVibrator()) {
            Log.i(TAG, "No vibrator available; ringing without it")
            return
        }
        vibrator = device

        // Declared as an alarm rather than left to default to USAGE_UNKNOWN.
        // Do Not Disturb and the silent profile suppress ordinary vibrations,
        // so without these attributes the phone would play the tone on the
        // alarm stream while sitting perfectly still in a pocket — which is
        // exactly the situation the buzz exists for.
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val pattern = longArrayOf(0, 800, 400)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                device.vibrate(VibrationEffect.createWaveform(pattern, 0), attributes)
            } else {
                @Suppress("DEPRECATION")
                device.vibrate(pattern, 0, attributes)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Vibration failed; the tone still plays", e)
        }
    }

    private fun launchAlarmActivity(label: String, alarmId: String) {
        val activityIntent = Intent(this, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_LABEL, label)
            putExtra(EXTRA_ALARM_ID, alarmId)
        }
        startActivity(activityIntent)
    }

    private fun buildNotification(label: String, alarmId: String): Notification {
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_LABEL, label)
            putExtra(EXTRA_ALARM_ID, alarmId)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            0,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val stopIntent = Intent(this, AlarmForegroundService::class.java).apply { action = ACTION_STOP }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, NotificationHelper.ALARM_CHANNEL_ID)
            .setContentTitle(getString(R.string.alarm_notification_title, label))
            .setContentText(getString(R.string.alarm_notification_body))
            .setSmallIcon(R.drawable.ic_notification_alarm)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(fullScreenPendingIntent)
            .addAction(
                R.drawable.ic_stop,
                getString(R.string.alarm_stop_button),
                stopPendingIntent,
            )
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }

    companion object {
        private const val TAG = "AlarmForegroundService"
        const val ACTION_START = "com.zaifears.locreminder.action.START_ALARM"
        const val ACTION_STOP = "com.zaifears.locreminder.action.STOP_ALARM"
        const val EXTRA_ALARM_ID = "extra_alarm_id"
        const val EXTRA_LABEL = "extra_label"
        private const val NOTIFICATION_ID = 4201
        private const val AUTO_STOP_MILLIS = 10 * 60 * 1000L

        var isRinging: Boolean = false
            private set
    }
}
