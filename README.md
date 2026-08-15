# 📍 LocReminder

Never miss your stop. Set an alarm on a destination and LocReminder rings —
a real, looping, full-screen alarm — when you get close, even if the app is
closed or your phone has been sitting untouched for hours.

---

### How it actually works

Most "background location" tutorials use a `Timer` that polls GPS every few
seconds from Dart. That only runs while the app process is alive, which
Android will kill the moment you swipe the app away or the screen has been
off for a while — so the alarm silently stops working. LocReminder doesn't
do that.

```
Your PC                                    Phone
  │                                          │
  ├── VS Code / Flutter                      ├── Android's native Geofencing API
  ├── GitHub Actions (CI build)               │      (Play Services, OS-managed)
  └── location-alarm.apk ────────────────────►      │
                                              ▼
                                     Phone moves normally
                                              │
                                     Entered the radius?
                                              │ yes
                                              ▼
                                  BroadcastReceiver (native, no
                                  Flutter engine required)
                                              │
                                              ▼
                                  Foreground alarm service:
                                  loops sound on STREAM_ALARM,
                                  vibrates, wakes the screen,
                                  shows a full-screen "Stop" UI
                                              │
                                              ▼
                                        🔊 ALARM RINGS
```

* Destinations are registered with Android's **native Geofencing API**
  (`GeofencingClient`), not a Dart timer — the OS itself watches your
  location efficiently and wakes your app's receiver on arrival, whether or
  not the app is running.
* The alarm — sound, vibration, full-screen lock-screen UI, "Stop" button —
  is entirely native Kotlin (`AlarmForegroundService` + `AlarmActivity`).
  It works even if the Flutter engine isn't currently loaded.
* Geofences are re-registered automatically after a device reboot
  (`BootReceiver`), since Android drops them on restart.
* Flutter is only used for the setup UI: picking a destination on the map,
  naming it, choosing a radius, and managing your list of alarms.

---

### ✨ Features

* Drop a pin (or several) on the map with a custom label and radius.
* Real background geofencing via Android's own Geofencing API — efficient,
  no polling, no foreground service required just to "watch".
* A loud, looping alarm on the dedicated alarm audio stream (rings even on
  silent/vibrate), full-screen lock-screen alert, and vibration.
* Multiple independent alarms, each toggleable or deletable.
* Guided permission onboarding (location, background location,
  notifications, battery-optimization exemption).
* Signed, installable release APK built automatically by GitHub Actions.

---

### 🛠️ Built with

* **Flutter / Dart** — map UI, alarm list, permission onboarding.
* **Kotlin** — geofence registration, the alarm foreground service, and the
  full-screen alarm activity (`android/app/src/main/kotlin/...`).
* **OpenStreetMap via `flutter_map`** — destination picking. No API key, no
  billing account, no Google Cloud project required.
* **Play Services Geofencing API** (`com.google.android.gms:play-services-location`)
  — free, no API key needed (this is a device-side location API, not Maps).

---

### 🚀 Getting started

#### Prerequisites

* [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
* [Android SDK](https://developer.android.com/studio) + a JDK 17

No Maps API key, no Google Cloud billing account, no signup of any kind —
the map is OpenStreetMap tiles, free and keyless.

#### 1. Clone and install dependencies

```sh
git clone https://github.com/zaifears/locreminder.git
cd locreminder
flutter pub get
```

#### 2. Generate the launcher icon

```sh
dart run flutter_launcher_icons
```

#### 3. Run it

```sh
flutter run --release
```

(`--release` is recommended even for testing, since geofencing/background
location behaves closest to real-world conditions in a release build.)

---

### 📦 Building a signed release APK

By default, release builds fall back to Android's debug signing key, so
`flutter build apk --release` always works out of the box and produces an
APK you can sideload. For a real production signature (recommended before
distributing the app):

```sh
keytool -genkey -v -keystore locreminder-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias locreminder
```

```sh
cp android/key.properties.example android/key.properties
```

Fill in `android/key.properties` with your keystore path and passwords
(also git-ignored). Then:

```sh
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

---

### 🤖 CI: GitHub Actions builds the APK for you

`.github/workflows/build.yml` builds a release APK on every push to `main`
and on version tags (`v1.0.0`, etc.), then uploads it as a workflow artifact
— and attaches it to a GitHub Release when you push a tag. This mirrors the
exact pipeline used during development: **push → GitHub Actions → Flutter
build → Android SDK/Gradle → `location-alarm.apk`**.

To have CI sign the APK with your real release key rather than the debug
key, add these repository secrets (Settings → Secrets and variables →
Actions):

| Secret | Required for |
|---|---|
| `RELEASE_KEYSTORE_BASE64` | Signing with your real release key (`base64 -w0 locreminder-release.jks`) |
| `RELEASE_STORE_PASSWORD` | ″ |
| `RELEASE_KEY_ALIAS` | ″ |
| `RELEASE_KEY_PASSWORD` | ″ |

None of these are required for CI to *build* — omitted secrets just mean a
debug-signed APK, still fully installable by sideloading.

---

### 📱 Installing on your phone

1. Download `app-release.apk` from a GitHub Actions run (or a Release, if
   you pushed a tag) onto your phone.
2. Open it — Android will prompt to allow installs from that source once.
3. Install, open the app, and complete the permission setup screen. Make
   sure to choose **"Allow all the time"** for location when prompted, and
   disable battery optimization for LocReminder when asked — both are
   required for the alarm to reliably fire in the background.

---

### 🤝 Contributing

Contributions are welcome — fork, branch, commit, and open a pull request.

1. **Fork the project**
2. **Create your feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a pull request**

---

### 📜 License

This project is unlicensed and free to the public — public domain. Use,
modify, and distribute it for any purpose without restriction.

---

### 📬 Contact

zaifears - [@shahoriar](https://shahoriar.me) - shahoriar.connect@gmail.com

Project Link: [https://github.com/zaifears/locreminder](https://github.com/zaifears/locreminder)
