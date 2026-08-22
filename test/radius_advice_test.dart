import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/services/radius_advice.dart';

void main() {
  group('minimumRadiusForSpeed', () {
    test('says nothing when the speed is unknown', () {
      expect(minimumRadiusForSpeed(null), isNull);
    });

    test('says nothing when standing still or walking', () {
      // Under 25 km/h the watcher is already polling every 10 seconds by the
      // time it matters, and the existing 100m floor covers that.
      expect(minimumRadiusForSpeed(0), isNull);
      expect(minimumRadiusForSpeed(1.4), isNull); // walking, 5 km/h
      expect(minimumRadiusForSpeed(6), isNull); // cycling, 21 km/h
    });

    test('widens through the speed bands', () {
      expect(minimumRadiusForSpeed(10), 300); // city bus, 36 km/h
      expect(minimumRadiusForSpeed(20), 500); // highway coach, 72 km/h
      expect(minimumRadiusForSpeed(30), 1000); // intercity, 108 km/h
    });

    test('holds at each boundary rather than jumping early', () {
      expect(minimumRadiusForSpeed(7), isNull);
      expect(minimumRadiusForSpeed(7.1), 300);
      expect(minimumRadiusForSpeed(14), 300);
      expect(minimumRadiusForSpeed(14.1), 500);
      expect(minimumRadiusForSpeed(25), 500);
      expect(minimumRadiusForSpeed(25.1), 1000);
    });

    test('ignores readings no journey could produce', () {
      // Some providers report a negative speed to mean "unknown", and a bad
      // fix can invent a few hundred metres per second.
      expect(minimumRadiusForSpeed(-1), isNull);
      expect(minimumRadiusForSpeed(200), isNull);
    });

    test('never asks for more than the slider offers', () {
      for (var speed = 0.0; speed <= 110; speed += 0.5) {
        final radius = minimumRadiusForSpeed(speed);
        if (radius != null) {
          expect(radius, greaterThanOrEqualTo(100));
          expect(radius, lessThanOrEqualTo(3000));
        }
      }
    });
  });

  test('kilometresPerHour converts for display', () {
    expect(kilometresPerHour(10), 36);
    expect(kilometresPerHour(27.8), 100);
  });
}
