# Changelog

All notable changes to LocReminder are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

## [1.6.14] - 2026-08-21

### Changed
- Releases are compiled inside F-Droid's own buildserver container, at the
  same paths F-Droid uses. Matching versions individually was not enough:
  with the NDK, CMake, Flutter, build path, package cache and locked
  dependencies all provably identical, one library still differed. Sharing
  the image removes the remaining variables, the operating system and its
  libraries among them, in one step rather than one release at a time.

## [1.6.12] - 2026-08-21

### Changed
- Releases are built with `PUB_CACHE` inside the project rather than in the
  home directory, matching where F-Droid puts it. `libdartjni.so` is the one
  library compiled from sources that live in the package cache, and the one
  file that would not reproduce. Everything else was already aligned: the
  logs on both sides show the same NDK r28c, the same CMake 3.22.1, the same
  Flutter, the same build path and the same locked dependencies.

## [1.6.11] - 2026-08-21

### Changed
- The Android NDK version is pinned explicitly rather than left to whatever
  Flutter defaults to, and the build environment points at that same copy.
  F-Droid's rebuild of 1.6.10 matched byte for byte everywhere except
  `libdartjni.so`, the one library compiled from native source by Dart's
  build-hook mechanism. That hook takes its toolchain from the environment
  rather than from Gradle's `ndkVersion`, and the two build machines offer
  different defaults, so the same source could go through different
  compilers.

## [1.6.10] - 2026-08-21

### Fixed
- `pubspec.lock` had drifted badly out of step with `pubspec.yaml`. It still
  named geolocator and google_maps_flutter, both dropped in 1.6.0 along with
  Play Services, while missing flutter_map, latlong2, url_launcher,
  package_info_plus and shared_preferences, which the app actually uses.
  Nothing caught it because the build ran a plain `pub get`, which resolves
  whatever it likes and rewrites the file in place, so the stale copy was
  never read. Builds now enforce the lockfile, which pins every dependency
  to an exact version and makes two builds of the same commit resolve
  identically.

## [1.6.9] - 2026-08-21

### Changed
- The Flutter version used to build releases is pinned rather than tracking
  whatever the stable channel happens to be that week. This is what makes the
  build reproducible: F-Droid rebuilds the app from source and compares the
  result byte for byte, and a compiler that changes underneath would make the
  two differ for no visible reason.

Once reproducible builds are verified, F-Droid can publish this project's own
signed APK instead of re-signing with its key, which means the GitHub and
F-Droid builds become interchangeable and you can move between them without
uninstalling.

## [1.6.8] - 2026-08-21

### Added
- A Free Palestine banner at the end of the About screen, linking to
  Revolutionary Papers. It sits on a light card rather than directly on the
  surface, because the artwork is dark ink on a transparent background and
  would otherwise be close to invisible in dark mode.

No change to how alarms work in this version.

## [1.6.7] - 2026-08-21

### Added
- Every tagged release is scanned by VirusTotal before the GitHub Release is
  created, so a build that looks like malware is never published. The verdict,
  a link to the full report and the APK's SHA-256 go into the release notes, a
  [scan log](docs/SECURITY-SCAN.md) and a README badge. The hash is carried
  alongside the verdict throughout: a clean report proves something about a
  file, and only the hash proves it was the one you downloaded.

No change to the app itself in this version.

## [1.6.6] — 2026-08-21

### Fixed
- Releases are signed with a real key. `build.gradle.kts` falls back to
  debug signing when no keystore is configured, so that a fresh clone can
  still run `flutter build apk --release` — but nothing checked whether CI
  was taking that path, and it was: no signing secrets had ever been set,
  so every release through 1.6.5 was signed with Android's debug key.
  That key ships identically with every SDK install, so it identified
  nobody and let anyone sign an update Android would accept in place.
  Tagged builds now fail if a signing secret is missing, and read the
  certificate back out of the finished APK to prove the debug key was not
  used.

> **Upgrading from an earlier GitHub build requires uninstalling it
> first.** Android refuses updates signed with a different key. Saved
> alarms will be lost. This does not affect F-Droid, which signs its own
> builds.

## [1.6.5] — 2026-08-20

