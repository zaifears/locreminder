package com.zaifears.locreminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Broadcast receiver triggered by [AlarmManager] for the locked-screen alarm test.
 *
 * Runs independently of [MainActivity]'s lifecycle so the test alarm reliably fires
 * even when the activity has been destroyed by vendor battery managers. If starting
 * the foreground service is blocked by system background restrictions, falls back
 * immediately to a high-priority full-screen intent notification so the test never
 * fails silently.
 */
class TestAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val label = intent.getStringExtra(AlarmForegroundService.EXTRA_LABEL)
            ?: context.getString(R.string.test_alarm_label)

        val alarmIntent = Intent(context, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_START
            putExtra(AlarmForegroundService.EXTRA_LABEL, label)
            putExtra(AlarmForegroundService.EXTRA_ALARM_ID, "")
        }

        try {
            ContextCompat.startForegroundService(context, alarmIntent)
        } catch (e: Exception) {
            Log.w(TAG, "Foreground service start blocked; posting fallback alarm notification", e)
            NotificationHelper.postFallbackAlarmNotification(context, label)
        }
    }

    companion object {
        private const val TAG = "TestAlarmReceiver"
        const val REQUEST_CODE = 9001
    }
}
