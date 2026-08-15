<div align="center">

  <img src="store/playstore-icon.png" alt="LocReminder Logo" width="140" />

  <h1>LocReminder</h1>

  <h3>Sleep on the bus. We'll wake you at your stop.</h3>

  <br/>

  <a href="https://github.com/zaifears/locreminder/releases"><img src="https://img.shields.io/badge/📱_Download-APK-34D399?style=for-the-badge" alt="Download APK"/></a>
  <a href="https://github.com/zaifears/locreminder/actions/workflows/build.yml"><img src="https://img.shields.io/badge/🤖_CI-GitHub_Actions-2563EB?style=for-the-badge" alt="CI"/></a>

  <br/><br/>

  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Kotlin-2.0-7F52FF?style=flat-square&logo=kotlin&logoColor=white" alt="Kotlin"/>
  <img src="https://img.shields.io/badge/Android-6.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android"/>
  <img src="https://img.shields.io/badge/OpenStreetMap-No_API_Key-7EBC6F?style=flat-square&logo=openstreetmap&logoColor=white" alt="OpenStreetMap"/>
  <img src="https://img.shields.io/badge/License-Unlicense-green?style=flat-square" alt="License"/>
  <img src="https://github.com/zaifears/locreminder/actions/workflows/build.yml/badge.svg" alt="Build status"/>

  <br/><br/>

  <em>A location alarm that actually rings — even with the app closed and the screen off.</em>

</div>

<br/>

---

<br/>

LocReminder is a **location-based alarm** for Android. Drop a pin on your destination, pick how close you want to get, then put your phone away and rest. When you arrive, it rings a **real alarm** — looping sound on the alarm audio stream, vibration, and a full-screen alert over your lock screen.

No account. No server. No API keys. Your locations never leave your phone.

<br/>

## 📱 Download

<div align="center">
  <br/>
  <a href="https://github.com/zaifears/locreminder/releases">
    <img src="https://img.shields.io/badge/📥_Download_LocReminder-APK-2563EB?style=for-the-badge&logoColor=white" alt="Download APK" />
  </a>
  <br/><br/>
</div>

