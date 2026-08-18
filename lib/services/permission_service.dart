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

  Future<PermissionStatusSummary> currentStatus() async {
    final serviceEnabled = await _nativeBridge.isLocationEnabled();
    final foreground = await ph.Permission.locationWhenInUse.status;
    final background = await ph.Permission.locationAlways.status;
    final notifications = await ph.Permission.notification.status;
    final fullScreenIntent = await _nativeBridge.canUseFullScreenIntent();
    final batteryOptimization = await _nativeBridge.isIgnoringBatteryOptimizations();

    return PermissionStatusSummary(
      locationServiceEnabled: serviceEnabled,
      foregroundLocationGranted: foreground.isGranted,
      backgroundLocationGranted: background.isGranted,
      notificationsGranted: notifications.isGranted || notifications.isLimited,
      fullScreenIntentAllowed: fullScreenIntent,
      batteryOptimizationDisabled: batteryOptimization,
    );
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
