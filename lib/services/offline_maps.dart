import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_version.dart';
import 'native_bridge.dart';

const _prefetchKey = 'offline_maps_prefetch';

/// Keeps the map usable when there is no connection.
///
/// Worth being exact about what does and does not need the internet, because
/// the two get conflated and the conclusion — "this app needs data to work" —
/// is wrong in the way that matters:
///
///  * **Arrival detection needs nothing.** GNSS is a receive-only radio. The
///    satellites broadcast, the phone listens, and the alarm compares two
///    coordinates on the device. It rings in a tunnel-black signal hole, on a
///    phone with no SIM at all.
///  * **Map tiles are pictures on a server.** Nobody can send a picture of a
///    street the phone has never seen without a connection to send it over.
///    That is not an OpenStreetMap restriction — it is true of every map on
///    every platform, Google's included, which is why they all ship an
///    offline-areas feature.
///
/// So this is that feature. Tiles are kept on disk for [_freshFor] and served
/// from there without asking the network at all; when the network is
/// unreachable, even expired tiles are served rather than showing the user a
/// blank grid. And the area around each new alarm is fetched at the moment it
/// is set — normally while the user still has the signal they used to search
/// for the place — so the map around the stop is already on the phone before
/// the journey starts.
class OfflineMaps {
  OfflineMaps._();

  /// How long a tile is trusted without re-checking with the server.
  ///
  /// Deliberately far longer than the day or so OpenStreetMap's headers ask
  /// for. Those headers are tuned for a desktop browser on a fixed line,
  /// where a re-validation costs nothing and yesterday's tile is worth
  /// replacing. Here the same request is what turns a working map into a
  /// blank one the moment the bus enters a 2G patch, and a street that has
  /// not moved in thirty days is not worth that. The tile server is spared
  /// the requests either way, which its usage policy explicitly asks of us.
  static const _freshFor = Duration(days: 30);

  /// Ceiling on the tile store. Roughly a large city at street zoom; the
  /// least recently used tiles are dropped past it.
  static const _maxCacheBytes = 200 * 1024 * 1024;

  /// A backstop on how long one failed tile request stands as evidence of
  /// being offline.
  ///
  /// The flag is normally cleared by a tile actually arriving — see
  /// [_OfflineTolerantCachingProvider.putTile] — which is a far better
  /// signal than a clock, because it is the thing we actually want to know.
  /// This only covers the case where nothing is being fetched at all, and it
  /// is deliberately not short: while the flag is set, expired tiles are
  /// served from disk instead of being re-validated, so clearing it early
  /// means a screenful of doomed requests and a map that briefly fills with
  /// holes again, every time it expires, for as long as the journey lasts.
  static const _offlineWindow = Duration(minutes: 15);

  /// Zoom levels saved around a new alarm, and how far around it.
  ///
  /// Kept small on purpose. This is a few dozen tiles — the view a person
  /// actually needs to recognise where they are getting off — not a
  /// region download. OpenStreetMap's tile policy forbids bulk area
  /// downloads, and rightly: the servers are donated.
  static const _prefetchZooms = [13, 14, 15, 16];
  static const _prefetchRadiusMetres = 1200.0;
  static const _prefetchTileLimit = 80;

  /// One request at a time with a gap between, so a prefetch is
  /// indistinguishable from a person panning the map.
  static const _prefetchGap = Duration(milliseconds: 250);

  static final _nativeBridge = NativeBridge();

  /// Whether the network appears to be unreachable, as last reported by a
  /// tile that failed to load. Drives the offline notice on the map.
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  static Timer? _offlineExpiry;

  static BuiltInMapCachingProvider? _builtIn;
  static final _tolerant = _OfflineTolerantCachingProvider();

  static final _resetController = StreamController<void>.broadcast();

  /// Fires when cached tiles are worth re-reading — on going offline, so the
  /// tiles that failed against the network are re-served from disk instead of
  /// leaving holes in the map.
  static Stream<void> get refresh => _resetController.stream;

