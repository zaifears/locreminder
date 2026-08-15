import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_result.dart';

/// Result of a place search: either matches (possibly none) or an outright
/// failure to reach the service, which the UI must word differently.
class SearchOutcome {
  const SearchOutcome.success(this.results) : reachedService = true;
  const SearchOutcome.failure()
      : results = const [],
        reachedService = false;

  final List<PlaceResult> results;
  final bool reachedService;
}

/// Place search and reverse geocoding via OpenStreetMap's Nominatim.
///
/// Free and keyless, but the usage policy requires an identifying
/// User-Agent and no more than one request per second — callers debounce
/// typing, and [_throttle] enforces the floor as a backstop.
class GeocodingService {
  static const _host = 'nominatim.openstreetmap.org';
  static const _userAgent = 'LocReminder/1.0 (https://github.com/zaifears/locreminder)';
  static const _minInterval = Duration(seconds: 1);

  DateTime? _lastRequest;

  Future<void> _throttle() async {
    final last = _lastRequest;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < _minInterval) {
        await Future<void>.delayed(_minInterval - elapsed);
      }
    }
    _lastRequest = DateTime.now();
  }

  /// Searches for places matching [query]. Never throws — the outcome
  /// distinguishes "nothing matched" from "couldn't reach the service", so
  /// the UI can tell the user which of the two actually happened.
  Future<SearchOutcome> search(String query) async {
    if (query.trim().isEmpty) return const SearchOutcome.success([]);
    await _throttle();

    final uri = Uri.https(_host, '/search', {
      'q': query,
      'format': 'json',
      'limit': '8',
      'addressdetails': '0',
    });

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const SearchOutcome.failure();
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return SearchOutcome.success(
        decoded
            .map((e) => PlaceResult.fromNominatimJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return const SearchOutcome.failure();
    }
  }

  /// Human-readable address for a coordinate, or null if it can't be resolved.
  Future<String?> reverse(double latitude, double longitude) async {
    await _throttle();

    final uri = Uri.https(_host, '/reverse', {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'json',
      'zoom': '18',
    });

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
