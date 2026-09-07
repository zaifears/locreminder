import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/services/offline_maps.dart';

/// The tile arithmetic behind saving a map area for offline use.
///
/// Worth its own test because it is the one part of offline maps that can be
/// wrong silently: a URL off by one tile still downloads, still caches, and
/// still draws — just not where the user is standing.
void main() {
  const template = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  test('centres on the tile containing the point', () {
    // Dhaka, at a radius small enough to land inside one tile at zoom 13.
    final urls = OfflineMaps.tileUrlsAround(
      latitude: 23.8103,
      longitude: 90.4125,
      radiusMetres: 10,
      zoom: 13,
      urlTemplate: template,
    );

    // Hand-computed from the standard slippy-map formulas.
    expect(urls, ['https://tile.openstreetmap.org/13/6153/3537.png']);
  });

  test('covers a square of tiles as the radius grows', () {
    final urls = OfflineMaps.tileUrlsAround(
      latitude: 23.8103,
      longitude: 90.4125,
      radiusMetres: 1200,
      zoom: 15,
      urlTemplate: template,
    );

    expect(urls.length, greaterThan(1));
    // A 2.4 km square at zoom 15, where tiles are roughly 1.2 km across, is a
    // handful of tiles — not a region download. The tile server's usage
    // policy is explicit about the difference.
    expect(urls.length, lessThan(20));
    expect(urls.toSet().length, urls.length, reason: 'no tile fetched twice');
  });

  test('stays inside the tile grid at the poles', () {
    final urls = OfflineMaps.tileUrlsAround(
      latitude: 89.9,
      longitude: 179.9,
      radiusMetres: 5000,
      zoom: 4,
      urlTemplate: template,
    );

    for (final url in urls) {
      final parts = url.split('/');
      final x = int.parse(parts[parts.length - 2]);
      final y = int.parse(parts.last.split('.').first);
      expect(x, inInclusiveRange(0, 15));
      expect(y, inInclusiveRange(0, 15));
    }
  });

  test('fills in every placeholder a template can carry', () {
    final urls = OfflineMaps.tileUrlsAround(
      latitude: 10,
      longitude: 10,
      radiusMetres: 1,
      zoom: 2,
      urlTemplate: 'https://{s}.example.org/{z}/{x}/{y}.png',
    );

    expect(urls.single, 'https://a.example.org/2/2/1.png');
  });
}
