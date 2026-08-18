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
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.zaifears.locreminder/geofence"
    private lateinit var geofencingClient: GeofencingClient

    /** Held across the sound-picker activity result, then completed. */
    private var pendingSoundResult: MethodChannel.Result? = null
    private var previewPlayer: android.media.MediaPlayer? = null

    private companion object {
        const val MIN_APPROACH_RADIUS_METRES = 2000f
        const val REQUEST_PICK_RINGTONE = 8101
        const val REQUEST_PICK_AUDIO_FILE = 8102
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        geofencingClient = LocationServices.getGeofencingClient(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "addGeofence" -> {
                    val id = call.argument<String>("id")
                    val lat = call.argument<Double>("latitude")
                    val lng = call.argument<Double>("longitude")
                    val radius = call.argument<Double>("radius")
                    val label = call.argument<String>("label") ?: "Destination"
                    if (id == null || lat == null || lng == null || radius == null) {
                        result.error("INVALID_ARGS", "id, latitude, longitude and radius are required", null)
                    } else {
                        addGeofence(id, lat, lng, radius.toFloat(), label, result)
                    }
                }
                "removeGeofence" -> {
                    val id = call.argument<String>("id")
                    if (id == null) {
                        result.error("INVALID_ARGS", "id is required", null)
                    } else {
                        removeGeofence(id, result)
                    }
                }
                "removeAllGeofences" -> removeAllGeofences(result)
                "getActiveGeofenceIds" -> result.success(GeofenceStore(this).loadAll().map { it.id })
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
                            putExtra(AlarmForegroundService.EXTRA_LABEL, "Test alarm")
                            putExtra(AlarmForegroundService.EXTRA_GEOFENCE_ID, "")
                        }
                        try {
                            ContextCompat.startForegroundService(this, testIntent)
                        } catch (e: Exception) {
                            NotificationHelper.postFallbackAlarmNotification(this, "Test alarm")
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

    private fun geofencePendingIntent(): PendingIntent {
        val intent = Intent(this, GeofenceBroadcastReceiver::class.java).apply {
            action = GeofenceBroadcastReceiver.ACTION_GEOFENCE_EVENT
        }
        // Geofencing requires a MUTABLE PendingIntent on Android 12+ since the
        // system fills in the triggering-geofence extras before broadcasting it.
        return PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    private fun addGeofence(
        id: String,
        latitude: Double,
        longitude: Double,
        radius: Float,
        label: String,
        result: MethodChannel.Result,
    ) {
        val geofence = Geofence.Builder()
            .setRequestId(id)
            .setCircularRegion(latitude, longitude, radius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
            .build()

        // A much larger outer ring whose only job is to wake the watcher for
        // the final approach. Because it is kilometres wide, even a Doze-
        // deferred delivery still lands with plenty of distance to spare —
        // the same deferral would be fatal on the inner ring.
        val approachRadius = maxOf(radius * 8f, MIN_APPROACH_RADIUS_METRES)
        val approachFence = Geofence.Builder()
            .setRequestId(id + GeofenceBroadcastReceiver.APPROACH_SUFFIX)
            .setCircularRegion(latitude, longitude, approachRadius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
            .build()

        val request = GeofencingRequest.Builder()
            .addGeofence(geofence)
            .addGeofence(approachFence)
            // Without this, Play Services fires ENTER immediately if the user
            // is already inside the radius — so setting an alarm for a place
            // you are currently near would ring the moment you saved it.
            .setInitialTrigger(0)
            .build()

        try {
            geofencingClient.addGeofences(request, geofencePendingIntent())
                .addOnSuccessListener {
                    GeofenceStore(this).save(GeofenceEntry(id, label, latitude, longitude, radius.toDouble()))
                    result.success(true)
                }
                .addOnFailureListener { e ->
                    result.error("GEOFENCE_ADD_FAILED", e.message, null)
                }
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        }
    }

    private fun removeGeofence(id: String, result: MethodChannel.Result) {
        // The approach ring is registered alongside every alarm, so it has to
        // be torn down with it or it would linger and keep waking the watcher.
        val ids = listOf(id, id + GeofenceBroadcastReceiver.APPROACH_SUFFIX)
        geofencingClient.removeGeofences(ids)
            .addOnCompleteListener {
                GeofenceStore(this).remove(id)
                result.success(true)
            }
    }

    private fun removeAllGeofences(result: MethodChannel.Result) {
        geofencingClient.removeGeofences(geofencePendingIntent())
            .addOnCompleteListener {
                GeofenceStore(this).clear()
                result.success(true)
            }
    }
}
