import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_alarm.dart';

/// Persists the user's saved alarms on the Dart side (for the UI list).
/// The native side keeps its own independent copy (see AlarmStore.kt) so
/// it can ring on arrival without needing the Flutter engine.
class AlarmRepository {
  static const _prefsKey = 'location_alarms';

  /// Reads the saved alarms, skipping any record that will not parse.
  ///
  /// One bad entry used to take the whole list with it: `loadAll` threw, the
  /// exception escaped the home screen's bootstrap, and the app sat on its
  /// loading spinner for good with no way back short of clearing its data.
  /// A record written by an older build, or truncated by a kill mid-write, is
  /// a reason to lose that alarm — not every alarm and the app with it.
  Future<List<LocationAlarm>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];

    final alarms = <LocationAlarm>[];
    for (final entry in raw) {
      try {
        alarms.add(
          LocationAlarm.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } catch (_) {
        continue;
      }
    }
    return alarms;
  }

  Future<void> saveAll(List<LocationAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      alarms.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
