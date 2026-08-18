# Changelog

All notable changes to LocReminder are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

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

[1.5.0]: https://github.com/zaifears/locreminder/releases/tag/v1.5.0
[1.4.0]: https://github.com/zaifears/locreminder/releases/tag/v1.4.0
[1.3.0]: https://github.com/zaifears/locreminder/releases/tag/v1.3.0
[1.2.0]: https://github.com/zaifears/locreminder/releases/tag/v1.2.0
[1.1.0]: https://github.com/zaifears/locreminder/releases/tag/v1.1.0
[1.0.0]: https://github.com/zaifears/locreminder/releases/tag/v1.0.0
