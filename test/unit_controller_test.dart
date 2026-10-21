import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/services/oem_service.dart';
import 'package:locreminder/services/radius_advice.dart';
import 'package:locreminder/services/unit_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('formatDistanceWithUnit', () {
    test('formats metric distances in m and km', () {
      expect(formatDistanceWithUnit(250, DistanceUnit.km), '250 m');
      expect(formatDistanceWithUnit(1500, DistanceUnit.km), '1.5 km');
      expect(formatDistanceWithUnit(14200, DistanceUnit.km), '14 km');
    });

    test('formats imperial distances in ft and mi', () {
      expect(formatDistanceWithUnit(100, DistanceUnit.miles), '330 ft');
      expect(formatDistanceWithUnit(1609.344, DistanceUnit.miles), '1.0 mi');
      expect(formatDistanceWithUnit(3218.688, DistanceUnit.miles), '2.0 mi');
      expect(formatDistanceWithUnit(19312.128, DistanceUnit.miles), '12 mi');
    });
  });

  group('formatRadiusWithUnit', () {
    test('gives distinct labels across slider steps in Miles mode', () {
      expect(formatRadiusWithUnit(100, DistanceUnit.miles), '330 ft');
      expect(formatRadiusWithUnit(200, DistanceUnit.miles), '660 ft');
      expect(formatRadiusWithUnit(300, DistanceUnit.miles), '980 ft');
      expect(formatRadiusWithUnit(400, DistanceUnit.miles), '0.25 mi');
      expect(formatRadiusWithUnit(500, DistanceUnit.miles), '0.31 mi');
      expect(formatRadiusWithUnit(1600, DistanceUnit.miles), '0.99 mi');
      expect(formatRadiusWithUnit(3000, DistanceUnit.miles), '1.86 mi');
    });
  });

  group('UnitController', () {
    test('persists KM and Miles selection in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = UnitController();
      await controller.load();
      expect(controller.value, DistanceUnit.km);

      await controller.setUnit(DistanceUnit.miles);
      expect(controller.value, DistanceUnit.miles);

      final restored = UnitController();
      await restored.load();
      expect(restored.value, DistanceUnit.miles);
    });
  });

  test('milesPerHour converts metres per second to mph', () {
    expect(milesPerHour(10), 22);
    expect(milesPerHour(26.8224), 60);
  });

  test('OemService.allPhoneGuides includes full-screen steps for every brand', () {
    final guides = OemService.allPhoneGuides;
    expect(guides, isNotEmpty);
    for (final guide in guides) {
      expect(guide.name, isNotEmpty);
      expect(guide.fullScreenSteps, isNotEmpty);
    }
  });
}
