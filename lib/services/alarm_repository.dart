import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_alarm.dart';

/// Persists the user's saved alarms on the Dart side (for the UI list).
/// The native side keeps its own independent copy (see GeofenceStore.kt) so
/// it can react to geofence triggers without needing the Flutter engine.
class AlarmRepository {
  static const _prefsKey = 'location_alarms';

  Future<List<LocationAlarm>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    return raw
        .map((s) => LocationAlarm.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<LocationAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      alarms.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
