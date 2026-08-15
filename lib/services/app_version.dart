import 'package:package_info_plus/package_info_plus.dart';

/// Reads the version straight from the built package.
///
/// It used to be typed into the About screen by hand, which drifted out of
/// step with pubspec.yaml the moment a release was cut. Sourcing it from the
/// package makes that impossible.
class AppVersion {
  static String? _cached;

  static Future<String> get() async {
    final cached = _cached;
    if (cached != null) return cached;

    final info = await PackageInfo.fromPlatform();
    final value = '${info.version} (build ${info.buildNumber})';
    _cached = value;
    return value;
  }
}
