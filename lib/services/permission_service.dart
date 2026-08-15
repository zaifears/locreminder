import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionStatusSummary {
  const PermissionStatusSummary({
    required this.locationServiceEnabled,
    required this.foregroundLocationGranted,
    required this.backgroundLocationGranted,
    required this.notificationsGranted,
  });

  final bool locationServiceEnabled;
  final bool foregroundLocationGranted;
  final bool backgroundLocationGranted;
  final bool notificationsGranted;

  bool get isFullyReady =>
      locationServiceEnabled &&
      foregroundLocationGranted &&
      backgroundLocationGranted &&
      notificationsGranted;
}

/// Wraps permission_handler + geolocator's own service-enabled check into
/// the sequence Android actually requires: foreground location must be
/// granted before background ("Allow all the time") can be requested, and
/// notification permission is a separate runtime prompt on Android 13+.
class PermissionService {
  Future<PermissionStatusSummary> currentStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final foreground = await ph.Permission.locationWhenInUse.status;
    final background = await ph.Permission.locationAlways.status;
    final notifications = await ph.Permission.notification.status;

    return PermissionStatusSummary(
      locationServiceEnabled: serviceEnabled,
      foregroundLocationGranted: foreground.isGranted,
      backgroundLocationGranted: background.isGranted,
      notificationsGranted: notifications.isGranted || notifications.isLimited,
    );
  }

  Future<bool> requestForegroundLocation() async {
    final status = await ph.Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> requestBackgroundLocation() async {
    final status = await ph.Permission.locationAlways.request();
    return status.isGranted;
  }

  Future<bool> requestNotifications() async {
    final status = await ph.Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> openSystemAppSettings() => ph.openAppSettings();
}
