# Changelog

All notable changes to LocReminder are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

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
