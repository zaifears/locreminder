package com.zaifears.locreminder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat

object NotificationHelper {
    const val ALARM_CHANNEL_ID = "locreminder_alarm_channel"
    const val WATCH_CHANNEL_ID = "locreminder_watch_channel"
    const val FALLBACK_NOTIFICATION_ID = 4202
    const val WATCH_STOPPED_NOTIFICATION_ID = 4204
    const val LOCATION_OFF_NOTIFICATION_ID = 4205

    fun ensureAlarmChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(ALARM_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            ALARM_CHANNEL_ID,
            context.getString(R.string.channel_alarm_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.channel_alarm_description)
            // The service plays the alarm sound itself via MediaPlayer so it can
            // loop continuously; the channel must not also play a one-shot sound.
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setBypassDnd(true)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Channel for the always-on watch notification. Deliberately low
     * importance and silent — it is a status indicator, not an alert.
     */
    fun ensureWatchChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(WATCH_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            WATCH_CHANNEL_ID,
            context.getString(R.string.channel_watch_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.channel_watch_description)
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Last-resort alert used when the alarm service cannot be started at all.
     * Posting a notification is always permitted from the background, so this
     * guarantees the user is told they arrived even if the ringing service was
     * blocked — far better than failing silently.
     */
    fun postFallbackAlarmNotification(context: Context, label: String) {
        ensureAlarmChannel(context)

        val intent = Intent(context, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(AlarmForegroundService.EXTRA_LABEL, label)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, ALARM_CHANNEL_ID)
            .setContentTitle(context.getString(R.string.alarm_notification_title, label))
            .setContentText(context.getString(R.string.notify_arrived_body))
            .setSmallIcon(R.drawable.ic_notification_alarm)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompatShim.notify(context, FALLBACK_NOTIFICATION_ID, notification)
    }

    /**
     * Tells the user that background tracking has stopped and could not be
     * restarted — almost always a vendor power manager. Silent failure here
     * would leave them trusting an alarm that is no longer watching.
     */
    fun postWatchStoppedNotification(context: Context) {
        ensureAlarmChannel(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            2,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, ALARM_CHANNEL_ID)
            .setContentTitle(context.getString(R.string.notify_stopped_title))
            .setContentText(context.getString(R.string.notify_stopped_body))
            .setSmallIcon(R.drawable.ic_notification_alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ERROR)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompatShim.notify(context, WATCH_STOPPED_NOTIFICATION_ID, notification)
    }

    /**
     * Tells the user that location is switched off at the OS level while an
     * alarm is armed. The watch service cannot register with any provider in
     * that state, so nothing will ever trigger — and because the service is
     * still running with its usual notification, the app otherwise looks
     * perfectly armed. Taps straight through to the system location screen.
     */
    fun postLocationOffNotification(context: Context) {
        ensureAlarmChannel(context)

        val pendingIntent = PendingIntent.getActivity(
            context,
            3,
            Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, ALARM_CHANNEL_ID)
            .setContentTitle(context.getString(R.string.notify_location_off_title))
            .setContentText(context.getString(R.string.notify_location_off_body))
            .setSmallIcon(R.drawable.ic_notification_alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ERROR)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompatShim.notify(context, LOCATION_OFF_NOTIFICATION_ID, notification)
    }

    fun clearLocationOffNotification(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.cancel(LOCATION_OFF_NOTIFICATION_ID)
    }
}

/** Keeps the POST_NOTIFICATIONS permission check in one place. */
private object NotificationManagerCompatShim {
    fun notify(context: Context, id: Int, notification: Notification) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        try {
            manager.notify(id, notification)
        } catch (_: SecurityException) {
            // Notification permission revoked; nothing further we can do.
        }
    }
}
