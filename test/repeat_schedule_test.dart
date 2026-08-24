import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/models/location_alarm.dart';

LocationAlarm _alarm({Set<int> repeatDays = RepeatSchedule.once}) => LocationAlarm(
      id: 'abc123',
      label: 'Buy medicine',
      latitude: 23.8103,
      longitude: 90.4125,
      radiusMeters: 500,
      isActive: true,
      createdAt: DateTime.utc(2026, 1, 1, 8, 30),
      repeatDays: repeatDays,
    );

void main() {
  group('RepeatSchedule.describe', () {
    test('names the presets the picker offers', () {
      expect(RepeatSchedule.describe(RepeatSchedule.once), 'Once');
      expect(RepeatSchedule.describe(RepeatSchedule.daily), 'Every day');
      expect(RepeatSchedule.describe(RepeatSchedule.weekdays), 'Weekdays');
      expect(RepeatSchedule.describe(RepeatSchedule.weekends), 'Weekends');
    });

    test('a single day reads as a weekly repeat', () {
      expect(RepeatSchedule.describe({2}), 'Every Tuesday');
      expect(RepeatSchedule.describe({7}), 'Every Sunday');
    });

    test('an arbitrary set lists its days in week order', () {
      // Deliberately out of order going in: the set has no order of its own,
      // so the label has to impose one or it changes between rebuilds.
      expect(RepeatSchedule.describe({5, 1, 3}), 'Mon, Wed, Fri');
    });
  });

  group('sanitize', () {
    test('drops days outside 1..7', () {
      expect(RepeatSchedule.sanitize([0, 1, 5, 8, -3, 7]), {1, 5, 7});
    });

    test('an empty or entirely invalid list becomes once', () {
      expect(RepeatSchedule.sanitize([]), RepeatSchedule.once);
      expect(RepeatSchedule.sanitize([0, 99]), RepeatSchedule.once);
    });
  });

  group('LocationAlarm JSON', () {
    test('round-trips a repeating alarm', () {
      final restored = LocationAlarm.fromJson(
        _alarm(repeatDays: {1, 3, 5}).toJson(),
      );
      expect(restored.repeatDays, {1, 3, 5});
      expect(restored.repeats, isTrue);
      expect(restored.label, 'Buy medicine');
    });

    test('serialises the days in a stable order', () {
      final json = _alarm(repeatDays: {5, 1, 3}).toJson();
      expect(json['repeatDays'], [1, 3, 5]);
    });

    test('an alarm saved before repeats existed loads as one-shot', () {
      // Exactly what is on disk for every user upgrading from 1.8.0 and
      // earlier: no repeatDays key at all.
      final legacy = {
        'id': 'legacy',
        'label': 'Bus stop',
        'latitude': 23.8103,
        'longitude': 90.4125,
        'radiusMeters': 500.0,
        'isActive': true,
        'createdAt': '2026-01-01T08:30:00.000Z',
      };

      final restored = LocationAlarm.fromJson(legacy);

      expect(restored.repeatDays, RepeatSchedule.once);
      expect(restored.repeats, isFalse);
      expect(restored.scheduleLabel, 'Once');
    });

    test('a corrupt repeatDays value cannot reach the native side', () {
      final json = _alarm().toJson()..['repeatDays'] = [0, 3, 9];
      expect(LocationAlarm.fromJson(json).repeatDays, {3});
    });
  });

  group('copyWith', () {
    test('changes the schedule without touching anything else', () {
      final updated = _alarm().copyWith(repeatDays: RepeatSchedule.daily);
      expect(updated.repeatDays, RepeatSchedule.daily);
      expect(updated.label, 'Buy medicine');
      expect(updated.radiusMeters, 500);
      expect(updated.isActive, isTrue);
    });

    test('leaves the schedule alone when not asked to change it', () {
      final updated = _alarm(repeatDays: {6}).copyWith(isActive: false);
      expect(updated.repeatDays, {6});
      expect(updated.isActive, isFalse);
    });
  });
}
