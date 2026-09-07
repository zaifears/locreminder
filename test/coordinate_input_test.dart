import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/services/coordinate_input.dart';

/// The search box decides, on every keystroke, whether to send what you typed
/// to a server or to read it as a place on the map. Getting that wrong in one
/// direction wastes a request; getting it wrong in the other silently drops a
/// pin somewhere you never asked for. Both directions are tested here.
void main() {
  group('reads a coordinate', () {
    void expectPoint(String input, double latitude, double longitude) {
      final parsed = parseCoordinates(input);
      expect(parsed, isNotNull, reason: 'should have parsed "$input"');
      expect(parsed!.latitude, closeTo(latitude, 1e-9), reason: input);
      expect(parsed.longitude, closeTo(longitude, 1e-9), reason: input);
    }

    test('written the way a map app copies it', () {
      expectPoint('23.8103, 90.4125', 23.8103, 90.4125);
      expectPoint('23.810332,90.412518', 23.810332, 90.412518);
      expectPoint('  23.8103 ,  90.4125  ', 23.8103, 90.4125);
    });

    test('separated by a space instead of a comma', () {
      expectPoint('23.8103 90.4125', 23.8103, 90.4125);
    });

    test('with signs', () {
      expectPoint('-33.8688, 151.2093', -33.8688, 151.2093);
      expectPoint('+23.8103, -90.4125', 23.8103, -90.4125);
    });

    test('with degree symbols and hemisphere marks', () {
      expectPoint('23.8103° N, 90.4125° E', 23.8103, 90.4125);
      expectPoint('23.8103N 90.4125E', 23.8103, 90.4125);
      expectPoint('N 23.8103, E 90.4125', 23.8103, 90.4125);
      expectPoint('33.8688 S, 151.2093 W', -33.8688, -151.2093);
    });

    test('written longitude first, when the marks say so', () {
      expectPoint('90.4125 E, 23.8103 N', 23.8103, 90.4125);
    });

    test('as the geo: URI Android shares', () {
      expectPoint('geo:23.8103,90.4125', 23.8103, 90.4125);
      expectPoint('geo:23.8103,90.4125;u=35', 23.8103, 90.4125);
    });

    test('at the edges of the world', () {
      expectPoint('0, 0', 0, 0);
      expectPoint('90, 180', 90, 180);
      expectPoint('-90, -180', -90, -180);
    });
  });

  group('leaves everything else to the search', () {
    void expectNotCoordinates(String input) {
      expect(parseCoordinates(input), isNull, reason: 'parsed "$input"');
    }

    test('a place name that happens to contain numbers and a comma', () {
      // The whole reason this parser is strict. Dhaka addresses look like
      // this, and reading one as a coordinate would drop the pin in the
      // Atlantic without saying so.
      expectNotCoordinates('Sector 10, Road 5');
      expectNotCoordinates('House 12, Dhanmondi 27');
      expectNotCoordinates('Platform 9, Kamalapur');
    });

    test('ordinary searches', () {
      expectNotCoordinates('Kamalapur Railway Station');
      expectNotCoordinates('airport');
      expectNotCoordinates('');
      expectNotCoordinates('   ');
    });

    test('a single number, which is half an answer', () {
      expectNotCoordinates('23.8103');
      expectNotCoordinates('23.8103,');
      expectNotCoordinates(',90.4125');
    });

    test('numbers outside the world', () {
      expectNotCoordinates('91, 90.4125');
      expectNotCoordinates('23.8103, 181');
      expectNotCoordinates('-91, 0');
    });

    test('a sign and a hemisphere mark that contradict each other', () {
      expectNotCoordinates('-23.8103 N, 90.4125 E');
      expectNotCoordinates('23.8103 N, -90.4125 W');
    });

    test('marks that name the same axis twice', () {
      expectNotCoordinates('23.8103 N, 90.4125 S');
      expectNotCoordinates('23.8103 E, 90.4125 W');
    });

    test('things that are not numbers at all', () {
      expectNotCoordinates('N, E');
      expectNotCoordinates('NaN, 90.4125');
      expectNotCoordinates('Infinity, 0');
      expectNotCoordinates('two, three');
    });
  });

  test('formatCoordinates round-trips back through the parser', () {
    final text = formatCoordinates(23.8103, 90.4125);
    expect(text, '23.81030, 90.41250');

    final reparsed = parseCoordinates(text);
    expect(reparsed, isNotNull);
    expect(reparsed!.latitude, closeTo(23.8103, 1e-5));
    expect(reparsed.longitude, closeTo(90.4125, 1e-5));
  });
}
