package com.zaifears.locreminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Restores watching after a restart.
 *
 * Saved alarms live in [AlarmStore], which survives a reboot, but the
 * foreground service that watches for arrival does not — so without this the
 * app would look armed while nothing was actually running.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON" &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }

        if (AlarmStore(context).loadAll().isEmpty()) return

        try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, LocationWatchService::class.java),
            )
        } catch (e: Exception) {
            // Some vendors block service starts immediately after boot/update. The
            // watchdog retries later, so this is not fatal.
            Log.e(TAG, "Could not restart location watch after boot/update", e)
            WatchdogReceiver.schedule(context)
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
