package com.zaifears.locreminder

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.location.Location
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

/**
 * Actively watches the device's location while any alarm is armed.
 *
 * Play Services geofencing alone is not dependable for an alarm: once the app
 * is idle, Doze and App Standby defer the transition broadcast, and it can
 * arrive minutes late or not until the user next opens the app — long after
 * the stop has gone by. A foreground service keeps the process out of that
 * idle state and checks arrival itself, so the alarm fires on time.
 *
 * Geofencing is still registered in parallel as a cheap backup path.
 */
class LocationWatchService : Service() {

    private lateinit var fusedClient: FusedLocationProviderClient
    private var currentIntervalMillis: Long = FAR_INTERVAL_MILLIS
    private var nearestLabel: String? = null
    private var nearestDistance: Double? = null

    /** Geofences the user was already inside, which must be exited before they can trigger. */
    private val suppressedUntilExit = mutableSetOf<String>()
    private var hadFirstFix = false

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let { onLocation(it) }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        fusedClient = LocationServices.getFusedLocationProviderClient(this)
        NotificationHelper.ensureWatchChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopWatching()
            return START_NOT_STICKY
        }

        // Nothing armed means nothing to watch; don't hold a notification for
        // no reason.
        if (GeofenceStore(this).loadAll().isEmpty()) {
            stopWatching()
            return START_NOT_STICKY
        }

        startForeground(NOTIFICATION_ID, buildNotification())
        requestUpdates(currentIntervalMillis)
        isWatching = true
        return START_STICKY
    }

    private fun requestUpdates(intervalMillis: Long) {
        val request = LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, intervalMillis)
            .setMinUpdateIntervalMillis(intervalMillis / 2)
            .setWaitForAccurateLocation(false)
            .build()

        try {
            fusedClient.removeLocationUpdates(locationCallback)
            fusedClient.requestLocationUpdates(request, locationCallback, mainLooper)
            currentIntervalMillis = intervalMillis
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission missing; stopping watch", e)
            stopWatching()
        }
    }

    private fun onLocation(location: Location) {
        val entries = GeofenceStore(this).loadAll()
        if (entries.isEmpty()) {
            stopWatching()
            return
        }

        var closest: Pair<GeofenceEntry, Double>? = null

        for (entry in entries) {
            val results = FloatArray(1)
            Location.distanceBetween(
                location.latitude,
                location.longitude,
                entry.latitude,
                entry.longitude,
                results,
            )
            val distance = results[0].toDouble()

            if (distance <= entry.radius) {
                // Match geofence ENTER semantics: being inside already when
                // watching starts is not an arrival. Wait until the user has
                // actually been outside, so setting an alarm for where you're
                // currently standing doesn't ring instantly.
                if (!hadFirstFix || entry.id in suppressedUntilExit) {
                    suppressedUntilExit.add(entry.id)
                } else {
                    triggerAlarm(entry)
                    return
                }
            } else {
                suppressedUntilExit.remove(entry.id)
            }

            if (closest == null || distance < closest.second) {
                closest = entry to distance
            }
        }
        hadFirstFix = true

        closest?.let { (entry, distance) ->
            nearestLabel = entry.label
            nearestDistance = distance
            updateNotification()
            adaptIntervalTo(distance)
        }
    }

    /**
     * Polls harder the closer the user gets. Checking every ten seconds from
     * across the city would waste battery for no benefit; checking every two
     * minutes when a stop is 200m away would miss it.
     */
    private fun adaptIntervalTo(distanceMetres: Double) {
        val target = when {
            distanceMetres > 5000 -> FAR_INTERVAL_MILLIS
            distanceMetres > 1500 -> 60_000L
            distanceMetres > 500 -> 20_000L
            else -> NEAR_INTERVAL_MILLIS
        }
        if (target != currentIntervalMillis) requestUpdates(target)
    }

    private fun triggerAlarm(entry: GeofenceEntry) {
        Log.i(TAG, "Arrived at ${entry.label}; starting alarm")
        // We are already a foreground service, so starting the alarm service
        // here is always permitted — this is the path that works when a
        // deferred geofence broadcast would not have arrived in time.
        val alarmIntent = Intent(this, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_START
            putExtra(AlarmForegroundService.EXTRA_GEOFENCE_ID, entry.id)
            putExtra(AlarmForegroundService.EXTRA_LABEL, entry.label)
        }
        startService(alarmIntent)

        // The alarm service consumes the geofence itself; if that leaves
        // nothing armed, this watch has no further work.
        if (GeofenceStore(this).loadAll().none { it.id != entry.id }) {
            stopWatching()
        }
    }

    private fun stopWatching() {
        isWatching = false
        try {
            fusedClient.removeLocationUpdates(locationCallback)
        } catch (_: Exception) {
            // Client may already be torn down.
        }
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        isWatching = false
        try {
            fusedClient.removeLocationUpdates(locationCallback)
        } catch (_: Exception) {
            // Ignored.
        }
        super.onDestroy()
    }

    private fun updateNotification() {
        NotificationManagerShim.notify(this, NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        val armedCount = GeofenceStore(this).loadAll().size
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val distance = nearestDistance
        val label = nearestLabel
        val text = when {
            label == null || distance == null ->
                if (armedCount == 1) "1 alarm armed" else "$armedCount alarms armed"
            distance >= 1000 -> "%.1f km from %s".format(distance / 1000, label)
            else -> "${distance.toInt()} m from $label"
        }

        return NotificationCompat.Builder(this, NotificationHelper.WATCH_CHANNEL_ID)
            .setContentTitle("Watching for your destination")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification_alarm)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setSilent(true)
            .setShowWhen(false)
            .setContentIntent(openIntent)
            .build()
    }

    companion object {
        private const val TAG = "LocationWatchService"
        const val ACTION_STOP = "com.zaifears.locreminder.action.STOP_WATCH"
        private const val NOTIFICATION_ID = 4203
        private const val FAR_INTERVAL_MILLIS = 120_000L
        private const val NEAR_INTERVAL_MILLIS = 10_000L

        var isWatching: Boolean = false
            private set
    }
}

private object NotificationManagerShim {
    fun notify(service: Service, id: Int, notification: Notification) {
        val manager = service.getSystemService(android.app.NotificationManager::class.java) ?: return
        try {
            manager.notify(id, notification)
        } catch (_: SecurityException) {
            // Notification permission revoked.
        }
    }
}
