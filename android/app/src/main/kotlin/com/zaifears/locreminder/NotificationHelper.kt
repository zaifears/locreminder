package com.zaifears.locreminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

object NotificationHelper {
    const val ALARM_CHANNEL_ID = "locreminder_alarm_channel"

    fun ensureAlarmChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(ALARM_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            ALARM_CHANNEL_ID,
            "Location alarms",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alerts you when you arrive near a saved destination"
            // The service plays the alarm sound itself via MediaPlayer so it can
            // loop continuously; the channel must not also play a one-shot sound.
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setBypassDnd(true)
        }
        manager.createNotificationChannel(channel)
    }
}