  /// One retrying client shared by every tile layer and by the prefetch.
  ///
  /// A tile that fails once used to stay blank until the app was restarted,
  /// which is what made the map look broken after switching between wifi and
  /// mobile data: the handover kills in-flight requests, and nothing tried
  /// again. Retries cover that, with a widening delay so a genuinely
  /// unreachable server is not hammered.
  ///
  /// 5xx and transport failures are retried; 429 deliberately is not.
  /// OpenStreetMap's tile policy treats that as "back off", and retrying
  /// through it would be the sort of behaviour that gets an app blocked.
  ///
  /// The connection cap is the other half of that. Dart's `HttpClient` opens
  /// as many sockets per host as it is asked to and will wait indefinitely to
  /// connect each one, so a burst of tile requests — a fast zoom is exactly
  /// that — could put a socket per tile in flight at once. Six at a time,
  /// each with a bounded connect attempt, is what a browser does and keeps
  /// the app inside OpenStreetMap's tile policy while a gesture is being
  /// flung about.
  static final http.Client client = RetryClient(
    IOClient(
      HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..maxConnectionsPerHost = 6,
    ),
    retries: 3,
    when: (response) => response.statusCode >= 500,
    whenError: (error, _) => isNetworkFailure(error),
    delay: (retry) => Duration(milliseconds: 400 * (1 << retry)),
  );

  /// The caching provider every tile layer reads through.
  static MapCachingProvider get cachingProvider => _tolerant;

