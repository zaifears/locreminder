import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native_bridge.dart';

/// Whether distances, radii, and travel speeds are shown in metric (km / m)
/// or imperial (miles / ft).
enum DistanceUnit {
  km,
  miles;

  String get shortLabel => switch (this) {
        DistanceUnit.km => 'KM',
        DistanceUnit.miles => 'Miles',
      };
}

/// Holds the user's distance unit preference (Kilometres vs Miles), persists
/// it in [SharedPreferences], and syncs it to the native watch service so the
/// ongoing notification uses the same unit.
class UnitController extends ValueNotifier<DistanceUnit> {
  UnitController({NativeBridge? nativeBridge})
      : _nativeBridge = nativeBridge ?? NativeBridge(),
        super(DistanceUnit.km);

  static const _prefsKey = 'distance_unit';
  final NativeBridge _nativeBridge;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    value = switch (stored) {
      'miles' => DistanceUnit.miles,
      _ => DistanceUnit.km,
    };
    try {
      await _nativeBridge.setDistanceUnit(miles: value == DistanceUnit.miles);
    } catch (_) {
      // Non-Android or test environment without native channel.
    }
  }

  Future<void> setUnit(DistanceUnit unit) async {
    if (value == unit) return;
    value = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, unit.name);
    try {
      await _nativeBridge.setDistanceUnit(miles: unit == DistanceUnit.miles);
    } catch (_) {
      // Non-Android or test environment without native channel.
    }
  }
}

const double metresPerMile = 1609.344;
const double feetPerMetre = 3.280839895;

/// Formats a metre distance in the chosen [unit] (km/m or mi/ft).
String formatDistanceWithUnit(
  double metres, [
  DistanceUnit unit = DistanceUnit.km,
]) {
  if (unit == DistanceUnit.miles) {
    final miles = metres / metresPerMile;
    if (miles < 0.1) {
      final feet = ((metres * feetPerMetre) / 10).round() * 10;
      return '${feet < 10 ? (metres * feetPerMetre).round() : feet} ft';
    }
    if (miles < 10) return '${miles.toStringAsFixed(1)} mi';
    return '${miles.round()} mi';
  }

  if (metres < 1000) return '${metres.round()} m';
  if (metres < 10000) return '${(metres / 1000).toStringAsFixed(1)} km';
  return '${(metres / 1000).round()} km';
}

/// Formats an alarm trigger radius (100m to 3000m) with enough precision that
/// every step on the radius slider shows a distinct value in both KM and Miles.
String formatRadiusWithUnit(
  double metres, [
  DistanceUnit unit = DistanceUnit.km,
]) {
  if (unit == DistanceUnit.miles) {
    final miles = metres / metresPerMile;
    if (metres < 400) {
      final feet = ((metres * feetPerMetre) / 10).round() * 10;
      return '$feet ft';
    }
    // Show up to 2 decimal places (e.g. 0.25 mi, 0.5 mi, 1.0 mi, 1.86 mi) so
    // consecutive 100m slider steps never display the exact same label.
    final twoDec = miles.toStringAsFixed(2);
    final trimmed =
        twoDec.endsWith('0') ? miles.toStringAsFixed(1) : twoDec;
    return '$trimmed mi';
  }

  if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
  return '${metres.round()} m';
}