### Fixed
- An alarm armed while location was switched off never watched anything.
  `requestUpdates()` found no enabled provider and returned early, but
  the service still reported itself as watching, so the watchdog saw a
  healthy watcher and never retried — and with no listener registered,
  the provider-enabled callback could not fire when location came back.
  The service sat in the foreground claiming to watch while nothing
  could trigger. "Alive" and "actually receiving fixes" are now tracked
  separately, the watchdog restarts on either, the provider callbacks
  are implemented, and the state is visible instead of silent.
- Coarse fixes could ring the alarm kilometres early: arrival compared
  raw distance and ignored `Location.accuracy` — already being read and
  then discarded — so a cell-tower fix good to ~2 km satisfied a 200 m
  radius. A fix must now be precise enough to place you inside the
  radius, floored at 500 m, since a missed stop is worse than an early
  one.
- "Centre on my location" read only the platform's cached fix, which is
  null after a reboot or fresh install — the button did nothing, with no
  feedback — and otherwise could be hours out of date. It now requests a
  real fix, falls back to the cache after 8 s, shows progress, and
  explains failure.

### Changed
- The blue dot draws its actual accuracy, instead of a fixed-size circle
  implying a precision it may not have at the same scale as the radius
  people choose.
- AGP's dependency-metadata block is no longer stamped into the APK. It
  is encrypted to a Google key, so it is unreadable and unreproducible
  by anyone else — unwanted in a package that is otherwise entirely free
  software, and something F-Droid's scanner inspects.
- The Nominatim `User-Agent` reports the real version; it had been
  hardcoded to 1.0 since well before 1.6.x.
- The README download button points at the GitHub Release asset rather
  than a copy committed into the repository, which kept a ~53 MB binary
  in history per release and could not be counted.

## [1.6.4] — 2026-08-20

### Fixed
- 1.6.3 narrowed the keep rule for Flutter's deferred-components manager,
  which dropped 1 of the 6 flagged Play Core classes but missed 5:
  `FlutterPlayStoreSplitApplication` — a separate Flutter class that
  extends Play Core's `SplitCompatApplication` and directly constructs
  a `PlayStoreDeferredComponentManager` in its startup code — was still
  matched by the general keep rule, which kept it and everything it
  reaches. This app's manifest never uses that class, so it's now
  excluded too.

## [1.6.3] — 2026-08-20

### Fixed
- 1.6.2's fix for the Play Core classes didn't work: they're compiled
  directly into Flutter's own engine artifact, not pulled in as a
  separate dependency, so excluding a Gradle dependency group had
  nothing to act on. The real cause was a blanket ProGuard keep rule for
  `io.flutter.**`, which forced R8 to preserve Flutter's unused
  deferred-components manager — and, with it, the Play Core classes its
  fields and methods are typed with. That rule now carves the manager
  out explicitly, so R8 is free to drop it and everything it pulled in.

## [1.6.2] — 2026-08-20

### Fixed
- The release build carried real, unused Google Play Core classes,
  pulled in transitively by Flutter's own embedding artifact to support
  optional dynamic-feature delivery. A `-dontwarn` rule kept R8 from
  erroring on the dangling reference but never stopped Gradle from
  bundling the actual classes, which F-Droid's non-free-code scanner
  flags regardless of whether the app calls them. The dependency group
  is now excluded outright so nothing from it enters the build.

## [1.6.1] — 2026-08-20

### Fixed
- The About screen still said the app "uses Android's built-in geofencing",
  which stopped being true in 1.6.0 when geofencing was removed. It now
  describes what the app actually does and notes it carries no Google
  services.
- Device setup guidance had drifted: the native side flagged Meizu, Asus
  and LeEco as needing extra steps while the UI had none to show them, so
  those users saw a warning with only generic advice. Vendor names, steps
  and notes now come from a single table, so that cannot recur.
- Mixed British and American spellings of "optimization" across screens;
  now consistently American, matching Android's own English settings
  labels so the wording matches what users are hunting for.

### Added
- Honor listed separately from Huawei — its menus diverged after the split.
- Guidance for Meizu (Flyme), Asus (ZenUI), and Lenovo / ZTE / LeEco.
- Stock-Android manufacturers (Google, Motorola, Sony, Nokia, Nothing,
  Fairphone) are now recognised by name and told no extra setup is needed.

## [1.6.0] — 2026-08-19