  /// Prepares the tile store. Must complete before the first map is built,
  /// because flutter_map creates its own default store on first use and
  /// whichever exists first is the one that is kept.
  static Future<void> initialise() async {
    // Deliberately not the OS cache directory flutter_map would pick by
    // default. Android empties that under storage pressure and whenever the
    // user taps "clear cache" — reasonable for a browser's images, wrong for
    // the one copy of the map that has to survive until the journey. Stored
    // with the app's own data instead, capped, and clearable from Settings.
    String? directory;
    try {
      // Timed out rather than simply awaited: this runs before `runApp`, so
      // a platform channel that never answers is not a missing cache, it is
      // an app that never draws its first frame.
      directory = await _nativeBridge
          .offlineMapDirectory()
          .timeout(const Duration(seconds: 5));
    } on Exception {
      // No native side (tests, desktop), or it did not answer in time:
      // flutter_map's own default directory is fine.
      directory = null;
    }

    _tolerant.inner = _builtIn = BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: directory,
      maxCacheSize: _maxCacheBytes,
      overrideFreshAge: _freshFor,
    );
  }

  /// Whether [error] is the network being unreachable, as opposed to the
  /// server answering with something unwelcome.
  static bool isNetworkFailure(Object error) =>
      error is SocketException ||
      error is HttpException ||
      error is TimeoutException ||
      error is http.ClientException;

  /// Records that the network is working again, and lets the map go back to
  /// checking tiles against the server.
  static void markOnline() {
    _offlineExpiry?.cancel();
    _offlineExpiry = null;
    offline.value = false;
  }

  /// Called for every tile that fails to load.
  ///
  /// A transport failure is the only signal available here that the phone has
  /// no working connection — there is no connectivity plugin in this app, and
  /// a plugin would answer a different question anyway: "is there an
  /// interface up", not "did the request work", and on the 2G edge of a cell
  /// those two disagree constantly.
  static void reportTileError(Object error) {
    if (!isNetworkFailure(error)) return;

    _offlineExpiry?.cancel();
    _offlineExpiry = Timer(_offlineWindow, () => offline.value = false);

    if (offline.value) return;
    offline.value = true;
    // Tiles that just failed are still sitting in the layer as holes. Now
    // that stale cached copies will be accepted, ask for them again.
    _resetController.add(null);
  }

  // ------------------------------------------------------------- prefetching

  /// Whether new alarms save their surroundings. On by default: the whole
  /// point is that it has already happened by the time it is needed.
  static Future<bool> prefetchEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefetchKey) ?? true;
  }

  static Future<void> setPrefetchEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefetchKey, enabled);
  }

  /// Downloads the tiles around a point so the map still draws there with no
  /// connection.
  ///
  /// Never throws and never reports progress: it runs while the user is doing
  /// something else, and a failure means the map is exactly as good as it was
  /// before. Returns how many tiles were actually fetched, for tests and
  /// logging.
  static Future<int> saveArea({
    required double latitude,
    required double longitude,
    required String urlTemplate,
    double radiusMetres = _prefetchRadiusMetres,
    List<int> zooms = _prefetchZooms,
  }) async {
    if (offline.value) return 0;

    final urls = <String>[];
    for (final zoom in zooms) {
      urls.addAll(
        tileUrlsAround(
          latitude: latitude,
          longitude: longitude,
          radiusMetres: radiusMetres,
          zoom: zoom,
          urlTemplate: urlTemplate,
        ),
      );
      if (urls.length > _prefetchTileLimit) break;
    }

    final headers = {
      'User-Agent':
          'LocReminder/${await AppVersion.plain()} (https://github.com/zaifears/locreminder)',
    };

    var saved = 0;
    for (final url in urls.take(_prefetchTileLimit)) {
      // Already held and still good: nothing to do, and no request to make.
      try {
        final existing = await cachingProvider.getTile(url);
        if (existing != null && !existing.metadata.isStale) continue;
      } catch (_) {
        // Unreadable cache entry; fetching replaces it.
      }

      try {
        final response = await client.get(Uri.parse(url), headers: headers);
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) continue;

        late final CachedMapTileMetadata metadata;
        try {
          metadata = CachedMapTileMetadata.fromHttpHeaders(response.headers);
        } catch (_) {
          metadata = CachedMapTileMetadata(
            staleAt: DateTime.timestamp().add(_freshFor),
            lastModified: null,
            etag: null,
          );
        }

        await cachingProvider.putTile(
          url: url,
          metadata: metadata,
          bytes: response.bodyBytes,
        );
        saved++;
      } catch (error) {
        if (isNetworkFailure(error)) {
          // The connection went away mid-prefetch. Stop rather than grinding
          // through eighty timeouts.
          reportTileError(error);
          break;
        }
      }

      await Future<void>.delayed(_prefetchGap);
    }

    return saved;
  }

  /// Every tile URL covering a [radiusMetres] square around a point.
  ///
  /// Plain slippy-map arithmetic, which is the same on every raster source
  /// the app offers, so one implementation covers all four.
  @visibleForTesting
  static List<String> tileUrlsAround({
    required double latitude,
    required double longitude,
    required double radiusMetres,
    required int zoom,
    required String urlTemplate,
  }) {
    const metresPerDegreeLatitude = 111320.0;
    final latitudeSpan = radiusMetres / metresPerDegreeLatitude;
    // A degree of longitude shrinks towards the poles; the floor keeps the
    // division finite where the cosine does not.
    final metresPerDegreeLongitude = math.max(
      1.0,
      metresPerDegreeLatitude * math.cos(latitude * math.pi / 180).abs(),
    );
    final longitudeSpan = radiusMetres / metresPerDegreeLongitude;

    final left = _tileX(longitude - longitudeSpan, zoom);
    final right = _tileX(longitude + longitudeSpan, zoom);
    // Tile rows count southwards, so the northern edge is the lower number.
    final top = _tileY(latitude + latitudeSpan, zoom);
    final bottom = _tileY(latitude - latitudeSpan, zoom);

    final urls = <String>[];
    for (var x = left; x <= right; x++) {
      for (var y = top; y <= bottom; y++) {
        urls.add(
          urlTemplate
              .replaceAll('{z}', '$zoom')
              .replaceAll('{x}', '$x')
              .replaceAll('{y}', '$y')
              // Present in some templates as a load-spreading subdomain. The
              // styles here don't use it, but substituting something valid is
              // cheaper than a broken URL if one ever does.
              .replaceAll('{s}', 'a'),
        );
      }
    }
    return urls;
  }

  static int _tileX(double longitude, int zoom) {
    final count = 1 << zoom;
    return _withinGrid((((longitude + 180) / 360) * count).floor(), count);
  }

  static int _tileY(double latitude, int zoom) {
    final count = 1 << zoom;
    // Web Mercator falls apart at the poles; this is the standard slippy-map
    // cut-off, past which no tiles exist to ask for.
    final clamped = math.max(-85.05112878, math.min(85.05112878, latitude));
    final radians = clamped * math.pi / 180;
    final y = (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) / 2;
    return _withinGrid((y * count).floor(), count);
  }

  static int _withinGrid(int index, int count) {
    if (index < 0) return 0;
    if (index > count - 1) return count - 1;
    return index;
  }

  // ------------------------------------------------------------- housekeeping

  /// Bytes currently held, or null where the directory cannot be read.
  static Future<int?> cacheSizeBytes() async {
    final directory = _builtIn == null ? null : await _cacheDirectory();
    if (directory == null || !directory.existsSync()) return null;

    var total = 0;
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) total += await entity.length();
      }
    } on FileSystemException {
      return null;
    }
    return total;
  }

  /// Throws away every saved tile. The next map view refills from the network.
  static Future<void> clearCache() async {
    final builtIn = _builtIn;
    if (builtIn == null) return;

    // Detached before it is torn down, not after. A map on screen keeps
    // asking for tiles throughout, and a store whose worker isolate has been
    // killed is a worse thing to ask than no store at all — the wrapper
    // answers "not cached" for a null one, which is exactly right here.
    _tolerant.inner = null;
    _builtIn = null;

    await builtIn.destroy(deleteCache: true);
    await initialise();
    _resetController.add(null);
  }

  static Future<Directory?> _cacheDirectory() async {
    try {
      final path = await _nativeBridge.offlineMapDirectory();
      if (path == null) return null;
      // The name flutter_map gives the directory it creates inside the one it
      // is handed.
      return Directory('$path${Platform.pathSeparator}fm_cache');
    } on Exception {
      return null;
    }
  }
}

