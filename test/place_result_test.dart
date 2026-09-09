import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/models/place_result.dart';

/// Photon answers in GeoJSON, which orders a coordinate longitude first —
/// the opposite of every other pair in this app, and of Nominatim's own
/// answer. Getting it backwards puts Dhaka in the Indian Ocean and nothing
/// in the app would complain, so it is pinned here.
void main() {
  group('Photon features', () {
    Map<String, dynamic> feature(Map<String, dynamic> properties) => {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [90.4265, 23.7327],
          },
          'properties': properties,
        };

    test('reads longitude first, as GeoJSON writes it', () {
      final place = PlaceResult.fromPhotonFeature(
        feature({'name': 'Kamalapur Railway Station'}),
      );

      expect(place, isNotNull);
      expect(place!.latitude, closeTo(23.7327, 1e-9));
      expect(place.longitude, closeTo(90.4265, 1e-9));
    });

    test('builds a headline and its context from the pieces', () {
      final place = PlaceResult.fromPhotonFeature(
        feature({
          'name': 'Kamalapur Railway Station',
          'street': 'Kamalapur Road',
          'city': 'Dhaka',
          'state': 'Dhaka Division',
          'country': 'Bangladesh',
        }),
      )!;

      expect(place.shortName, 'Kamalapur Railway Station');
      expect(place.context, 'Kamalapur Road, Dhaka, Dhaka Division, Bangladesh');
    });

    test('falls back to the address when the place has no name', () {
      final place = PlaceResult.fromPhotonFeature(
        feature({'housenumber': '12', 'street': 'Dhanmondi 27', 'city': 'Dhaka'}),
      )!;

      expect(place.shortName, '12 Dhanmondi 27');
      // The street is the headline here, so it is not repeated behind it.
      expect(place.context, 'Dhaka');
    });

    test('never says the same thing twice', () {
      final place = PlaceResult.fromPhotonFeature(
        feature({'name': 'Dhaka', 'city': 'Dhaka', 'country': 'Bangladesh'}),
      )!;

      expect(place.displayName, 'Dhaka, Bangladesh');
    });

    test('falls back through the coarser fields when there is no street', () {
      final onlyCountry =
          PlaceResult.fromPhotonFeature(feature({'country': 'Bangladesh'}))!;
      expect(onlyCountry.shortName, 'Bangladesh');
    });

    test('rejects a feature with nothing to call it', () {
      expect(PlaceResult.fromPhotonFeature(feature({})), isNull);
    });

    test('rejects malformed geometry rather than guessing', () {
      expect(
        PlaceResult.fromPhotonFeature({
          'properties': {'name': 'Somewhere'},
        }),
        isNull,
      );
      expect(
        PlaceResult.fromPhotonFeature({
          'geometry': {'coordinates': <double>[]},
          'properties': {'name': 'Somewhere'},
        }),
        isNull,
      );
    });
  });

  test('Nominatim results still split on their own commas', () {
    final place = PlaceResult.fromNominatimJson({
      'display_name': 'Kamalapur Railway Station, Dhaka, Bangladesh',
      'lat': '23.7327',
      'lon': '90.4265',
    });

    expect(place.shortName, 'Kamalapur Railway Station');
    expect(place.context, 'Dhaka, Bangladesh');
    expect(place.latitude, closeTo(23.7327, 1e-9));
  });
}
