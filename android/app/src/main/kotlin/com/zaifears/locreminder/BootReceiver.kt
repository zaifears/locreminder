package com.zaifears.locreminder

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

/**
 * The OS drops all registered geofences on reboot, so every saved alarm
 * that was still active must be re-registered with Play Services once the
 * device comes back up.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val entries = GeofenceStore(context).loadAll()
        if (entries.isEmpty()) return

        val geofences = entries.map { entry ->
            Geofence.Builder()
                .setRequestId(entry.id)
                .setCircularRegion(entry.latitude, entry.longitude, entry.radius.toFloat())
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
                .build()
        }

        val request = GeofencingRequest.Builder()
            .addGeofences(geofences)
            // Matches the registration in MainActivity: never fire just
            // because the device booted inside one of the saved radii.
            .setInitialTrigger(0)
            .build()

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, GeofenceBroadcastReceiver::class.java)
                .setAction(GeofenceBroadcastReceiver.ACTION_GEOFENCE_EVENT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )

        try {
            LocationServices.getGeofencingClient(context).addGeofences(request, pendingIntent)
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing background location permission, cannot restore geofences on boot", e)
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}
