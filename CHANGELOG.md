# Changelog

All notable changes to LocReminder are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

## [1.8.1] - 2026-08-24

### Added
- An alarm can carry a task in your own words. The label used to be whatever
  the place was called, so "Buy medicine" arrived as the name of the pharmacy.
  The picker now has a field for it, left blank with the place name as its
  hint — nothing to clear before typing, and nothing for the address lookup to
  overwrite a moment later if you were mid-sentence.
- Alarms can repeat: once, every day, or on the weekdays you choose. A
  repeating alarm stays armed after it rings, so a commute or a standing
  errand is set once rather than every morning.

  It rings once per day on each day it is set for. Leaving the area and
  coming back the same afternoon does not ring it again, and an alarm you are
  already sitting inside when its day comes round still waits until you have
  actually arrived.

### Changed
- The app is described by what it does rather than only by one use of it. It
  was "helps you wake up at the right place", which tells someone looking for
  a location-based reminder that this is not their app. It is the same
  mechanism either way.
- The About screen links to GitHub only; the author's email address and
  personal website are no longer published in the app.
- The store listing promised "errands, as a nudge" a few lines above "a real
  alarm, not a quiet notification". Both could not be true. Every alarm is a
  full alarm, errands included, and the listing now says so.

### Fixed
- Release notes are no longer truncated. Both stores cut the What's New text
  off at 500 characters without warning, and four entries were over it —
  1.8.0's worst of all, at 734. The limit is checked in the build now.

## [1.8.0] - 2026-08-23

### Fixed
- Zooming the map out quickly could leave it frozen and take the app down with
  it. flutter_map turns a pinch into a zoom with `log(scale)`, and its only
  guard is a clamp against the map's own zoom limits — which this app had
  never set, making the clamp a no-op. A fast enough gesture reports a scale
  of zero, `log(0)` is negative infinity, and that went straight into the
  camera: every projection then worked from a world of zero size, and the
  resulting NaN spread through the tile and marker maths until nothing could
  be drawn. Both maps now hold between zoom 2 and 19.
- The picker's radius circle drifted away from the centre crosshair while the
  map was being dragged, then jumped back a moment after it stopped. The
  circle was drawn at the last centre the screen had been told about, and it
  was only told once the address lookup fired. It now follows the map itself,
  so the circle and the pin never disagree about where the alarm will go.
- One unreadable saved alarm — written by an older build, or truncated by the
  system killing the app mid-write — took the whole list with it and left the
  app on its loading spinner permanently. Bad records are skipped now, and
  startup can no longer be stopped by anything it reads.
- A permission check that the platform refused to answer had the same effect,
  on the launch screen. Any single check that fails is now read as "not
  granted" instead of stopping the screen from loading.
- The alarm test on the reliability screen said "lock your phone now" even
  when scheduling the test had been refused, which is the one screen where a
  silent failure is worst. It now says what went wrong.
- Deleting an alarm, tapping Contact on the About screen with no mail app set
  up, and opening a vendor settings screen that does not exist could each
  throw where nothing was catching.
- The topographic map went blank above zoom 17 rather than blurry.
  OpenTopoMap does not publish tiles past that level, and the app had not
  said so, so it kept asking for tiles that will never exist.

### Changed
- The blue from the launcher icon is now the app's accent everywhere, in both
  light and dark themes. It was already the seed for the colour scheme, but
  Material treats a seed as a hue to harmonise rather than a colour to
  reproduce, so the blue on screen never actually matched the icon. Surfaces
  are still Material's generated tonal greys; the accent roles are now the
  icon's own blue, lightened for dark mode so it can carry text.

  It shows up on the alarm switches, the "Add alarm" button, the theme
  picker, section labels, links and the About screen's app mark. The two
  small map buttons deliberately went the other way — white with a blue
  glyph — so that only one control on the map reads as the primary action.
- Map tiles are darkened with a single filter over the whole layer instead of
  one per tile. A colour filter allocates an offscreen buffer, and doing that
  per tile meant dozens of them every frame of a pan or a pinch, at exactly
  the moment there was least headroom.
- Tile requests are capped at six connections at a time with a bounded
  connect attempt, so a flung gesture cannot put a socket in flight per tile.

## [1.7.1] - 2026-08-23

### Fixed
- Phones the app did not recognise were told they were fine. The reliability
  screen printed a fixed sentence saying the manufacturer follows Android's
  standard background rules, which is exactly what is not known about a brand
  the app has never heard of. It also hid the fallback advice, which was the
  only guidance available to those users. The real note is shown now.

### Added
- Phone-specific advice for around fifteen more manufacturers: TCL and
  Alcatel, HTC, Sharp and Kyocera, Amazon's Fire OS, the MediaTek-based
  budget brands (Ulefone, Doogee, Blackview, Cubot, Umidigi, Oukitel), and a
  group covering Walton, Symphony, Lava, Micromax, Karbonn, BLU, Wiko and
  others. Around forty-five brands are now named, up from thirty.

  The MediaTek entry matters most of the new ones. Those phones ship
  DuraSpeed, which closes background apps, sits outside Android's own battery
  settings, and is switched on by default. It cannot be found unless you know
  its name.

  Phones in the grouped entry show their own brand rather than a label
  invented to cover a dozen unrelated makers.