| | |
|---|---|
| **Latest Release** | `v1.4.0` |
| **Requirements** | Android 6.0+ (API 23) |
| **Size** | ~55 MB |
| **Signing** | Debug-signed by default — see [Release builds](#-building-a-signed-release-apk) |

> Every push to `main` builds an APK you can grab from the [Actions tab](https://github.com/zaifears/locreminder/actions). Pushing a `v*` tag publishes it as a Release.

<br/>

---

<br/>

## 🎯 Why this exists

Most "location alarm" tutorials poll GPS from a Dart `Timer`. That works in the emulator and fails on a real journey: Android kills the app the moment you lock your screen, and the alarm silently never fires.

The second attempt — Android's native geofencing alone — also failed field testing. A geofence was set 150 m away with a 100 m radius; the phone walked into it and stayed 30 seconds. **Nothing.** The alarm rang the instant the app was reopened, because Doze and App Standby had deferred the geofence broadcast until the app became active again.

That is the real problem this project solves.

<br/>

## ⚙️ How it works

```
                     ┌──────────────────┐
                     │   Flutter UI     │  search · pin · radius
                     │  (config only)   │  settings · reliability
                     └────────┬─────────┘
                              │  arms alarm
              ┌───────────────┴───────────────┐
              ▼                               ▼
   ┌────────────────────┐         ┌──────────────────────┐
   │ Foreground watcher │         │  Play Services       │
   │  PRIMARY           │         │  geofence  BACKUP    │
   │  adaptive polling  │         │  + approach ring     │
   └──────────┬─────────┘         └──────────┬───────────┘
              │                              │
              └──────────────┬───────────────┘
                             ▼
                    ARRIVAL DETECTED
                             │
                             ▼
              ┌──────────────────────────┐
              │  Native alarm service    │  ← no Flutter engine needed
              └──────────┬───────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
    alarm-stream     vibration     full-screen UI
       audio                       over lock screen

    watchdog ──► every 15 min, restarts the watcher if an OEM killed it
    boot     ──► restores alarms, geofences and the watcher
```

**Everything that matters is native Kotlin.** The Flutter engine can be completely dead and the app will still detect arrival and ring — that is the design benchmark.

| Layer | Role |
|---|---|
| **Foreground watcher** | Primary trigger. Polls adaptively — 5 min beyond 10 km, 10 s within 500 m. Holding a foreground service is what keeps the process out of the idle state that defers everything. |
| **Approach geofence** | Wide outer ring (8× radius, min 2 km) that wakes the watcher for the final approach — so far-field polling can stay lazy without losing precision. |
| **Inner geofence** | Low-power backup trigger. |
| **Alarm service** | Looping audio on `USAGE_ALARM` (rings on silent), vibration, wake lock, full-screen activity. Auto-stops after 10 minutes. |
| **Watchdog** | Inexact allow-while-idle alarm that restarts the watcher if a vendor power manager killed it. |

<br/>

---

<br/>

## ✨ Features

<table>
  <tr>
    <td width="60"><strong>🔍</strong></td>
    <td><strong>Search, don't hunt</strong></td>
    <td>Type "Kamalapur Railway Station" instead of squinting at a map. Keyless OpenStreetMap geocoding.</td>
  </tr>
  <tr>
    <td><strong>⏰</strong></td>
    <td><strong>A real alarm</strong></td>
    <td>Loops on the alarm audio stream — sounds even on silent — with a full-screen alert over your lock screen.</td>
  </tr>
  <tr>
    <td><strong>📍</strong></td>
    <td><strong>Multiple alarms</strong></td>
    <td>Arm as many destinations as you like, each with its own label and radius. Live distance to each.</td>
  </tr>
  <tr>
    <td><strong>🛡️</strong></td>
    <td><strong>Reliability screen</strong></td>
    <td>Detects your phone's manufacturer and gives the exact settings path for that model, plus a test that proves alarms get through.</td>
  </tr>
  <tr>
    <td><strong>🌙</strong></td>
    <td><strong>Light & dark</strong></td>
    <td>Material 3 throughout, with map tiles tone-mapped for dark mode.</td>
  </tr>
  <tr>
    <td><strong>🔒</strong></td>
    <td><strong>Private by design</strong></td>
    <td>No account, no analytics, no backend. Locations are stored only on your device.</td>
  </tr>
</table>

<br/>

---

<br/>

## 🛡️ Making it reliable on your phone

> **This is the part most location alarms get wrong.** Read it before trusting the app with a real journey.

Android grants the permissions, but **phone manufacturers overrule them.** Xiaomi, Samsung, Oppo, Vivo, OnePlus and Huawei each run their own app-killer on top of Android, and none of them expose an API to opt out — the user has to allow it by hand.

In-app: **Menu → Alarm reliability**. It detects your manufacturer, lists the exact menu path for your model, deep-links to the vendor screen, and offers a **Run alarm test** that rings the real alarm after 15 seconds so you can lock your phone and confirm it breaks through.

| Manufacturer | What to allow |
|---|---|
| **Xiaomi / Redmi / Poco** | Autostart **and** Battery saver → No restrictions |
| **Samsung** | Battery → Background usage limits → **Never sleeping apps** |
| **Oppo / Realme** | Allow Auto-startup + Allow background running |
| **Vivo / iQOO** | High background power consumption + Autostart |
| **OnePlus** | Don't optimise + Auto-launch + disable Advanced optimisation |
| **Huawei / Honor** | App launch → Manage manually → enable all three |

Also required regardless of manufacturer:

- **Location → "Allow all the time"** — with "only while using the app" the alarm can never fire once the screen is off.
- **Battery optimisation off** — with it on, Android postpones the app's location work until you next open it.

<br/>

---

<br/>

## 🛠️ Tech Stack

```
┌─────────────────────────────────────────────────────────────┐
│  UI               Flutter 3 · Dart 3 · Material 3           │
│  Native engine    Kotlin (geofencing, watcher, alarm, boot) │
├─────────────────────────────────────────────────────────────┤
│  Maps             OpenStreetMap via flutter_map — no key    │
│  Search           Nominatim geocoding — no key              │
│  Location         Play Services Geofencing + Fused Location │
├─────────────────────────────────────────────────────────────┤
│  Storage          SharedPreferences (device-local only)     │
│  Build            Gradle 9 · AGP 9 · R8 shrinking           │
│  CI/CD            GitHub Actions → signed release APK       │
└─────────────────────────────────────────────────────────────┘
```

<br/>

---

<br/>

## 🚀 Local Development

### Prerequisites

- **[Flutter SDK](https://flutter.dev/docs/get-started/install)** (stable channel)
- **[Android SDK](https://developer.android.com/studio)** + **JDK 17**

No Maps API key, no Google Cloud billing account, no signup — the map is OpenStreetMap.

### Quick Start

```bash
# 1. Clone & enter
git clone https://github.com/zaifears/locreminder.git
cd locreminder

# 2. Install dependencies
flutter pub get

# 3. Run it
flutter run --release
```

> `--release` is recommended even for testing — geofencing and background location behave closest to real-world conditions in a release build.

> **App icons** under `android/app/src/main/res/mipmap-*` are hand-authored and committed as-is. Do **not** run `flutter_launcher_icons`; it would regenerate and overwrite them.

### Available Scripts

| Command | Description |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter analyze` | Static analysis (CI treats warnings as failures) |
| `flutter test` | Run unit tests |
| `flutter run --release` | Run on a connected device |
| `flutter build apk --release` | Build release APK |

<br/>

---

<br/>

## 📦 Building a signed release APK

Release builds fall back to Android's debug key, so `flutter build apk --release` always produces an installable APK. For a real production signature:

```bash
keytool -genkey -v -keystore locreminder-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias locreminder
```

```bash
cp android/key.properties.example android/key.properties
```

Fill in your keystore path and passwords (git-ignored), then build. The APK lands in `build/app/outputs/flutter-apk/app-release.apk`.

### CI secrets

| Secret | Required for |
|---|---|
| `RELEASE_KEYSTORE_BASE64` | Signing with your real key (`base64 -w0 locreminder-release.jks`) |
| `RELEASE_STORE_PASSWORD` | ″ |
| `RELEASE_KEY_ALIAS` | ″ |
| `RELEASE_KEY_PASSWORD` | ″ |

None are required for CI to build — omitted secrets simply produce a debug-signed APK.

<br/>

---

<br/>

## 🤝 Contributing

Contributions are welcome — fork, branch, commit, and open a pull request.

1. **Fork the project**
2. **Create your feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a pull request**

<br/>

## 📄 License

Released into the **public domain** under the [Unlicense](UNLICENSE) — use, modify and distribute it for any purpose, without restriction.

Map data and search © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors, available under the Open Database License.

<br/>

---

<br/>

<div align="center">

  <strong>🚏 Never miss your stop again.</strong>

  <br/><br/>

  <a href="https://github.com/zaifears/locreminder/releases">Download</a> &nbsp;·&nbsp; <a href="https://github.com/zaifears/locreminder/issues">Report Issue</a> &nbsp;·&nbsp; <a href="https://shahoriar.bd/">Website</a> &nbsp;·&nbsp; <a href="mailto:shahoriar.connect@gmail.com">Contact</a>

  <br/><br/>

  <sub>Built with ❤️ by <a href="https://github.com/zaifears">Shahoriar Hossain</a></sub>

</div>
