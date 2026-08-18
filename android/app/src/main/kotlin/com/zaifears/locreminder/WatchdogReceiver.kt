package com.zaifears.locreminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Periodically checks that the location watcher is still alive and restarts
 * it if not.
 *
 * Aggressive vendor power managers kill foreground services outright, and
 * once that happens nothing in the app would otherwise notice until the user
 * next opened it — which is exactly too late for a travel alarm. This
 * heartbeat gives the app a chance to recover on its own.
 *
 * Uses an inexact allow-while-idle alarm on purpose: it still fires in Doze,
 * needs no SCHEDULE_EXACT_ALARM permission, and avoids the Play Store policy
 * scrutiny that comes with exact alarms. A roughly-15-minute check is ample
 * for catching a killed service.
 */
class WatchdogReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val armed = AlarmStore(context).loadAll()
        if (armed.isEmpty()) {
            cancel(context)
            return
        }

        if (!LocationWatchService.isWatching) {
            Log.w(TAG, "Watcher not running while ${armed.size} alarm(s) armed; restarting")
            try {
                ContextCompat.startForegroundService(
                    context,
                    Intent(context, LocationWatchService::class.java),
                )
            } catch (e: Exception) {
                // Even the restart was blocked. Say so rather than leaving the
                // user believing an alarm is armed when nothing is watching.
                Log.e(TAG, "Watcher restart blocked by the system", e)
                NotificationHelper.postWatchStoppedNotification(context)
            }
        }

        schedule(context)
    }

    companion object {
        private const val TAG = "WatchdogReceiver"
        private const val INTERVAL_MILLIS = 15 * 60 * 1000L
        private const val REQUEST_CODE = 7301

        private fun pendingIntent(context: Context): PendingIntent {
            return PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                Intent(context, WatchdogReceiver::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun schedule(context: Context) {
            val manager = context.getSystemService(AlarmManager::class.java) ?: return
            manager.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + INTERVAL_MILLIS,
                pendingIntent(context),
            )
        }

        fun cancel(context: Context) {
            val manager = context.getSystemService(AlarmManager::class.java) ?: return
            manager.cancel(pendingIntent(context))
        }
    }
}
