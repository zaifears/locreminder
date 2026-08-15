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

  Future<bool> isAlarmRinging() async {
    final result = await _channel.invokeMethod<bool>('isAlarmRinging');
    return result ?? false;
  }

  Future<void> stopAlarm() {
    return _channel.invokeMethod<void>('stopAlarm');
  }
}
