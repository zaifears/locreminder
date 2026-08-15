import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/models/location_alarm.dart';

void main() {
  test('LocationAlarm round-trips through JSON', () {
    final alarm = LocationAlarm(
      id: 'abc123',
      label: 'Bus stop',
      latitude: 23.8103,
      longitude: 90.4125,
      radiusMeters: 500,
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1, 8, 30),
    );

    final restored = LocationAlarm.fromJson(alarm.toJson());

    expect(restored.id, alarm.id);
    expect(restored.label, alarm.label);
    expect(restored.latitude, alarm.latitude);
    expect(restored.longitude, alarm.longitude);
    expect(restored.radiusMeters, alarm.radiusMeters);
    expect(restored.isActive, alarm.isActive);
    expect(restored.createdAt, alarm.createdAt);
  });

  test('copyWith only changes the requested fields', () {
    final alarm = LocationAlarm(
      id: 'abc123',
      label: 'Bus stop',
      latitude: 23.8103,
      longitude: 90.4125,
      radiusMeters: 500,
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final toggled = alarm.copyWith(isActive: false);

    expect(toggled.isActive, isFalse);
    expect(toggled.label, alarm.label);
    expect(toggled.latitude, alarm.latitude);
    expect(toggled.radiusMeters, alarm.radiusMeters);
  });
}
