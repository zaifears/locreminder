import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place_result.dart';
import 'app_version.dart';

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

/// Place search and reverse geocoding, over two free OpenStreetMap services.
///
/// **Photon** answers the typing.** It is built for search-as-you-type:
/// prefix matching, tolerance for a misspelling, and ranking that can be
/// biased towards where the user is looking. Nominatim is not built for that
/// and says so in its own documentation — it wants a complete, correctly
/// spelled query, which is not what a half-typed bus stand is. Most of "lots
/// of places don't show up" was that mismatch.
///
/// **Nominatim answers everything else**, and Photon's failures. It still
/// does reverse geocoding, still runs when Photon cannot be reached, and
/// still runs when Photon finds nothing — the two indexes differ, and a
/// second look costs one request in exactly the case the user is already
/// unhappy about.
///
/// Both are free, keyless, and run on donated infrastructure, which is worth
/// treating as the privilege it is: an identifying User-Agent on every
/// request, typing debounced before either is asked anything, and a minimum
/// spacing enforced here as a backstop. Nominatim's policy names one request
/// per second; Photon expects autocomplete traffic and is given a lighter
/// floor.
class GeocodingService {
  static const _nominatimHost = 'nominatim.openstreetmap.org';
  static const _photonHost = 'photon.komoot.io';

  static const _nominatimMinInterval = Duration(seconds: 1);
  static const _photonMinInterval = Duration(milliseconds: 300);

  static const _resultLimit = 15;
  static const _timeout = Duration(seconds: 10);

  DateTime? _lastNominatimRequest;
  DateTime? _lastPhotonRequest;

  /// Nominatim's policy asks that this identify the app accurately, so the
  /// version comes from the package rather than a literal — the previous one
  /// silently said 1.0 while the app shipped 1.6.x.
  Future<Map<String, String>> _headers() async => {
        'User-Agent':
            'LocReminder/${await AppVersion.plain()} (https://github.com/zaifears/locreminder)',
      };

  Future<void> _throttleNominatim() async {
    _lastNominatimRequest =
        await _spaceOut(_lastNominatimRequest, _nominatimMinInterval);
  }

  Future<void> _throttlePhoton() async {
    _lastPhotonRequest = await _spaceOut(_lastPhotonRequest, _photonMinInterval);
  }

  /// Waits until [minInterval] has passed since [last], and reports the time
  /// the caller may consider its request to have started.
  Future<DateTime> _spaceOut(DateTime? last, Duration minInterval) async {
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < minInterval) {
        await Future<void>.delayed(minInterval - elapsed);
      }
    }
    return DateTime.now();
  }

  /// Searches for places matching [query]. Never throws — the outcome
  /// distinguishes "nothing matched" from "couldn't reach the service", so
  /// the UI can tell the user which of the two actually happened.
  ///
  /// [near] biases the ranking towards somewhere, normally whatever the map
  /// is currently showing. Without it both services rank the whole world by
  /// general importance, which is how a search for a local bus stand loses
  /// to a similarly named place on another continent.
  Future<SearchOutcome> search(String query, {LatLng? near}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const SearchOutcome.success([]);

    final photon = await _searchPhoton(trimmed, near);
    if (photon != null && photon.isNotEmpty) {
      return SearchOutcome.success(photon);
    }

    // Photon either could not be reached or knows nothing about this. Either
    // way Nominatim is worth asking: a second index, and the one that has to
    // answer anyway when Photon is down.
    final nominatim = await _searchNominatim(trimmed, near);

    // Photon answering "nothing" is still an answer. Only report a failure
    // when neither service could be reached at all, or the user is told
    // their connection is broken when in truth their search simply matched
    // nothing.
    if (!nominatim.reachedService && photon != null) {
      return const SearchOutcome.success([]);
    }
    return nominatim;
  }

  /// Returns null when Photon could not be reached, an empty list when it
  /// was reached and matched nothing.
  Future<List<PlaceResult>?> _searchPhoton(String query, LatLng? near) async {
    await _throttlePhoton();

    final uri = Uri.https(_photonHost, '/api/', {
      'q': query,
      'limit': '$_resultLimit',
      // Ranking bias, not a filter: somewhere far away still appears, just
      // below the things near enough to be what was meant.
      if (near != null) 'lat': '${near.latitude}',
      if (near != null) 'lon': '${near.longitude}',
    });

    try {
      final response =
          await http.get(uri, headers: await _headers()).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final features = decoded['features'];
      if (features is! List) return null;

      return features
          .whereType<Map<String, dynamic>>()
          .map(PlaceResult.fromPhotonFeature)
          .whereType<PlaceResult>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<SearchOutcome> _searchNominatim(String query, LatLng? near) async {
    await _throttleNominatim();

    final uri = Uri.https(_nominatimHost, '/search', {
      'q': query,
      'format': 'json',
      'limit': '$_resultLimit',
      'addressdetails': '0',
      // Same bias, expressed the way Nominatim wants it. Unbounded, so the
      // box orders results rather than restricting them to it.
      if (near != null) ...{
        'viewbox': _viewboxAround(near),
        'bounded': '0',
      },
    });

    try {
      final response =
          await http.get(uri, headers: await _headers()).timeout(_timeout);
      if (response.statusCode != 200) return const SearchOutcome.failure();
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return SearchOutcome.success(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(PlaceResult.fromNominatimJson)
            .toList(),
      );
    } catch (_) {
      return const SearchOutcome.failure();
    }
  }

  /// A box roughly [_viewboxDegrees] across, centred on [near], in the
  /// left,top,right,bottom order Nominatim expects.
  static String _viewboxAround(LatLng near) {
    const span = _viewboxDegrees;
    final left = (near.longitude - span).clamp(-180.0, 180.0);
    final right = (near.longitude + span).clamp(-180.0, 180.0);
    final top = (near.latitude + span).clamp(-90.0, 90.0);
    final bottom = (near.latitude - span).clamp(-90.0, 90.0);
    return '$left,$top,$right,$bottom';
  }

  /// Half-width of that box. Half a degree is roughly 55 km, which covers a
  /// city and its surroundings without being so wide that it stops meaning
  /// anything.
  static const _viewboxDegrees = 0.5;

  Future<String?> reverse(double latitude, double longitude) async {
    await _throttleNominatim();

    final uri = Uri.https(_nominatimHost, '/reverse', {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'json',
      'zoom': '18',
    });

    try {
      final response =
          await http.get(uri, headers: await _headers()).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
