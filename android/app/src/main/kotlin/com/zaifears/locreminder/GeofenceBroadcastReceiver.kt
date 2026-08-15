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
            val entry = store.getById(geofence.requestId)
            val label = entry?.label ?: "your destination"

            val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                action = AlarmForegroundService.ACTION_START
                putExtra(AlarmForegroundService.EXTRA_GEOFENCE_ID, geofence.requestId)
                putExtra(AlarmForegroundService.EXTRA_LABEL, label)
            }
            ContextCompat.startForegroundService(context, serviceIntent)
        }
    }

    companion object {
        private const val TAG = "GeofenceReceiver"
        const val ACTION_GEOFENCE_EVENT = "com.zaifears.locreminder.action.GEOFENCE_EVENT"
    }
}