/// Serves an expired tile rather than nothing, once the network is known to
/// be unreachable.
///
/// flutter_map's own provider is strict about freshness: a stale tile is
/// re-validated against the server, and if the server cannot be reached the
/// tile is dropped and the map draws a hole. That is the correct trade on a
/// desktop and precisely the wrong one here — a month-old picture of a street
/// is worth a great deal more to somebody trying to work out which stop is
/// coming than a grey square is.
///
/// [inner] is mutable so clearing the cache can swap the underlying store
/// without every tile layer in the app having to be rebuilt around a new
/// object.
class _OfflineTolerantCachingProvider implements MapCachingProvider {
  MapCachingProvider? inner;

  @override
  bool get isSupported => inner?.isSupported ?? false;

  @override
  Future<CachedMapTile?> getTile(String url) async {
    final store = inner;
    if (store == null) return null;

    final tile = await store.getTile(url);
    if (tile == null || !OfflineMaps.offline.value || !tile.metadata.isStale) {
      return tile;
    }

    return (
      bytes: tile.bytes,
      metadata: CachedMapTileMetadata(
        // Only long enough to outlast the offline spell. The tile is not
        // actually fresh, and pretending otherwise on disk would keep it from
        // ever being re-checked once there is a connection again to do it
        // with.
        staleAt: DateTime.timestamp().add(const Duration(minutes: 5)),
        lastModified: tile.metadata.lastModified,
        etag: tile.metadata.etag,
      ),
    );
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) async {
    // Only reached when a tile has just come back from the server, which is
    // better evidence that the network is working than any timer or
    // connectivity flag could be: not "is there an interface up" but "did a
    // request just succeed".
    if (OfflineMaps.offline.value) OfflineMaps.markOnline();

    await inner?.putTile(url: url, metadata: metadata, bytes: bytes);
  }
}
