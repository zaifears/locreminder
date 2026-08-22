# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Two audiences that matter equally, and the tension between them shapes most
decisions:

- **Commuters and travellers.** Someone on a long bus or train journey who
  knows roughly where they are going but not when they will arrive. They want
  to sleep, read, or work instead of watching for their stop. Dhaka bus and
  train routes are the case the app was built around and the default map
  position, but the job is the same anywhere.
- **Privacy-minded Android users.** People on de-Googled ROMs, Huawei and
  Honor devices without Play Services, LineageOS, GrapheneOS. They need an
  alarm that works with no Google dependency at all, and they audit what they
  install.

Neither is secondary. The first group judges the app on whether it rings; the
second on what it does not contain.

## Product Purpose

An alarm that goes off at a place rather than a time. The user drops a pin,
chooses how close to get, and puts the phone away; on arrival the app rings a
real alarm — looping audio on the alarm stream so it sounds through silent
mode, vibration, and a full-screen alert over the lock screen.

Success is narrow and absolute: **it rings, at the right place, with the app
closed and the screen off.** Everything else is secondary to that.

## Positioning

A location alarm that uses no Google Play Services whatsoever. Location comes
from Android's platform `LocationManager`; maps and search come from
OpenStreetMap and Nominatim, needing no API key or account. That is what
neighbouring apps cannot truthfully copy without rebuilding their location
stack — most depend on the fused Play Services client and therefore fail on
exactly the devices this app targets.

Reproducible builds are verified, so F-Droid publishes the developer's own
signed APK rather than re-signing, and the GitHub and F-Droid builds are
interchangeable.

## Operating Context

- **Used while in motion**, one-handed, on a moving vehicle, often with the
  phone half-attended or pocketed.
- **The app is usually closed while it matters.** Detection runs in a native
  foreground service; the Flutter engine may be entirely dead when the alarm
  fires.
- **Vendor power management is the standing enemy.** Xiaomi, Samsung, Oppo,
  Vivo, OnePlus, Huawei each kill background services in ways no app can
  override. A dedicated reliability screen detects the manufacturer, gives the
  exact settings to change, and offers a test alarm.
- **Network is unreliable in transit**, including wifi/mobile handovers that
  kill in-flight tile requests.

## Capabilities and Constraints

- Multiple simultaneous alarms, each with its own label and radius; pausable
  without deleting.
- Radius from 100 m to 3 km. The floor is real: OpenStreetMap data can sit
  tens of metres off true position in some areas, so a tighter radius would
  promise precision the underlying data cannot support.
- Custom alarm sound (system ringtone or a user's own audio file); vibration
  toggle.
- Adaptive polling — roughly 5 minutes beyond 10 km, 10 seconds within 500 m —
  so a three-hour journey does not flatten the battery.
- Arrival is only confirmed by a fix precise enough to place the user inside
  the radius (floored at 500 m), because a coarse cell-tower fix could
  otherwise ring kilometres early.
- Alarm engine is native Kotlin, independent of the Flutter engine.
- Data is device-local (`SharedPreferences`). No account, no server, no sync.
- Android 6.0 (API 23) and above.
- Map styles: standard OpenStreetMap plus Humanitarian, Topographic and Cycle.
  **No satellite view** — every provider of satellite imagery is a proprietary
  service, and depending on one would contradict the positioning above.

## Brand Commitments

- Name **LocReminder**, the logo and the app icon are © Shahoriar Hossain, all
  rights reserved. The source code and other artwork are MIT.
- Zero F-Droid anti-features. No tracking, ads, accounts, analytics, or
  non-free dependencies. This is a deliberate standing constraint, not an
  accident, and any future dependency must be checked against it.
- A Free Palestine banner in the About screen, linking to Revolutionary
  Papers.
- Voice: plain, direct, unhyped. Tells users what could go wrong (vendor app
  killers, the upgrade key break) rather than glossing over it.

## Evidence on Hand

- Source: `https://github.com/zaifears/locreminder` — public, MIT.
- F-Droid submission under review: fdroiddata MR !46299, with reproducible
  builds verified.
- Every release is scanned by VirusTotal before publication; results and APK
  checksums are recorded in `docs/SECURITY-SCAN.md`, and a live badge sits in
  the README.
- Store metadata and six phone screenshots in
  `fastlane/metadata/android/en-US/`.
- Privacy policy at `PRIVACY.md`.
- **No usage analytics of any kind exist**, deliberately. There is no user
  count, retention figure, or engagement data, and future work must not
  fabricate one or quote a number as if measured. Downloads counted by GitHub
  Releases are the only real signal.

## Product Principles

1. **Ringing beats everything.** Battery, elegance and feature breadth all
   yield to whether the alarm fires with the app closed. A missed stop is the
   only unrecoverable failure.
2. **Say what can go wrong.** Vendor app-killers, key changes that break
   upgrades, map data that sits 50 m off — the app and its documentation name
   these plainly rather than letting users discover them mid-journey.
3. **Nothing proprietary, no exceptions.** Any dependency, tile source or
   service that is not free software is declined, and the reason is explained
   where a user would otherwise ask.
4. **Claims must be checkable.** Every assurance is tied to something a user
   can verify: a checksum, a scan report, a reproducible build, public source.
5. **Usable without attention.** The person using this is on a bus, one-handed,
   possibly half-asleep. Anything demanding focus or precision has failed them.

## Accessibility & Inclusion

- **One-handed, in-transit use is a requirement**, not a preference. Controls
  must be reachable with a thumb, tap targets generous, and no interaction
  should demand steadiness the user does not have on a moving vehicle.
- Screen-reader and large-text support: **not yet established as a
  requirement.** Recorded as undecided rather than assumed.

## Open Decisions

- **Scope boundary is undecided.** Whether the app stays a single-purpose
  arrival alarm or grows adjacent features (recurring alarms, saved routes,
  journey history) has not been settled. Future work should not silently
  assume either.
