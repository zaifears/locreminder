package com.zaifears.locreminder

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.location.LocationRequest
import android.os.Build
import android.os.Bundle
import android.os.Handler
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
 *
 * Nothing here touches the network. GNSS is a receive-only radio: the
 * satellites broadcast, the phone listens, and no data connection is involved
 * at any point. That is what lets the alarm ring on a bus with no signal —
 * only the map tiles and the place search need the internet, and neither is
 * part of detection.
 */
class LocationWatchService : Service() {

    private lateinit var locationManager: LocationManager
    private var currentIntervalMillis: Long = FAR_INTERVAL_MILLIS
    private var nearestLabel: String? = null
    private var nearestDistance: Double? = null

    /** Last text put on the ongoing notification, so identical ones are skipped. */
    private var lastNotificationText: String? = null

    /**
     * When a fix last arrived, on the monotonic clock. Registration succeeding
     * says nothing about fixes actually being delivered — see
     * [onStarvationCheck] for the case where it silently is not.
     */
    private var lastFixElapsed: Long = 0

    /**
     * Whether the platform's own fused provider has been given up on for this
     * run, and the raw providers registered instead. Sticky on purpose: a
     * provider that starved once will starve again, and flapping between the
     * two costs more than staying on the one that works.
     */
    private var escalatedToRawProviders = false

    private val handler by lazy { Handler(mainLooper) }
    private val starvationCheck = Runnable { onStarvationCheck() }

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
        applyTodaysSchedule()

