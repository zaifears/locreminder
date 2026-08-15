package com.zaifears.locreminder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

/**
 * Receives ENTER transitions from Play Services' native Geofencing API.
 * This fires even if the app process has been killed, which is the whole
 * point of using GeofencingClient instead of a Dart-side timer/poll loop.
 */
class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent == null) {
            Log.w(TAG, "Received intent with no geofencing event payload")
            return
        }

        if (geofencingEvent.hasError()) {
            val errorMessage = GeofenceStatusCodes.getStatusCodeString(geofencingEvent.errorCode)
            Log.e(TAG, "Geofencing error: $errorMessage")
            return
        }

        if (geofencingEvent.geofenceTransition != Geofence.GEOFENCE_TRANSITION_ENTER) {
            return
        }

        val triggeringGeofences = geofencingEvent.triggeringGeofences ?: return
        val store = GeofenceStore(context)

        for (geofence in triggeringGeofences) {
            // Outer "you're getting close" ring: don't ring the alarm, just
            // wake the watcher to high-frequency polling for the final
            // approach. Lets the far-field tier stay lazy on long journeys.
            if (geofence.requestId.endsWith(APPROACH_SUFFIX)) {
                try {
                    ContextCompat.startForegroundService(
                        context,
                        Intent(context, LocationWatchService::class.java).apply {
                            action = LocationWatchService.ACTION_BOOST
                        },
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Could not boost watcher on approach", e)
                }
                continue
            }

            val entry = store.getById(geofence.requestId)
            val label = entry?.label ?: "your destination"

            val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                action = AlarmForegroundService.ACTION_START
                putExtra(AlarmForegroundService.EXTRA_GEOFENCE_ID, geofence.requestId)
                putExtra(AlarmForegroundService.EXTRA_LABEL, label)
            }
            // Geofence transitions are exempt from Android 12+'s background
            // foreground-service restriction, but OEM power managers still
            // block this in practice. Never let that fail silently: fall back
            // to a full-screen notification, which is always allowed from the
            // background, so the user is told they arrived either way.
            try {
                ContextCompat.startForegroundService(context, serviceIntent)
            } catch (e: Exception) {
                Log.e(TAG, "Alarm service blocked for ${geofence.requestId}; using notification", e)
                NotificationHelper.postFallbackAlarmNotification(context, label)
            }
        }
    }

    companion object {
        private const val TAG = "GeofenceReceiver"
        const val ACTION_GEOFENCE_EVENT = "com.zaifears.locreminder.action.GEOFENCE_EVENT"
        const val APPROACH_SUFFIX = "__approach"
    }
}
