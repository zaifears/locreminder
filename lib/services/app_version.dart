import 'package:package_info_plus/package_info_plus.dart';

/// Reads the version straight from the built package.
///
/// It used to be typed into the About screen by hand, which drifted out of
/// step with pubspec.yaml the moment a release was cut. Sourcing it from the
/// package makes that impossible.
class AppVersion {
  static String? _cached;
  static String? _cachedPlain;

  static Future<String> get() async {
    final cached = _cached;
    if (cached != null) return cached;

    final info = await PackageInfo.fromPlatform();
    final value = '${info.version} (build ${info.buildNumber})';
    _cached = value;
    return value;
  }

  /// Just the version name, e.g. `1.6.4`, for places that need it inside a
  /// larger string rather than shown to the user — a User-Agent, say.
  ///
  /// Falls back to `unknown` rather than throwing: a failure to read package
  /// metadata should never be able to take out place search along with it.
  static Future<String> plain() async {
    final cached = _cachedPlain;
    if (cached != null) return cached;

    try {
      final value = (await PackageInfo.fromPlatform()).version;
      _cachedPlain = value;
      return value;
    } catch (_) {
      return 'unknown';
    }
  }
}