### Changed
- **Removed all Google Play Services dependencies.** Location now uses the
  platform `LocationManager`, which on Android 12+ exposes the same fused
  provider natively. The `geolocator` package was also dropped, since it
  pulled Play Services in transitively.
- Play Services geofencing was removed rather than replaced. It was already
  the least reliable path — deferred by Doze on exactly the devices that
  need help most — and the foreground watcher was doing the real work.

### Added
- Works on devices with no Google services at all: post-2019 Huawei/Honor
  (HMS), and de-Googled ROMs such as LineageOS, /e/OS and GrapheneOS.
- Eligible for F-Droid, which rejects or flags non-free dependencies.

## [1.5.0] — 2026-08-15

### Added
- **Custom alarm sounds.** Pick any system ringtone, or an audio file of
  your own (mp3, m4a, ogg, wav, flac), with a preview button.
- Separate vibration toggle.
- F-Droid publication metadata, privacy policy and changelog.

### Fixed
- A custom sound that later becomes unreadable — file deleted, SD card
  removed, permission revoked — now falls back to the default alarm tone
  instead of leaving the alarm silent.

## [1.4.0] — 2026-08-15

### Added
- **Alarm reliability screen.** Detects the phone's manufacturer and shows
  the exact settings path for that model (Xiaomi autostart, Samsung
  never-sleeping apps, Oppo/Vivo/OnePlus/Huawei equivalents), with a deep
  link to the vendor screen.
- **Alarm self-test** that rings the real alarm after 15 seconds so it can
  be verified from a locked screen.
- **Watchdog** that restarts the location watcher if a vendor power manager
  kills it, and warns the user if even that is blocked.
- **Approach geofence** — a wide outer ring that wakes the watcher for the
  final approach, allowing much lazier polling on long journeys.

### Changed
- Material 3 pass across the app: consistent radii, elevation, touch
  targets, floating snackbars and predictive back.

## [1.3.0] — 2026-08-15

### Fixed
- **Alarms did not fire in the background.** Geofence transitions were
  being deferred by Doze and App Standby until the app was next opened,
  so the alarm stayed silent for an entire journey and then rang on
  launch. Added a foreground location service that keeps the process out
  of that idle state and detects arrival itself; Play Services geofencing
  is retained as a backup path.
- Battery optimisation is now a required permission rather than a
  suggestion, since it directly causes the deferral above.
- Map pins were anchored by their centre rather than their tip, so they
  appeared offset from the geofence circle.
- The app version shown in About was hardcoded and had drifted.

## [1.2.0] — 2026-08-15

### Fixed
- **The geofence receiver required a permission the sender could not
  hold**, which silently dropped every geofence broadcast. Alarms could
  never have fired.
- Service restarts with a null intent rang a phantom alarm for a
  destination the user never set.
- Geofences fired immediately when registered inside their own radius.
- Nothing stopped an unattended alarm; it now auto-stops after 10 minutes.

### Added
- Permission-loss banner, live distance to each alarm, undo on delete,
  tappable pins.

## [1.1.0] — 2026-08-15

### Added
- Destination search via OpenStreetMap Nominatim, replacing blind map
  tapping, with a centre-crosshair picker and live reverse geocoding.
- Navigation drawer with Settings and About.
- Light, dark and system themes.
- Four full-screen permission explanations shown before each request.

### Changed
- Replaced Google Maps with OpenStreetMap, removing the API key and
  billing account requirement entirely.

## [1.0.0] — 2026-08-15

### Added
- Initial release: native Android geofencing, foreground alarm service
  with looping audio on the alarm channel, full-screen lock-screen alarm,
  and geofence restoration after reboot.

[1.6.1]: https://github.com/zaifears/locreminder/releases/tag/v1.6.1
[1.6.0]: https://github.com/zaifears/locreminder/releases/tag/v1.6.0
[1.5.0]: https://github.com/zaifears/locreminder/releases/tag/v1.5.0
[1.4.0]: https://github.com/zaifears/locreminder/releases/tag/v1.4.0
[1.3.0]: https://github.com/zaifears/locreminder/releases/tag/v1.3.0
[1.2.0]: https://github.com/zaifears/locreminder/releases/tag/v1.2.0
[1.1.0]: https://github.com/zaifears/locreminder/releases/tag/v1.1.0
[1.0.0]: https://github.com/zaifears/locreminder/releases/tag/v1.0.0
