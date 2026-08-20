import 'package:flutter/services.dart';

import '../models/location_alarm.dart';

/// Talks to the native Android alarm engine (MainActivity.kt,
/// LocationWatchService.kt, AlarmForegroundService.kt) over a MethodChannel.
///
/// Arrival detection and ringing happen entirely on the native side, so they
/// keep working even when this Flutter engine is not running. Everything here
/// uses the platform APIs only — no Google Play Services — so the app also
/// works on devices with no Google services at all.
class NativeBridge {
  static const _channel = MethodChannel('com.zaifears.locreminder/alarms');

  Future<void> addAlarm(LocationAlarm alarm) {
    return _channel.invokeMethod<void>('addAlarm', {
      'id': alarm.id,
      'latitude': alarm.latitude,
      'longitude': alarm.longitude,
      'radius': alarm.radiusMeters,
      'label': alarm.label,
    });
  }

  Future<void> removeAlarm(String id) {
    return _channel.invokeMethod<void>('removeAlarm', {'id': id});
  }

  Future<void> removeAllAlarms() {
    return _channel.invokeMethod<void>('removeAllAlarms');
  }

  Future<List<String>> getActiveAlarmIds() async {
    final result = await _channel.invokeMethod<List<Object?>>('getActiveAlarmIds');
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

  /// Starts the foreground service that actively watches location. Holding a
  /// foreground service is what makes detection dependable: it keeps the
  /// process out of the idle state where Doze defers background work.
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

  // -------------------------------------------------------------- alarm sound

  /// Returns `{uri, name, vibrate}`. A null `uri` means the system default.
  Future<Map<Object?, Object?>> getAlarmSound() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('getAlarmSound');
    return result ?? const {};
  }

  /// Opens the system ringtone picker. Returns `{uri, name}`, or null when
  /// the user cancelled or chose the default.
  Future<Map<Object?, Object?>?> pickAlarmRingtone() {
    return _channel.invokeMapMethod<Object?, Object?>('pickAlarmRingtone');
  }

  /// Opens the document picker for an audio file (mp3, m4a, ogg, wav, flac).
  Future<Map<Object?, Object?>?> pickAlarmAudioFile() {
    return _channel.invokeMapMethod<Object?, Object?>('pickAlarmAudioFile');
  }

  Future<void> resetAlarmSound() {
    return _channel.invokeMethod<void>('resetAlarmSound');
  }

  Future<void> setAlarmVibration(bool enabled) {
    return _channel.invokeMethod<void>('setAlarmVibration', {'enabled': enabled});
  }

  Future<void> previewAlarmSound() {
    return _channel.invokeMethod<void>('previewAlarmSound');
  }

  Future<void> stopAlarmSoundPreview() {
    return _channel.invokeMethod<void>('stopAlarmSoundPreview');
  }

  // ----------------------------------------------------------- location

  /// Whether any location provider is switched on at the OS level.
  Future<bool> isLocationEnabled() async {
    final result = await _channel.invokeMethod<bool>('isLocationEnabled');
    return result ?? false;
  }

  Future<void> openLocationSettings() {
    return _channel.invokeMethod<void>('openLocationSettings');
  }

  /// Latest fix the platform already holds. Returns instantly, but may be
  /// null, and what it returns can be hours old — good enough to pick an
  /// opening map position, not to answer "where am I now".
  ///
  /// Returns `{latitude, longitude, accuracy, time}`.
  Future<Map<Object?, Object?>?> getLastKnownLocation() {
    return _channel.invokeMapMethod<Object?, Object?>('getLastKnownLocation');
  }

  /// Asks the platform for a fresh fix, falling back to the cached one if
  /// none arrives within a few seconds. Takes noticeably longer than
  /// [getLastKnownLocation], so callers should show progress.
  Future<Map<Object?, Object?>?> getCurrentLocation() {
    return _channel.invokeMapMethod<Object?, Object?>('getCurrentLocation');
  }

  Future<bool> isAlarmRinging() async {
    final result = await _channel.invokeMethod<bool>('isAlarmRinging');
    return result ?? false;
  }

  Future<void> stopAlarm() {
    return _channel.invokeMethod<void>('stopAlarm');
  }
}
