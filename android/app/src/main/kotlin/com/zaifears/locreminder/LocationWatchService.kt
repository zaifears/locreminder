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
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.Calendar

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

    /**
     * When each alarm was first seen inside its radius by a fix too
     * imprecise to trust on its own. In-memory only: if the service is
     * killed and restarted the count starts over, which just means the
     * fallback below waits its full duration again rather than misfiring.
     */
    private val ignoredSince = mutableMapOf<String, Long>()

    /**
     * Which alarms have been seen from outside, and so may ring on the way
     * back in. Persisted rather than held in fields: see [ArrivalState] for
     * the missed alarm that taught us the difference.
     */
    private val arrivalState by lazy { ArrivalState(this) }

    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) = onLocation(location)

        // Declared explicitly rather than relying on the interface defaults,
        // which only exist from API 30 — this app supports API 23.
        @Deprecated("Deprecated in Java")
        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit

        // A provider coming back (user re-enabling GPS, leaving airplane mode)
        // is the cue to re-register: the set of usable providers has changed,
        // and on the way in it may have been empty.
        override fun onProviderEnabled(provider: String) {
            requestUpdates(currentIntervalMillis)
        }

        override fun onProviderDisabled(provider: String) {
            requestUpdates(currentIntervalMillis)
        }
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
        // Deliberately reported even when registration fails. The service is
        // alive either way; what the watchdog needs to know is whether fixes
        // are actually arriving, which isReceivingUpdates carries separately.
        isWatching = true
        requestUpdates(currentIntervalMillis)

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
            // Location is switched off at the OS level. Nothing can be
            // registered, so no callback will ever arrive to recover on its
            // own — the watchdog's retry is the only way back, and until then
            // the user must be told, or they will trust an alarm that cannot
            // possibly ring.
            Log.w(TAG, "No location provider is enabled; cannot watch")
            isReceivingUpdates = false
            updateNotification()
            NotificationHelper.postLocationOffNotification(this)
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
            if (!isReceivingUpdates) {
                isReceivingUpdates = true
                NotificationHelper.clearLocationOffNotification(this)
                updateNotification()
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission missing; stopping watch", e)
            isReceivingUpdates = false
            stopWatching()
        } catch (e: Exception) {
            Log.e(TAG, "Could not request location updates", e)
            isReceivingUpdates = false
        }
    }

    private fun onLocation(location: Location) {
        val entries = AlarmStore(this).loadAll()
        if (entries.isEmpty()) {
            stopWatching()
            return
        }

        arrivalState.forgetAllExcept(entries.map { it.id })
        ignoredSince.keys.retainAll(entries.map { it.id }.toSet())

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
                // A fix far vaguer than the radius cannot actually place the
                // user inside it — a cell-tower fix can be kilometres out, and
                // acting on one rings the alarm nowhere near the stop. Wait for
                // a sharper fix instead; one is normally seconds away, since
                // proximity has already tightened the polling interval.
                //
                // But "normally" fails under an elevated rail viaduct or a
                // covered platform, where multipath can keep every fix above
                // the accuracy floor for as long as the phone stays there — a
                // real arrival reported minutes late, once the phone reaches
                // open sky again. A run of fixes that all land inside the same
                // radius for a full minute is not one bad reading, so past
                // that point the fix is trusted regardless of its accuracy.
                val confirmed = canConfirmArrival(location, entry.radius) ||
                    SystemClock.elapsedRealtime() -
                    ignoredSince.getOrPut(entry.id) { SystemClock.elapsedRealtime() } >=
                    ACCURACY_FALLBACK_MILLIS

                if (!confirmed) {
                    Log.i(TAG, "Ignoring ${location.accuracy}m fix for ${entry.label}")
                } else {
                    ignoredSince.remove(entry.id)

                    if (!entry.ringsOn(todayIsoWeekday())) {
                        // Armed, but not for today. Deliberately checked before
                        // the suppression test so the alarm is not left needing
                        // an exit it already made: the user genuinely arrived,
                        // the schedule simply says not today, and tomorrow's
                        // arrival should be treated as an arrival.
                        Log.i(TAG, "Inside ${entry.label} but not scheduled today")
                        arrivalState.suppressUntilExit(entry.id)
                    } else if (entry.repeats && arrivalState.hasRungToday(entry.id, today())) {
                        // Left the radius and came back the same day. One ring a
                        // day is what a repeating reminder means.
                        Log.i(TAG, "${entry.label} already rang today")
                        arrivalState.suppressUntilExit(entry.id)
                    } else if (arrivalState.shouldSuppress(entry.id)) {
                        // Arrival means crossing *into* the radius. Being inside
                        // already the first time this alarm is seen is not an
                        // arrival, so an alarm set for where you're standing
                        // doesn't ring at once.
                        Log.i(TAG, "Inside ${entry.label} but not arrived; awaiting exit")
                    } else {
                        triggerAlarm(entry)
                        return
                    }
                }
            } else {
                ignoredSince.remove(entry.id)
                arrivalState.markOutside(entry.id)
            }

            if (closest == null || distance < closest.second) {
                closest = entry to distance
            }
        }

        closest?.let { (entry, distance) ->
            nearestLabel = entry.label
            nearestDistance = distance
            updateNotification()
            adaptIntervalTo(distance, location)
        }
    }

    /**
     * Today as 1 = Monday through 7 = Sunday, matching Dart's
     * `DateTime.weekday` and so the numbers stored in [AlarmEntry.repeatDays].
     *
     * [Calendar.DAY_OF_WEEK] counts from Sunday = 1, which is the same range
     * meaning different days — storing one and comparing against the other
     * would arm every alarm one day early.
     */
    private fun todayIsoWeekday(): Int =
        ((Calendar.getInstance().get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1

    /** The local calendar date, as the key for "has this rung today". */
    private fun today(): String {
        val cal = Calendar.getInstance()
        return "%04d-%02d-%02d".format(
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH),
        )
    }

    /**
     * Whether [location] is precise enough to say the user is inside a
     * [radiusMetres] circle.
     *
     * The floor matters as much as the ratio: with a tight radius on a phone
     * indoors, insisting on radius-grade accuracy could hold the alarm back
     * indefinitely, and a missed stop is the worse failure. Anything up to
     * [ACCURACY_FLOOR_METRES] is therefore accepted regardless of radius,
     * which still excludes the kilometre-scale fixes that cause false alarms.
     */
    private fun canConfirmArrival(location: Location, radiusMetres: Double): Boolean {
        if (!location.hasAccuracy()) return true
        return location.accuracy <= maxOf(radiusMetres, ACCURACY_FLOOR_METRES)
    }

    /**
     * Polls harder the closer the user gets. Ten-second fixes from across the
     * country would flatten the battery on a long journey for no benefit,
     * while two-minute fixes 200m out would sail past the stop.
     */
    private fun adaptIntervalTo(distanceMetres: Double, location: Location) {
        val byDistance = when {
            distanceMetres > 10_000 -> VERY_FAR_INTERVAL_MILLIS
            distanceMetres > 5_000 -> FAR_INTERVAL_MILLIS
            distanceMetres > 1_500 -> 60_000L
            distanceMetres > 500 -> 20_000L
            else -> NEAR_INTERVAL_MILLIS
        }

        // Distance on its own assumes a speed, and on a highway coach or an
        // intercity train it assumes far too low a one. At 30 m/s the 500m
        // band's 20s interval covers 600m between consecutive fixes, so a
        // tight radius can be crossed entirely without ever being sampled.
        // Where the fix reports a speed, poll on time-to-arrival as well and
        // take whichever of the two answers is tighter.
        val speed = location.takeIf { it.hasSpeed() }?.speed?.takeIf { it > 1f }
        val target = if (speed == null) {
            byDistance
        } else {
            // A quarter of the remaining journey, so four fixes land between
            // here and the destination however fast "here" happens to be.
            val byEta = (distanceMetres / speed / 4 * 1000).toLong()
                .coerceIn(NEAR_INTERVAL_MILLIS, VERY_FAR_INTERVAL_MILLIS)
            minOf(byDistance, byEta)
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

        // A repeating alarm survives the ring, and the user is standing
        // inside its radius as it does. Without this it would ring again on
        // the very next fix, and every fix after that. See
        // [ArrivalState.suppressUntilExit].
        //
        // The day is marked here rather than where it is checked, because
        // here is the only place we know the alarm actually rang.
        if (entry.repeats) {
            arrivalState.markRungToday(entry.id, today())
            arrivalState.suppressUntilExit(entry.id)
        }

        // The alarm service consumes the entry itself, so this deliberately
        // asks only about the *other* entries: whether this one has been
        // removed yet is a race, and whether anything else is armed is not.
        //
        // A repeating alarm is not consumed at all, so it still counts as
        // armed and the watch has to stay up for it. Stopping here would have
        // been the whole feature failing silently on the second week: the
        // alarm survives in the store, the service that watches for it does
        // not, and nothing restarts it until the app is next opened.
        val othersArmed = AlarmStore(this).loadAll().any { it.id != entry.id }
        if (!entry.repeats && !othersArmed) {
            stopWatching()
        }
    }

    private fun stopWatching() {
        isWatching = false
        isReceivingUpdates = false
        NotificationHelper.clearLocationOffNotification(this)
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
        isReceivingUpdates = false
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
            !isReceivingUpdates -> getString(R.string.watch_location_off)
            label == null || distance == null ->
                resources.getQuantityString(R.plurals.watch_armed, armedCount, armedCount)
            distance >= 1000 ->
                getString(R.string.watch_distance_km, "%.1f".format(distance / 1000), label)
            else ->
                getString(R.string.watch_distance_m, distance.toInt().toString(), label)
        }

        return NotificationCompat.Builder(this, NotificationHelper.WATCH_CHANNEL_ID)
            .setContentTitle(
                getString(
                    if (isReceivingUpdates) R.string.watch_title_active
                    else R.string.watch_title_inactive,
                ),
            )
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
        private const val ACCURACY_FLOOR_METRES = 500.0
        private const val ACCURACY_FALLBACK_MILLIS = 60_000L

        var isWatching: Boolean = false
            private set

        /**
         * Whether fixes are actually being delivered, as opposed to the
         * service merely being alive. The two diverge exactly when location is
         * switched off at the OS level: the service runs, holds its
         * notification and looks armed, while nothing can ever trigger. Kept
         * separate so the watchdog can tell that case apart and retry.
         */
        var isReceivingUpdates: Boolean = false
            private set
    }
}
