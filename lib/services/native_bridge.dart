import 'package:flutter/services.dart';

import '../models/location_alarm.dart';

/// Talks to the native Android geofencing + alarm engine
/// (MainActivity.kt / AlarmForegroundService.kt) over a MethodChannel.
///
/// The actual geofence monitoring and alarm ringing happen entirely on the
/// native side via Play Services' GeofencingClient and a foreground service,
/// so they keep working even if this Flutter engine instance is not running.
class NativeBridge {
  static const _channel = MethodChannel('com.zaifears.locreminder/geofence');

  Future<void> addGeofence(LocationAlarm alarm) {
    return _channel.invokeMethod<void>('addGeofence', {
      'id': alarm.id,
      'latitude': alarm.latitude,
      'longitude': alarm.longitude,
      'radius': alarm.radiusMeters,
      'label': alarm.label,
    });
  }

  Future<void> removeGeofence(String id) {
    return _channel.invokeMethod<void>('removeGeofence', {'id': id});
  }

  Future<void> removeAllGeofences() {
    return _channel.invokeMethod<void>('removeAllGeofences');
  }

  Future<List<String>> getActiveGeofenceIds() async {
    final result = await _channel.invokeMethod<List<Object?>>('getActiveGeofenceIds');
    return result?.map((e) => e.toString()).toList() ?? const [];
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return result ?? false;
  }

  Future<void> requestIgnoreBatteryOptimizations() {
    return _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
  }

  /// Android 14+ gates full-screen intents separately; without it the alarm
  /// can ring without ever showing its screen. Always true below 14.
  Future<bool> canUseFullScreenIntent() async {
    final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
    return result ?? true;
  }

  Future<void> requestFullScreenIntentPermission() {
    return _channel.invokeMethod<void>('requestFullScreenIntentPermission');
  }

  /// Starts the foreground service that actively watches location. This is
  /// what makes arrival detection dependable — geofence broadcasts alone get
  /// deferred by Doze once the app goes idle.
  Future<void> startLocationWatch() {
    return _channel.invokeMethod<void>('startLocationWatch');
  }

  Future<void> stopLocationWatch() {
    return _channel.invokeMethod<void>('stopLocationWatch');
  }

  Future<bool> isLocationWatchRunning() async {
    final result = await _channel.invokeMethod<bool>('isLocationWatchRunning');
    return result ?? false;
  }

  Future<Map<Object?, Object?>> getDeviceInfo() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('getDeviceInfo');
    return result ?? const {};
  }

  /// Opens the vendor's autostart screen. Returns false when this device has
  /// no such screen, so the caller can fall back to standard app settings.
  Future<bool> openAutoStartSettings() async {
    final result = await _channel.invokeMethod<bool>('openAutoStartSettings');
    return result ?? false;
  }

  Future<bool> openAppSettings() async {
    final result = await _channel.invokeMethod<bool>('openAppSettings');
    return result ?? false;
  }

  /// Fires the real alarm after [delaySeconds] so the user can lock their
  /// screen and verify it breaks through from an idle, locked state.
  Future<void> triggerTestAlarm({int delaySeconds = 10}) {
    return _channel.invokeMethod<void>('triggerTestAlarm', {
      'delaySeconds': delaySeconds,
    });
  }

  Future<bool> isAlarmRinging() async {
    final result = await _channel.invokeMethod<bool>('isAlarmRinging');
    return result ?? false;
  }

  Future<void> stopAlarm() {
    return _channel.invokeMethod<void>('stopAlarm');
  }
}
