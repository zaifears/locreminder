# Adding a language

LocReminder is English-only today. This is the plan for changing that, and
the inventory of everything a translator would have to touch.

Nothing here is done yet. It is written down first because the shape of the
work decides where the strings should live, and moving 350 strings twice is
worse than moving them once.

## What "easy to add a language" should mean

The target: adding Bangla is **three files and no code**.

```
lib/l10n/app_bn.arb                              the app's own text
android/app/src/main/res/values-bn/strings.xml   what the alarm says
fastlane/metadata/android/bn/                    the F-Droid store listing
```

Add them, and the app follows the phone's language setting with no further
changes. Nothing else should need editing, and nobody should need to be able
to write Dart to contribute a translation.

Three files rather than one because three different things render the text,
and only one of them is Flutter:

- The **app UI** is Flutter, so it uses Flutter's own localisation.
- The **alarm** is deliberately not Flutter. It rings through a native
  Activity and notification so it works when the Flutter engine is not
  running, which means its text comes from Android resources.
- The **store listing** is read by F-Droid from the repository, never by the
  app at all.

## Why ARB, and what it costs

Flutter's standard is ARB — a JSON file per language under `lib/l10n`, with
`flutter gen-l10n` turning them into a lookup class. It is worth using rather
than hand-rolling a `Map<String, String>` for two reasons: Weblate, which is
how translations actually reach a FOSS app, reads ARB natively; and plurals
("1 alarm" against "5 alarms") are a real problem that ARB solves and a plain
map does not.

It has a cost worth stating plainly. It adds `flutter_localizations` and
`intl` to the dependency set, which means:

1. `pubspec.lock` has to be regenerated. CI builds with
   `--enforce-lockfile`, so the build **will fail** until the
   `refresh-lockfile` workflow has been run and its commit merged.
2. It adds a code-generation step to the build. Reproducible builds took six
   releases to get right, and F-Droid compares our APK to theirs byte for
   byte. `gen-l10n` is deterministic, so this should be safe — but "should
   be" has been wrong before on this project.

Because of (2), the migration wants to be its own release, verified on its
own. Do not fold it into a release that also carries alarm fixes.

## The inventory

350 or so distinct strings. The count is unique literals per file, so shared
wording is counted once where it is written.

### Flutter — 328 strings

| File | Strings | Notes |
|---|---:|---|
| `lib/services/oem_service.dart` | 90 | Per-manufacturer battery-settings instructions. The largest single block by far, and the most valuable to translate: it is the text that stops alarms being silently killed. Names like "MIUI" and "HyperOS" stay untranslated. |
| `lib/screens/onboarding_screen.dart` | 56 | First-run explanations of why each permission is needed. |
| `lib/screens/home_screen.dart` | 39 | Map screen, alarm list, and every transient message. Contains the plurals and interpolations listed below. |
| `lib/screens/reliability_screen.dart` | 36 | The "your alarms will not ring" diagnostics and their fixes. |
| `lib/screens/about_screen.dart` | 25 | Includes the Free Palestine section. |
| `lib/screens/settings_screen.dart` | 23 | |
| `lib/screens/location_picker_screen.dart` | 20 | Search, radius, and the speed advice added in 1.7.0. |
| `lib/widgets/alarm_sound_section.dart` | 13 | |
| `lib/widgets/map_tiles.dart` | 11 | Map style names, and the note on why there is no satellite view. |
| `lib/widgets/app_drawer.dart` | 6 | |
| `lib/services/geocoding_service.dart` | 5 | Search failure messages. |
| `lib/main.dart`, `lib/models/place_result.dart`, `lib/services/app_version.dart` | 4 | |

### Android — 30 strings

| File | Strings | Notes |
|---|---:|---|
| `NotificationHelper.kt` | 10 | Channel names and descriptions. These appear in Android's own settings UI, not just ours. |
| `LocationWatchService.kt` | 8 | The ongoing notification: "1 alarm armed", "450 m from Home". Plural and interpolated. |
| `AlarmForegroundService.kt` | 5 | "You're near X", and the joiner between two stops. |
| `MainActivity.kt` | 6 | Mostly channel error messages; only "Test alarm" is user-visible. |
| `AlarmSettings.kt` | 1 | "Custom sound" fallback name. |

Three strings are already in `res/values/strings.xml` and are the model for
the rest.

### Store listing — 4 files

`fastlane/metadata/android/en-US/`: `title.txt`, `short_description.txt`,
`full_description.txt`, and `changelogs/`. F-Droid reads a sibling directory
per locale. Changelogs are per-version and only worth translating going
forward, not retroactively.

## The parts that are not just moving text

**Plurals.** "1 alarm" / "5 alarms" appears in the alarm sheet header and in
the watch notification. Bangla does not inflect plurals the way English
does, and other target languages have more than two forms. These must become
ARB `plural` entries, not string concatenation.

**Interpolation with units.** "450 m from Home" and "1.2 km from Home" put a
number, a unit, and a place name in an order that is not universal. Keep the
whole sentence as one translatable string with named placeholders, never
assembled from fragments.

**Distance formatting.** `formatDistance` picks m against km. The threshold
is fine everywhere, but the decimal separator is not: much of Europe writes
`1,2 km`. This needs `NumberFormat` from `intl`, which the migration pulls in
anyway.

**Right-to-left.** Not needed for Bangla, which is left-to-right. If Arabic
or Urdu is ever added, every hardcoded `EdgeInsets.only(left:)` becomes a bug.
Switching those to `EdgeInsetsDirectional` is cheap to do during the
migration and expensive to retrofit.

**What must not be translated.** Manufacturer and OS names (Xiaomi, MIUI,
HyperOS, Samsung, OnePlus), the Android setting names the instructions tell
users to look for — those appear in English on some ROMs regardless — map
style names that are proper nouns (OpenStreetMap, OpenTopoMap), and the app
name itself.

## Order of work

1. Add the dependencies and run `refresh-lockfile`. Merge that alone, and
   confirm CI is green, before touching a single string.
2. Move the Android strings into `res/values/strings.xml`. Self-contained,
   30 strings, and it does not touch the Flutter build at all.
3. Move the Flutter strings into `lib/l10n/app_en.arb`, file by file. Largest
   first — `oem_service.dart` alone is a quarter of the total.
4. Release, and verify the reproducible build still matches before adding any
   actual translation.
5. Only then add `app_bn.arb` and the rest.

Steps 1 to 4 change no visible behaviour. That is the point: if the English
build looks and reads identically before and after, the migration was clean.
