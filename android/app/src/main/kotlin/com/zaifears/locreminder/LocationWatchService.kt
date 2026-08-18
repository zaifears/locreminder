package com.zaifears.locreminder

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Actively watches the device's location while any alarm is armed, and rings
 * the alarm on arrival.
 *
 * This is the whole detection mechanism, deliberately. Play Services
 * geofencing was tried first and is not dependable for an alarm: once the app
 * goes idle, Doze and App Standby defer the transition broadcast, so it can
 * arrive minutes late — or not until the user next opens the app, long after
 * the stop. Holding a foreground service keeps the process out of that idle
 * state, which is what makes the alarm land on time.
 *
 * Uses the platform [LocationManager] rather than Play Services' fused
 * client, so the app carries no proprietary dependency and works on devices
 * with no Google services at all — Huawei's HMS phones and de-Googled ROMs
 * included. On Android 12+ the platform exposes its own fused provider,
 * giving the same sensor-blended efficiency without the dependency.
 */
class LocationWatchService : Service() {

    private lateinit var locationManager: LocationManager
    private var currentIntervalMillis: Long = FAR_INTERVAL_MILLIS
    private var nearestLabel: String? = null
    private var nearestDistance: Double? = null

    /** Alarms the user was already inside, which must be exited before they can trigger. */
    private val suppressedUntilExit = mutableSetOf<String>()
    private var hadFirstFix = false

    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) = onLocation(location)

        // Declared explicitly rather than relying on the interface defaults,
        // which only exist from API 30 — this app supports API 23.
        @Deprecated("Deprecated in Java")
        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit

        override fun onProviderEnabled(provider: String) = Unit

        override fun onProviderDisabled(provider: String) = Unit
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(LocationManager::class.java)
        NotificationHelper.ensureWatchChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            WatchdogReceiver.cancel(this)
            stopWatching()
            return START_NOT_STICKY
        }

        // Nothing armed means nothing to watch; don't hold a notification for
        // no reason.
        if (AlarmStore(this).loadAll().isEmpty()) {
            stopWatching()
            return START_NOT_STICKY
        }

        startForeground(NOTIFICATION_ID, buildNotification())
        requestUpdates(currentIntervalMillis)

        isWatching = true
        WatchdogReceiver.schedule(this)
        return START_STICKY
    }

    /**
     * Providers to listen on, best first.
     *
     * Android 12 added a platform fused provider that blends GPS, wifi and
     * sensors the way Play Services does — preferred where present. Below
     * that, GPS and network are used together: network gives cheap coarse
     * fixes indoors, GPS the accuracy needed near the destination.
     */
    private fun activeProviders(): List<String> {
        val available = try {
            locationManager.allProviders
        } catch (e: Exception) {
            emptyList<String>()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            available.contains(LocationManager.FUSED_PROVIDER)
        ) {
            return listOf(LocationManager.FUSED_PROVIDER)
        }

        return listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { provider ->
                available.contains(provider) &&
                    runCatching { locationManager.isProviderEnabled(provider) }.getOrDefault(false)
            }
    }

    private fun requestUpdates(intervalMillis: Long) {
        val providers = activeProviders()
        if (providers.isEmpty()) {
            Log.w(TAG, "No location provider is enabled; cannot watch")
            return
        }

        try {
            locationManager.removeUpdates(locationListener)
            for (provider in providers) {
                locationManager.requestLocationUpdates(
                    provider,
                    intervalMillis,
                    0f,
                    locationListener,
                    mainLooper,
                )
            }
            currentIntervalMillis = intervalMillis
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission missing; stopping watch", e)
            stopWatching()
        } catch (e: Exception) {
            Log.e(TAG, "Could not request location updates", e)
        }
    }

    private fun onLocation(location: Location) {
        val entries = AlarmStore(this).loadAll()
        if (entries.isEmpty()) {
            stopWatching()
            return
        }

        var closest: Pair<AlarmEntry, Double>? = null

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
                // Arrival means crossing *into* the radius. Being inside
                // already when watching starts is not an arrival, so an alarm
                // set for where you're currently standing doesn't ring at once.
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
     * Polls harder the closer the user gets. Ten-second fixes from across the
     * country would flatten the battery on a long journey for no benefit,
     * while two-minute fixes 200m out would sail past the stop.
     */
    private fun adaptIntervalTo(distanceMetres: Double) {
        val target = when {
            distanceMetres > 10_000 -> VERY_FAR_INTERVAL_MILLIS
            distanceMetres > 5_000 -> FAR_INTERVAL_MILLIS
            distanceMetres > 1_500 -> 60_000L
            distanceMetres > 500 -> 20_000L
            else -> NEAR_INTERVAL_MILLIS
        }
        if (target != currentIntervalMillis) requestUpdates(target)
    }

    private fun triggerAlarm(entry: AlarmEntry) {
        Log.i(TAG, "Arrived at ${entry.label}; starting alarm")
        // We are already a foreground service, so starting the alarm service
        // from here is always permitted.
        val alarmIntent = Intent(this, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_START
            putExtra(AlarmForegroundService.EXTRA_ALARM_ID, entry.id)
            putExtra(AlarmForegroundService.EXTRA_LABEL, entry.label)
        }
        startService(alarmIntent)

        // The alarm service consumes the entry itself; if that leaves nothing
        // armed, this watch has no further work.
        if (AlarmStore(this).loadAll().none { it.id != entry.id }) {
            stopWatching()
        }
    }

    private fun stopWatching() {
        isWatching = false
        try {
            locationManager.removeUpdates(locationListener)
        } catch (_: Exception) {
            // Manager may already be torn down.
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
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
            locationManager.removeUpdates(locationListener)
        } catch (_: Exception) {
            // Ignored.
        }
        super.onDestroy()
    }

    private fun updateNotification() {
        val manager = getSystemService(android.app.NotificationManager::class.java) ?: return
        try {
            manager.notify(NOTIFICATION_ID, buildNotification())
        } catch (_: SecurityException) {
            // Notification permission revoked.
        }
    }

    private fun buildNotification(): Notification {
        val armedCount = AlarmStore(this).loadAll().size
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
        private const val VERY_FAR_INTERVAL_MILLIS = 300_000L
        private const val FAR_INTERVAL_MILLIS = 120_000L
        private const val NEAR_INTERVAL_MILLIS = 10_000L

        var isWatching: Boolean = false
            private set
    }
}