        WatchdogReceiver.schedule(this)
        return START_STICKY
    }

    /**
     * Watches only on days something can actually ring.
     *
     * A weekday commute alarm used to hold the GPS open all weekend for an
     * alarm that could not fire until Monday — two days of polling for
     * nothing, which is a large share of what people mean when they say this
     * app drains their battery. On a day when no armed alarm is scheduled the
     * service stays alive, keeps its notification and stays out of Doze, but
     * asks for no fixes at all.
     *
     * Both edges of that are the watchdog's ordinary 15-minute tick, which
     * pokes the service whether or not anything looks wrong precisely so this
     * runs again: the day rolls over in the middle of a run, in both
     * directions, and nothing else would notice. A quarter of an hour either
     * side of midnight is ample for a journey nobody has started yet.
     *
     * Which is why this only re-registers when the state actually has to
     * change. Called every fifteen minutes for the life of an alarm, tearing
     * the registration down and building it back up each time would restart
     * the receiver's acquisition cycle four times an hour for nothing.
     */
    private fun applyTodaysSchedule() {
        val weekday = todayIsoWeekday()
        val ringsToday = AlarmStore(this).loadAll().any { it.ringsOn(weekday) }

        if (ringsToday) {
            if (isDormant) {
                isDormant = false
                // Yesterday's distance is not today's. Clearing it keeps the
                // notification from showing a stale number until the first
                // fix lands.
                nearestLabel = null
                nearestDistance = null
            } else if (isReceivingUpdates) {
                // Already watching, and watching correctly. The armed count
                // may have changed, which the notification says when it has
                // no distance to show yet; nothing else here has.
                updateNotification()
                return
            }
            requestUpdates(currentIntervalMillis)
            return
        }

        if (isDormant) return

        Log.i(TAG, "Nothing is scheduled to ring today; standing down until it is")
        isDormant = true
        isReceivingUpdates = false
        handler.removeCallbacks(starvationCheck)
        runCatching { locationManager.removeUpdates(locationListener) }
        NotificationHelper.clearLocationOffNotification(this)
        updateNotification()
    }

    /**
     * Providers to listen on, best first.
     *
     * Android 12 added a platform fused provider that blends GPS, wifi and
     * sensors the way Play Services does — preferred where present. Below
     * that, GPS and network are used together: network gives cheap coarse
     * fixes indoors, GPS the accuracy needed near the destination.
     *
     * The enabled check matters as much as the availability one. A provider
     * that exists but is switched off delivers nothing, and registering on it
     * regardless left the service claiming to watch while location was off at
     * the OS level — armed, notified, and incapable of ever ringing.
     */
    private fun activeProviders(): List<String> {
        val available = try {
            locationManager.allProviders
        } catch (e: Exception) {
            emptyList<String>()
        }

        if (!escalatedToRawProviders &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            available.contains(LocationManager.FUSED_PROVIDER) &&
            runCatching { locationManager.isProviderEnabled(LocationManager.FUSED_PROVIDER) }
                .getOrDefault(false)
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
            handler.removeCallbacks(starvationCheck)
            updateNotification()
            NotificationHelper.postLocationOffNotification(this)
            return
        }

        try {
            locationManager.removeUpdates(locationListener)
            for (provider in providers) {
                register(provider, intervalMillis)
            }

            // Fixes another app has already paid for are free to read, so at
            // the long intervals of a journey's early hours it is worth
            // listening for them: a mapping app running alongside this one
            // keeps the distance current at no cost in battery at all.
            if (intervalMillis >= PASSIVE_PIGGYBACK_FROM_MILLIS &&
                runCatching { locationManager.allProviders }
                    .getOrDefault(emptyList<String>())
                    .contains(LocationManager.PASSIVE_PROVIDER)
            ) {
                register(
                    LocationManager.PASSIVE_PROVIDER,
                    maxOf(NEAR_INTERVAL_MILLIS, intervalMillis / 4),
                )
            }

            currentIntervalMillis = intervalMillis
            armStarvationCheck()
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

    /**
     * Registers one provider, asking for as little power as the current
     * distance allows.
     *
     * Android 12 added a way to say what a request is actually for, and the
     * platform bills accordingly: [LocationRequest.QUALITY_HIGH_ACCURACY]
     * turns the GNSS receiver on for every fix, while
     * [LocationRequest.QUALITY_BALANCED_POWER_ACCURACY] lets it answer from
     * whatever it already knows when that is good enough. Only the last few
     * hundred metres need the expensive answer, so only they ask for it.
     *
     * [LocationRequest.QUALITY_LOW_POWER] is deliberately never used: it is
     * the tier that gives up on GNSS entirely, and on a phone with no data
     * connection — the exact situation this alarm exists for — that is a
     * request for fixes that can never arrive.
     */
    private fun register(provider: String, intervalMillis: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val request = LocationRequest.Builder(intervalMillis)
                .setQuality(
                    if (intervalMillis <= HIGH_ACCURACY_UP_TO_MILLIS) {
                        LocationRequest.QUALITY_HIGH_ACCURACY
                    } else {
                        LocationRequest.QUALITY_BALANCED_POWER_ACCURACY
                    },
                )
                .apply {
                    // Letting the hardware hold a couple of fixes back and
                    // deliver them together lets the processor stay asleep
                    // between them. Only offered when the next fix is minutes
                    // out anyway, where the delay it adds cannot matter.
                    if (intervalMillis >= BATCHING_FROM_MILLIS) {
                        setMaxUpdateDelayMillis(intervalMillis)
                    }
                }
                .build()
            locationManager.requestLocationUpdates(provider, request, mainExecutor, locationListener)
        } else {
            locationManager.requestLocationUpdates(
                provider,
                intervalMillis,
                0f,
                locationListener,
                mainLooper,
            )
        }
    }

    /** Re-checks, after a generous grace period, that fixes are still arriving. */
    private fun armStarvationCheck() {
        handler.removeCallbacks(starvationCheck)
        handler.postDelayed(starvationCheck, starvationDeadlineMillis())
    }

    /**
     * How long silence has to last before it counts as a provider failing
     * rather than a phone indoors.
     *
     * Three missed intervals is the signal, but with a floor under it: near
     * the destination the interval is ten seconds, and a GNSS receiver in a
     * building can easily take longer than thirty to produce anything at all.
     * Treating that as a fault would mean tearing down a working registration
     * every time somebody waits inside a shop.
     */
    private fun starvationDeadlineMillis(): Long =
        maxOf(currentIntervalMillis * 3, MIN_STARVATION_MILLIS) + STARVATION_GRACE_MILLIS

    /**
     * Handles a registration that succeeded but delivers nothing.
     *
     * The fused provider is the usual cause. It is a blend, and on some
     * builds — de-Googled ROMs especially, but also ordinary phones with no
     * data connection — the half of the blend it prefers is the network one,
     * so with no internet it can sit there answering nothing at all while
     * GPS, which needs no internet whatsoever, would have had a fix in
     * seconds. Falling back to the raw providers is what makes the alarm work
     * on a bus with no signal.
     */
    private fun onStarvationCheck() {
        if (isDormant || !isWatching) return

        val silentFor = SystemClock.elapsedRealtime() - lastFixElapsed
        if (lastFixElapsed != 0L && silentFor < starvationDeadlineMillis()) {
            armStarvationCheck()
            return
        }

        if (!escalatedToRawProviders && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Log.w(TAG, "No fix in ${silentFor}ms; falling back to GPS and network")
            escalatedToRawProviders = true
            requestUpdates(currentIntervalMillis)
            return
        }

        // Already on the raw providers and still nothing. Deliberately *not*
        // reported as a fault: on the raw providers, prolonged silence is
        // usually a phone that is simply indoors, and saying "location is off"
        // to somebody whose location is plainly on would be a lie that also
        // sends the watchdog into restarting a registration that is working
        // as well as it can. Logged, and left alone.
        Log.w(TAG, "No fix in ${silentFor}ms on raw providers")
        armStarvationCheck()
    }

    private fun onLocation(location: Location) {
        lastFixElapsed = SystemClock.elapsedRealtime()
        if (!isReceivingUpdates) {
            isReceivingUpdates = true
            NotificationHelper.clearLocationOffNotification(this)
        }

        val entries = AlarmStore(this).loadAll()
        if (entries.isEmpty()) {
            stopWatching()
            return
        }

        val liveIds = entries.map { it.id }
        arrivalState.forgetAllExcept(liveIds)
        ignoredSince.keys.retainAll(liveIds.toSet())

        // Named for the day of the week, not the date: [today] is the date,
        // and the two are used a few lines apart.
        val weekday = todayIsoWeekday()
        var closest: Pair<AlarmEntry, Double>? = null

        for (entry in entries) {
            val distance = distanceBetween(location, entry)

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
                // that point the fix is trusted — provided it is merely
                // imprecise and not a cell-ID-only guess tens of kilometres
                // wide, which persisting for a minute does nothing to make
                // trustworthy.
                val confirmed = canConfirmArrival(location, entry.radius) || run {
                    val since = ignoredSince.getOrPut(entry.id) { SystemClock.elapsedRealtime() }
                    val overdue = SystemClock.elapsedRealtime() - since >= ACCURACY_FALLBACK_MILLIS
                    overdue && location.accuracy <= ACCURACY_FALLBACK_CEILING_METRES
                }

                if (!confirmed) {
                    Log.i(TAG, "Ignoring ${location.accuracy}m fix for ${entry.label}")
                } else {
                    ignoredSince.remove(entry.id)

                    if (!entry.ringsOn(weekday)) {
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
        }
        adaptIntervalTo(location, entries, weekday)
    }

    private fun distanceBetween(location: Location, entry: AlarmEntry): Double {
        val results = FloatArray(1)
        Location.distanceBetween(
            location.latitude,
            location.longitude,
            entry.latitude,
            entry.longitude,
            results,
        )
        return results[0].toDouble()
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
     * Sets the polling interval from the one thing that actually decides
     * whether an alarm can be missed: how long the user could still be far
     * enough away for the next fix to be worth waiting for.
     *
     * The gap between two fixes is safe as long as it cannot cover the whole
     * distance to the far side of the destination circle — that is
     * `distance + radius` metres. Divided by the speed being travelled and by
     * [SAMPLES_BEFORE_ARRIVAL], it gives an interval that keeps several fixes
     * between here and the stop no matter what the numbers are, and it does
     * so without a table of hand-picked distance bands that were each only
     * ever right for one kind of journey.
     *
     * Where the fix reports a speed, that speed is used. Where it does not —
     * or reports a bus sitting at a light — [CRUISE_SPEED_MPS] stands in for
     * how fast the journey could resume, so a stationary phone is never
     * lulled into an interval it cannot get out of.
     *
     * What this changes in practice: two hours into a 300 km coach journey
     * the old fixed ladder was still waking the GNSS receiver every five
     * minutes, for a stop that could not physically arrive for another hour.
     * It now waits a quarter of an hour, and tightens continuously as the
     * distance falls, reaching ten-second fixes for the final approach
     * exactly as before.
     */
    private fun adaptIntervalTo(location: Location, entries: List<AlarmEntry>, weekday: Int) {
        val reported = if (location.hasSpeed() && location.speed > 1f) location.speed else 0f
        val planned = maxOf(reported, CRUISE_SPEED_MPS)

        var target = MAX_INTERVAL_MILLIS
        for (entry in entries) {
            if (!entry.ringsOn(weekday)) continue
            val reach = distanceBetween(location, entry) + entry.radius
            val safe = (reach / planned / SAMPLES_BEFORE_ARRIVAL * 1000).toLong()
            target = minOf(target, safe)
        }

        // Quantised, because re-registering restarts the receiver's whole
        // acquisition cycle. Left continuous, a target that drifted by a
        // second between fixes would pay that cost on every single one.
        val stepped = INTERVAL_STEPS_MILLIS.lastOrNull { it <= target } ?: NEAR_INTERVAL_MILLIS
        if (stepped != currentIntervalMillis) requestUpdates(stepped)
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
        isDormant = false
        handler.removeCallbacks(starvationCheck)
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
        isDormant = false
        handler.removeCallbacks(starvationCheck)
        try {
            locationManager.removeUpdates(locationListener)
        } catch (_: Exception) {
            // Ignored.
        }
        super.onDestroy()
    }

    /**
     * Re-posts the ongoing notification, but only when it would actually read
     * differently.
     *
     * Every fix used to re-post it, which at ten-second fixes is a wakeup and
     * a round trip to the notification manager six times a minute to redraw
     * the same sentence. The distance only changes the text when the rounded
     * number does.
     */
    private fun updateNotification() {
        val text = notificationText()
        if (text == lastNotificationText) return

        val manager = getSystemService(android.app.NotificationManager::class.java) ?: return
        val notification = buildNotification(text)
        try {
            manager.notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Notification permission revoked.
        }
    }

    private fun notificationText(): String {
        val distance = nearestDistance
        val label = nearestLabel
        return when {
            isDormant -> getString(R.string.watch_dormant_body)
            !isReceivingUpdates -> getString(R.string.watch_location_off)
            label == null || distance == null -> {
                val armedCount = AlarmStore(this).loadAll().size
                resources.getQuantityString(R.plurals.watch_armed, armedCount, armedCount)
            }
            distance >= 1000 ->
                getString(R.string.watch_distance_km, "%.1f".format(distance / 1000), label)
            else ->
                getString(R.string.watch_distance_m, distance.toInt().toString(), label)
        }
    }

    private fun buildNotification(text: String = notificationText()): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        lastNotificationText = text

        return NotificationCompat.Builder(this, NotificationHelper.WATCH_CHANNEL_ID)
            .setContentTitle(
                getString(
                    when {
                        isDormant -> R.string.watch_title_dormant
                        isReceivingUpdates -> R.string.watch_title_active
                        else -> R.string.watch_title_inactive
                    },
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
        private const val FAR_INTERVAL_MILLIS = 120_000L
        private const val NEAR_INTERVAL_MILLIS = 10_000L
        private const val MAX_INTERVAL_MILLIS = 900_000L
        private const val ACCURACY_FLOOR_METRES = 500.0
        private const val ACCURACY_FALLBACK_MILLIS = 60_000L

        /**
         * The intervals actually used, so that a continuously computed target
         * turns into a handful of stable registrations rather than a new one
         * on every fix.
         */
        private val INTERVAL_STEPS_MILLIS = listOf(
            10_000L, 15_000L, 20_000L, 30_000L, 45_000L, 60_000L,
            90_000L, 120_000L, 180_000L, 300_000L, 600_000L, MAX_INTERVAL_MILLIS,
        )

        /**
         * How fast to assume the journey could be moving when the fix does not
         * say — 72 km/h, which covers a highway coach and leaves margin for an
         * intercity train that has not reported its speed yet.
         */
        private const val CRUISE_SPEED_MPS = 20f

        /** Fixes to fit between here and the far side of the destination. */
        private const val SAMPLES_BEFORE_ARRIVAL = 3

        /** Above this interval, the expensive always-GNSS tier is not asked for. */
        private const val HIGH_ACCURACY_UP_TO_MILLIS = 30_000L

        /** Above this interval, fixes may be batched so the processor can sleep. */
        private const val BATCHING_FROM_MILLIS = 300_000L

        /** Above this interval, other apps' fixes are worth listening for. */
        private const val PASSIVE_PIGGYBACK_FROM_MILLIS = 60_000L

        /** Slack on top of three missed intervals before calling it starvation. */
        private const val STARVATION_GRACE_MILLIS = 60_000L

        /** Floor under that, so a short interval cannot make it trigger-happy. */
        private const val MIN_STARVATION_MILLIS = 300_000L

        // Bad-but-plausible GPS or network accuracy under a viaduct or roof
        // is in the hundreds to low thousands of metres. Far past that is not
        // a degraded fix, it is cell-ID-only noise with no real position in
        // it, and no amount of waiting makes it worth trusting.
        private const val ACCURACY_FALLBACK_CEILING_METRES = 3_000.0

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

        /**
         * Whether the service is deliberately not asking for fixes because
         * nothing armed is scheduled to ring today. Distinct from the state
         * above, which is a fault: this one is the service doing its job by
         * doing nothing, and restarting it would not be a repair.
         */
        var isDormant: Boolean = false
            private set
    }
}
