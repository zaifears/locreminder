import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'native_bridge.dart';

class PermissionStatusSummary {
  const PermissionStatusSummary({
    required this.locationServiceEnabled,
    required this.foregroundLocationGranted,
    required this.backgroundLocationGranted,
    required this.notificationsGranted,
    required this.fullScreenIntentAllowed,
    required this.batteryOptimizationDisabled,
  });

  final bool locationServiceEnabled;
  final bool foregroundLocationGranted;
  final bool backgroundLocationGranted;
  final bool notificationsGranted;
  final bool fullScreenIntentAllowed;
  final bool batteryOptimizationDisabled;

  /// Everything the alarm needs in order to fire on time in the background.
  ///
  /// Battery optimization is included deliberately. With it left on, Android
  /// puts the app in App Standby and defers location work until the app is
  /// next opened — which in testing meant the alarm stayed silent during the
  /// whole journey and then rang the moment the app was launched. That makes
  /// it a functional requirement, not a nice-to-have.
  bool get isFullyReady =>
      locationServiceEnabled &&
      foregroundLocationGranted &&
      backgroundLocationGranted &&
      notificationsGranted &&
      batteryOptimizationDisabled;
}

/// Wraps permission_handler and the native location checks into the sequence
/// Android actually requires: foreground location must be granted before
/// background ("Allow all the time") can be requested, notifications are a
/// separate runtime prompt on Android 13+, and full-screen intents are gated
/// again on 14+.
///
/// Location-service checks go through the native bridge rather than the
/// geolocator plugin, which depends on Google Play Services and would have
/// made the app ineligible for F-Droid and unusable on de-Googled devices.
class PermissionService {
  PermissionService({NativeBridge? nativeBridge})
      : _nativeBridge = nativeBridge ?? NativeBridge();

  final NativeBridge _nativeBridge;

  /// Reads every permission the app depends on, degrading one answer rather
  /// than the whole call when the platform will not say.
  ///
  /// Six calls across two plugins and a method channel, and this runs on the
  /// startup path: an exception from any one of them used to propagate out of
  /// here, leaving whichever screen asked stuck on its loading spinner with
  /// no route forward — including the launch gate, which decides between
  /// onboarding and the map. Treating an unanswerable check as "not granted"
  /// is both the safe reading and a recoverable one: every caller re-checks
  /// when the app is resumed.
  Future<PermissionStatusSummary> currentStatus() async {
    final serviceEnabled = await _ask(_nativeBridge.isLocationEnabled, false);
    final foreground = await _ask(
      () => ph.Permission.locationWhenInUse.status,
      ph.PermissionStatus.denied,
    );
    final background = await _ask(
      () => ph.Permission.locationAlways.status,
      ph.PermissionStatus.denied,
    );
    final notifications = await _ask(
      () => ph.Permission.notification.status,
      ph.PermissionStatus.denied,
    );
    final fullScreenIntent =
        await _ask(_nativeBridge.canUseFullScreenIntent, true);
    final batteryOptimization =
        await _ask(_nativeBridge.isIgnoringBatteryOptimizations, false);

    return PermissionStatusSummary(
      locationServiceEnabled: serviceEnabled,
      foregroundLocationGranted: foreground.isGranted,
      backgroundLocationGranted: background.isGranted,
      notificationsGranted: notifications.isGranted || notifications.isLimited,
      fullScreenIntentAllowed: fullScreenIntent,
      batteryOptimizationDisabled: batteryOptimization,
    );
  }

  /// Runs one platform check, falling back if it cannot be answered.
  static Future<T> _ask<T>(Future<T> Function() check, T fallback) async {
    try {
      return await check();
    } on PlatformException {
      return fallback;
    } on MissingPluginException {
      return fallback;
    }
  }

  Future<bool> requestForegroundLocation() async {
    if (!await _nativeBridge.isLocationEnabled()) {
      await _nativeBridge.openLocationSettings();
      return false;
    }
    final status = await ph.Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) {
      await ph.openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<bool> requestBackgroundLocation() async {
    final status = await ph.Permission.locationAlways.request();
    // Android never shows a second dialog for "Allow all the time" once the
    // user has dismissed it; the only remaining route is app settings.
    if (!status.isGranted) {
      await ph.openAppSettings();
    }
    return status.isGranted;
  }

  Future<bool> requestNotifications() async {
    final status = await ph.Permission.notification.request();
    if (status.isPermanentlyDenied) {
      await ph.openAppSettings();
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  Future<void> requestFullScreenIntent() =>
      _nativeBridge.requestFullScreenIntentPermission();

  Future<void> requestDisableBatteryOptimization() =>
      _nativeBridge.requestIgnoreBatteryOptimizations();

  Future<void> openSystemAppSettings() => ph.openAppSettings();
}
