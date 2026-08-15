package com.zaifears.locreminder

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
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

        val request = GeofencingRequest.Builder()
            .addGeofence(geofence)
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
        geofencingClient.removeGeofences(listOf(id))
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
