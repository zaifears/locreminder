package com.zaifears.locreminder

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.location.LocationManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.zaifears.locreminder/alarms"

    /** Held across the sound-picker activity result, then completed. */
    private var pendingSoundResult: MethodChannel.Result? = null
    private var previewPlayer: android.media.MediaPlayer? = null

    private companion object {
        const val REQUEST_PICK_RINGTONE = 8101
        const val REQUEST_PICK_AUDIO_FILE = 8102

        /**
         * How long to wait for a fresh fix before falling back to the cached
         * one. Long enough for GPS to come up from cold outdoors, short enough
         * that the button never feels stuck.
         */
        const val FRESH_FIX_TIMEOUT_MILLIS = 8_000L
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "addAlarm" -> {
                    val id = call.argument<String>("id")
                    val lat = call.argument<Double>("latitude")
                    val lng = call.argument<Double>("longitude")
                    val radius = call.argument<Double>("radius")
                    val label = call.argument<String>("label") ?: "Destination"
                    if (id == null || lat == null || lng == null || radius == null) {
                        result.error("INVALID_ARGS", "id, latitude, longitude and radius are required", null)
                    } else {
                        AlarmStore(this).save(AlarmEntry(id, label, lat, lng, radius))
                        result.success(true)
                    }
                }
                "removeAlarm" -> {
                    val id = call.argument<String>("id")
                    if (id == null) {
                        result.error("INVALID_ARGS", "id is required", null)
                    } else {
                        AlarmStore(this).remove(id)
                        result.success(true)
                    }
                }
                "removeAllAlarms" -> {
                    AlarmStore(this).clear()
                    result.success(true)
                }
                "getActiveAlarmIds" -> result.success(AlarmStore(this).loadAll().map { it.id })
                // Replaces the geolocator plugin, which pulled in Play
                // Services transitively.
                "isLocationEnabled" -> {
                    val manager = getSystemService(LocationManager::class.java)
                    val enabled = manager != null && (
                        runCatching { manager.isProviderEnabled(LocationManager.GPS_PROVIDER) }.getOrDefault(false) ||
                            runCatching { manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) }.getOrDefault(false)
                        )
                    result.success(enabled)
                }
                "openLocationSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getLastKnownLocation" -> result.success(lastKnownLocation())
                "getCurrentLocation" -> currentLocation(result)
                "isIgnoringBatteryOptimizations" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                // Android 14+ gates full-screen intents behind a separate
                // capability that is only auto-granted to some app categories,
                // so the alarm screen can silently fail to appear without it.
                "canUseFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val manager = getSystemService(NotificationManager::class.java)
                        result.success(manager?.canUseFullScreenIntent() ?: false)
                    } else {
                        result.success(true)
                    }
                }
                "requestFullScreenIntentPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        try {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    Uri.parse("package:$packageName"),
                                ),
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }
                // The watch service is what makes triggering dependable; the
                // Dart layer keeps it running exactly while alarms are armed.
                "startLocationWatch" -> {
                    try {
                        ContextCompat.startForegroundService(
                            this,
                            Intent(this, LocationWatchService::class.java),
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WATCH_START_FAILED", e.message, null)
                    }
                }
                "stopLocationWatch" -> {
                    startService(
                        Intent(this, LocationWatchService::class.java).apply {
                            action = LocationWatchService.ACTION_STOP
                        },
                    )
                    result.success(true)
                }
                "isLocationWatchRunning" -> result.success(LocationWatchService.isWatching)
                "getDeviceInfo" -> result.success(
                    mapOf(
                        "manufacturer" to (android.os.Build.MANUFACTURER ?: ""),
                        "model" to (android.os.Build.MODEL ?: ""),
                        "sdkInt" to android.os.Build.VERSION.SDK_INT,
                        "needsExtraSetup" to OemHelper.needsExtraSetup(),
                    ),
                )
                "openAutoStartSettings" -> result.success(OemHelper.openAutoStartSettings(this))
                "openAppSettings" -> result.success(OemHelper.openAppSettings(this))
                // Fires the real alarm path after a delay so the user can lock
                // the screen and confirm it breaks through from a locked,
                // idle state — the condition that actually matters.
                "triggerTestAlarm" -> {
                    val delaySeconds = call.argument<Int>("delaySeconds") ?: 10
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        val testIntent = Intent(this, AlarmForegroundService::class.java).apply {
                            action = AlarmForegroundService.ACTION_START
                            putExtra(AlarmForegroundService.EXTRA_LABEL, getString(R.string.test_alarm_label))
                            putExtra(AlarmForegroundService.EXTRA_ALARM_ID, "")
                        }
                        try {
                            ContextCompat.startForegroundService(this, testIntent)
                        } catch (e: Exception) {
                            NotificationHelper.postFallbackAlarmNotification(this, getString(R.string.test_alarm_label))
                        }
                    }, delaySeconds * 1000L)
                    result.success(true)
                }
                "getAlarmSound" -> {
                    val settings = AlarmSettings(this)
                    result.success(
                        mapOf(
                            "uri" to settings.soundUri()?.toString(),
                            "name" to settings.soundName(),
                            "vibrate" to settings.vibrationEnabled(),
                        ),
                    )
                }
                "pickAlarmRingtone" -> startSoundPicker(result, ringtonePicker(), REQUEST_PICK_RINGTONE)
                "pickAlarmAudioFile" -> startSoundPicker(result, audioFilePicker(), REQUEST_PICK_AUDIO_FILE)
                "resetAlarmSound" -> {
                    AlarmSettings(this).setSound(null, null)
                    result.success(true)
                }
                "setAlarmVibration" -> {
                    AlarmSettings(this).setVibrationEnabled(call.argument<Boolean>("enabled") ?: true)
                    result.success(true)
                }
                "previewAlarmSound" -> {
                    playPreview()
                    result.success(true)
                }
                "stopAlarmSoundPreview" -> {
                    stopPreview()
                    result.success(true)
                }
                "isAlarmRinging" -> result.success(AlarmForegroundService.isRinging)
                "stopAlarm" -> {
                    startService(
                        Intent(this, AlarmForegroundService::class.java).apply {
                            action = AlarmForegroundService.ACTION_STOP
                        },
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ---------------------------------------------------------------- sound

    private fun ringtonePicker(): Intent {
        return Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Choose an alarm sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                AlarmSettings(this@MainActivity).soundUri(),
            )
        }
    }

    private fun audioFilePicker(): Intent {
        return Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            // Lets the picker offer formats whose MIME type some providers
            // report inconsistently, mp3 among them.
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("audio/mpeg", "audio/mp4", "audio/ogg", "audio/x-wav", "audio/flac", "audio/*"),
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun startSoundPicker(result: MethodChannel.Result, intent: Intent, requestCode: Int) {
        if (pendingSoundResult != null) {
            result.error("PICKER_BUSY", "A sound picker is already open", null)
            return
        }
        try {
            pendingSoundResult = result
            startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            pendingSoundResult = null
            result.error("PICKER_UNAVAILABLE", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != REQUEST_PICK_RINGTONE && requestCode != REQUEST_PICK_AUDIO_FILE) return

        val pending = pendingSoundResult ?: return
        pendingSoundResult = null

        if (resultCode != RESULT_OK) {
            pending.success(null)
            return
        }

        val uri: Uri? = if (requestCode == REQUEST_PICK_RINGTONE) {
            @Suppress("DEPRECATION")
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        } else {
            data?.data
        }

        if (uri == null) {
            // The system picker returns no URI when "Default"/"None" is chosen.
            AlarmSettings(this).setSound(null, null)
            pending.success(null)
            return
        }

        // A document URI is only readable in future processes if we take a
        // persistable grant now — without this the alarm would fall silent
        // after the next reboot.
        if (requestCode == REQUEST_PICK_AUDIO_FILE) {
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (e: SecurityException) {
                android.util.Log.w("MainActivity", "Could not persist read access to $uri", e)
            }
        }

        val name = AlarmSettings.displayNameFor(this, uri)
        AlarmSettings(this).setSound(uri, name)
        pending.success(mapOf("uri" to uri.toString(), "name" to name))
    }

    private fun playPreview() {
        stopPreview()
        val uri = AlarmSettings(this).resolvePlayableUri() ?: return
        try {
            previewPlayer = android.media.MediaPlayer().apply {
                setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(this@MainActivity, uri)
                isLooping = false
                prepare()
                start()
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Could not preview alarm sound", e)
        }
    }

    private fun stopPreview() {
        try {
            previewPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
        } catch (e: Exception) {
            android.util.Log.d("MainActivity", "Preview player already released", e)
        }
        previewPlayer = null
    }

    override fun onStop() {
        // Never let a preview keep playing once the screen is gone.
        stopPreview()
        super.onStop()
    }

    // ------------------------------------------------------------- location

    /**
     * Most recent fix known to the platform, used to centre the map. Returns
     * null rather than waiting for a fresh fix — the map has a sensible
     * default, and blocking the UI on GPS would be worse than showing it.
     */
    private fun lastKnownLocation(): Map<String, Any?>? {
        val manager = getSystemService(LocationManager::class.java) ?: return null

        val providers = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.GPS_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
            add(LocationManager.PASSIVE_PROVIDER)
        }

        var best: android.location.Location? = null
        for (provider in providers) {
            val location = try {
                manager.getLastKnownLocation(provider)
            } catch (e: SecurityException) {
                return null
            } catch (e: Exception) {
                null
            } ?: continue

            if (best == null || location.time > best.time) best = location
        }

        return (best ?: return null).asMap()
    }

    private fun android.location.Location.asMap(): Map<String, Any?> = mapOf(
        "latitude" to latitude,
        "longitude" to longitude,
        "accuracy" to accuracy.toDouble(),
        // Metres per second, or null where the provider doesn't report it.
        // The picker uses it to warn that a tight radius may be crossed
        // between fixes at the speed the user is currently travelling.
        "speed" to if (hasSpeed()) speed.toDouble() else null,
        // Lets the caller judge staleness. A cached fix can be hours old and
        // hundreds of kilometres away, which is worth showing differently
        // from a fix taken just now.
        "time" to time,
    )

    /**
     * Asks for a fresh fix, falling back to the cached one if nothing arrives
     * in time.
     *
     * [lastKnownLocation] alone is not enough for "centre on my location":
     * right after a boot or a fresh install the platform holds no fix at all
     * and it returns null, leaving the button doing nothing at all — and when
     * it does return something, that something can be badly out of date.
     */
    private fun currentLocation(result: MethodChannel.Result) {
        val manager = getSystemService(LocationManager::class.java)
        if (manager == null) {
            result.success(null)
            return
        }

        val providers = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.GPS_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
        }.filter { provider ->
            runCatching { manager.isProviderEnabled(provider) }.getOrDefault(false)
        }

        if (providers.isEmpty()) {
            result.success(lastKnownLocation())
            return
        }

        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        var settled = false
        // A one-slot holder rather than a `var`: settle() has to unregister
        // the listener, but the listener has to call settle(), and Kotlin
        // won't smart-cast a var captured by a closure back to non-null.
        val registered = arrayOfNulls<android.location.LocationListener>(1)

        fun settle(value: Map<String, Any?>?) {
            if (settled) return
            settled = true
            registered[0]?.let { runCatching { manager.removeUpdates(it) } }
            result.success(value)
        }

        val giveUp = Runnable { settle(lastKnownLocation()) }

        val listener = object : android.location.LocationListener {
            override fun onLocationChanged(location: android.location.Location) {
                handler.removeCallbacks(giveUp)
                settle(location.asMap())
            }

            // Explicit for API 23; the interface defaults only exist from 30.
            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(provider: String?, status: Int, extras: android.os.Bundle?) = Unit

            override fun onProviderEnabled(provider: String) = Unit

            override fun onProviderDisabled(provider: String) = Unit
        }
        registered[0] = listener

        try {
            for (provider in providers) {
                manager.requestLocationUpdates(provider, 0L, 0f, listener, mainLooper)
            }
            handler.postDelayed(giveUp, FRESH_FIX_TIMEOUT_MILLIS)
        } catch (e: SecurityException) {
            settle(null)
        } catch (e: Exception) {
            settle(lastKnownLocation())
        }
    }
}