- Translations now need one file and no tooling. Everything the app says
  lives in `locale/<code>.yaml`, and a generator turns it into the three
  formats the app actually reads: Dart for the screens, Android resources for
  the alarm, and the F-Droid listing. Adding a language means copying
  `locale/en.yaml`, translating the right-hand side, and nothing else.

  No new dependencies, and the generator never runs during a build. Its
  output is committed and CI only checks it still matches its source, so the
  reproducible build is untouched.

  The alarm's text and the store listing have moved across, leaving no
  hardcoded user-facing text in the Android side at all. The app's own
  screens follow file by file; anything not yet moved still works exactly as
  before.
- `docs/LANGUAGE.md` lists all 305 strings in the app in one table, ready to
  be filled in by hand and turned into a language file.

## [1.7.0] - 2026-08-23

### Fixed
- With two alarms armed, the second could stay silent for the whole journey
  and then ring on the way back past it. Two separate faults each caused
  exactly that, and both are fixed.

  The first was arrival state living in memory. An alarm rings on crossing
  *into* its radius, so one set for where you are standing has to wait until
  you leave and return, and deciding that needs a record of where you have
  been. That record was two fields on the watch service. The service is
  restarted automatically if Android kills it, which aggressive battery
  managers do routinely and most of all right after a full-screen alarm takes
  over the phone. It came back with the record erased, so the next location
  fix looked like the first one ever taken, and any alarm you were already
  approaching was filed as "we started inside this one" and held back until
  the next time you left its radius. The record is now saved to disk.

  The second was a second arrival landing while the first alarm was still
  ringing. It was discarded outright, and because the alarm is only removed
  from the armed list further along, it was left armed as well: silently
  swallowed, then rung on re-entry. Arrivals now fold into the ring already
  in progress, name both stops, and restart the ten-minute cutoff from the
  newer arrival.
- Vibration was suppressed by Do Not Disturb and the silent profile. It did
  not declare itself as an alarm, so Android treated it as an ordinary
  notification buzz and muted it — leaving the phone playing the tone while
  sitting perfectly still in a pocket, which is the exact case vibration
  exists for. It now also uses the current vibrator API on Android 12 and
  above, and checks the phone has a vibrator before trying.
- Messages appeared in the middle of the map and looked stuck there. A
  floating message is laid out above whatever sits in the corner button slot,
  and that slot held a column of three buttons rather than one, which pushed
  every message a quarter of the way up the screen. Messages also queued
  behind each other, so a burst played back one at a time long after the
  action that caused it. Only one shows at a time now, at the bottom, for at
  most five seconds.
- Tapping the search bar took two taps to start typing. The first opened the
  search screen with the field unfocused, so the keyboard needed a second tap
  on a field you had in effect already tapped. It now opens ready to type.
  "Add alarm" still opens on the map, since that asks for a place rather than
  a name.

### Added
- Location checks now account for how fast you are moving. The intervals were
  based on distance alone, which assumes a speed — and on a highway coach or
  an intercity train it assumes far too low a one. At 108 km/h the app could
  travel 600 m between two checks, enough to cross a small alarm area without
  ever noticing. Where the phone reports a speed, the interval is also worked
  out from how long is left until arrival, and the tighter of the two wins.
- The alarm area now opens wider than 500 m when you set an alarm while
  already travelling fast, and says why. Above 90 km/h it starts at 1 km,
  above 50 at 500 m, above 25 at 300 m. Drag it back below that and it warns
  you the alarm may pass your stop between checks.

### Documentation
- `docs/LOCALISATION.md` records what adding a language would take: the
  inventory of every translatable string, where each has to live, and the
  parts that are not just moving text.

## [1.6.16] - 2026-08-22

### Fixed
- The saved-location pin drew as a lopsided blob rather than a teardrop. Its
  head's arc swept the wrong way round the circle: from the right tangent
  point it ran 240 degrees clockwise, which ends at the top of the head rather
  than at the left tangent, so the arc crossed the body and closing the path
  cut a straight chord across the head. It has been malformed since the pin
  was written.
- The map style and locate buttons sat inset from the screen edge. The column
  holding them centres its children, and the wide "Add alarm" button set the
  column's width, so the two small buttons were pulled inward. All three now
  align to the edge.
- The map controls stayed pinned over the alarm list once it was dragged open.
  They now follow the sheet while it is near its resting size and fade out
  past the point where the list owns the screen.

## [1.6.15] - 2026-08-22

### Fixed
- The map pin drew as two overlapping markers on some phones. Its shadow used
  `Canvas.drawShadow`, Material's elevation primitive, which rasterises
  differently per backend and lands under Impeller as a hard offset silhouette
  rather than a blur. It is now a blurred copy of the same shape, which
  renders the same everywhere.
- A map tile that failed to load stayed blank until the app was restarted, so
  switching between wifi and mobile data could not recover it: the handover
  kills requests in flight and nothing tried again. Tiles now retry, with a
  widening delay, and failed ones are evicted so returning to an area fetches
  them afresh. 429 is deliberately not retried, since OpenStreetMap's tile
  policy treats it as a request to back off.

### Added
- Humanitarian, Topographic and Cycle map styles alongside the standard one,
  remembered per device and shared by both map screens.

> No satellite view, and the style sheet says why. Every provider of satellite
> imagery is a closed service, so offering one would mean depending on
> something users cannot inspect, for a feature a location alarm does not
> need.

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
