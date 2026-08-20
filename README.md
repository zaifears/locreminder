<div align="center">

  <img src="store/playstore-icon.png" alt="LocReminder Logo" width="140" />

  <h1>LocReminder</h1>

  <h3>A location alarm that rings when you reach your destination</h3>

  <br/>

  <a href="#-download"><img src="https://img.shields.io/badge/📱_Get_it_on-F--Droid-1976D2?style=for-the-badge&logo=fdroid&logoColor=white" alt="Get it on F-Droid"/></a>
  <a href="#-how-to-use-it"><img src="https://img.shields.io/badge/📖_How_to-Use_it-2563EB?style=for-the-badge" alt="How to use"/></a>

  <br/><br/>

  <img src="https://img.shields.io/badge/Android-6.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android"/>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Kotlin-2.0-7F52FF?style=flat-square&logo=kotlin&logoColor=white" alt="Kotlin"/>
  <img src="https://img.shields.io/badge/Maps-OpenStreetMap-7EBC6F?style=flat-square&logo=openstreetmap&logoColor=white" alt="OpenStreetMap"/>
  <img src="https://img.shields.io/badge/100%25-FOSS-blue?style=flat-square" alt="FOSS"/>
  <img src="https://img.shields.io/badge/No_Ads-No_Tracking-blueviolet?style=flat-square" alt="No ads"/>
  <img src="https://img.shields.io/badge/Code-MIT-green?style=flat-square" alt="License"/>

  <br/><br/>

  <em>Sleep on the bus. Read your book. We'll wake you at your stop.</em>

</div>

<br/>

---

<br/>

## 🚏 What is LocReminder?

**LocReminder is an alarm clock that goes off at a place instead of a time.**

You know roughly *where* you're going, but not exactly *when* you'll get there — traffic, delays, and unfamiliar routes make that impossible to predict. So you can't set a normal alarm. Instead you spend the whole journey glancing out of the window, unable to properly rest or focus.

LocReminder fixes that. Drop a pin on your destination, choose how close you want to get, and put your phone away. When you arrive, it **rings a real alarm** — a looping sound that plays even on silent, vibration, and a full-screen alert over your lock screen. Exactly like a morning alarm, except triggered by arriving somewhere.

<br/>

### Who it's for

| | |
|---|---|
| 😴 **Long bus or train rides** | Actually sleep, instead of half-watching for your stop. |
| 🌏 **An unfamiliar city** | You don't know what your stop looks like — so let the phone know for you. |
| 📚 **Commuters** | Read, work, or listen to something without keeping one eye on the route. |
| 🚗 **Passengers on road trips** | Get woken before the turn-off instead of 20 km past it. |
| 📦 **Pickups and errands** | A nudge when you're near the shop, the post office, or a friend's place. |

<br/>

> **The one thing it must do is ring.** An alarm that only works when you happen to be looking at your phone is useless — so most of the engineering here went into making it fire reliably with the app closed and the screen off. See [Making sure it rings](#️-making-sure-it-rings).

<br/>

---

<br/>

## 📱 Download

**LocReminder is on its way to F-Droid**, the free and open-source Android
app store — submission is in review. Until that listing goes live, grab
the APK directly below.

<div align="center">
  <br/>
  <a href="https://github.com/zaifears/locreminder/raw/main/apk/locreminder.apk">
    <img src="https://img.shields.io/badge/⬇️_Download-APK-2563EB?style=for-the-badge&logo=android&logoColor=white" alt="Download APK" />
  </a>
  &nbsp;
  <img src="https://img.shields.io/badge/📥_F--Droid-Coming_soon-9E9E9E?style=for-the-badge&logo=fdroid&logoColor=white" alt="F-Droid: coming soon" />
  <br/><br/>
</div>

| | |
|---|---|
| **Latest release** | `v1.6.4` |
| **Requirements** | Android 6.0 or newer |
| **Price** | Free. No ads, no accounts, no in-app purchases, no tracking. |

> ⚠️ **This APK is a test build, signed with a different key from the
> eventual F-Droid version.** Once F-Droid is live, installing from there
> will require uninstalling this one first (losing your saved alarms).
> Full release notes: [CHANGELOG.md](CHANGELOG.md).

<br/>

---

<br/>

## 📖 How to use it

<table>
  <tr>
    <td width="70" align="center"><h2>1</h2></td>
    <td><strong>Search for where you're going</strong><br/><sub>Type a place name, or drag the map under the pin. No account needed.</sub></td>
  </tr>
  <tr>
    <td align="center"><h2>2</h2></td>
    <td><strong>Choose how early to be woken</strong><br/><sub>Anywhere from 100 m to 3 km out. A bigger radius gives you more time to gather your things.</sub></td>
  </tr>
  <tr>
    <td align="center"><h2>3</h2></td>
    <td><strong>Put your phone away and rest</strong><br/><sub>A quiet notification shows how far you have left. When you arrive, the alarm rings.</sub></td>
  </tr>
</table>

**Before your first real journey**, open **Menu → Alarm reliability** and tap **Run alarm test**. It rings the alarm after 15 seconds so you can lock your phone and confirm it gets through. Better to find out at home than on a train.

<br/>

---

<br/>

## ✨ Features

<table>
  <tr>
    <td width="60"><strong>⏰</strong></td>
    <td><strong>A real alarm, not a notification</strong></td>
    <td>Loops on the alarm audio stream, so it sounds even when your phone is on silent — with a full-screen alert over your lock screen and a big Stop button.</td>
  </tr>
  <tr>
    <td><strong>🔍</strong></td>
    <td><strong>Search by name</strong></td>
    <td>Type "Kamalapur Railway Station" instead of hunting across the map for it.</td>
  </tr>
  <tr>
    <td><strong>📍</strong></td>
    <td><strong>As many alarms as you like</strong></td>
    <td>Each with its own label and radius. Pause one without deleting it, and see live distance to each.</td>
  </tr>
  <tr>
    <td><strong>🔋</strong></td>
    <td><strong>Easy on the battery</strong></td>
    <td>Checks rarely when you're far away and often as you get close, so a three-hour journey doesn't flatten your phone.</td>
  </tr>
  <tr>
    <td><strong>🛡️</strong></td>
    <td><strong>Reliability check</strong></td>
    <td>Detects your phone's brand and shows the exact settings it needs, plus a test that proves the alarm gets through.</td>
  </tr>
  <tr>
    <td><strong>🌙</strong></td>
    <td><strong>Light and dark themes</strong></td>
    <td>Material 3 throughout, with map tiles tuned so dark mode isn't a white rectangle at night.</td>
  </tr>
  <tr>
    <td><strong>🔒</strong></td>
    <td><strong>Genuinely private</strong></td>
    <td>No account, no analytics, no server. There's nowhere for your locations to go — they stay on your phone.</td>
  </tr>
</table>

<br/>

---

<br/>

## 🛡️ Making sure it rings

> **Please read this once.** It's the difference between an alarm that works and one that doesn't.

Android lets apps ask for permission to run in the background — but **phone manufacturers overrule it.** Xiaomi, Samsung, Oppo, Vivo, OnePlus and Huawei each add their own app-killer, and no app can switch those off by itself. You have to allow it by hand, once.

**Menu → Alarm reliability** detects your phone and walks you through it. For reference:

| Your phone | What to allow |
|---|---|
| **Xiaomi / Redmi / Poco** | Autostart **and** Battery saver → No restrictions |
| **Samsung** | Battery → Background usage limits → **Never sleeping apps** |
| **Oppo / Realme** | Allow Auto-startup + Allow background running |
| **Vivo / iQOO** | High background power consumption + Autostart |
| **OnePlus** | Don't optimise + Auto-launch + turn off Advanced optimisation |
| **Huawei / Honor** | App launch → Manage manually → enable all three |

And on every phone, regardless of brand:

- **Location → "Allow all the time".** With *"only while using the app"*, the alarm can never fire once your screen is off.
- **Battery optimisation → off.** With it on, Android postpones the app's work until you next open it — the alarm stays silent all journey, then goes off the moment you unlock your phone.

<br/>

---

<br/>

## 🔧 Under the hood

<details>
<summary><strong>How the alarm actually survives a locked screen</strong> (click to expand)</summary>

<br/>

The usual approach — polling GPS from a Dart `Timer` — works in an emulator and fails on a real trip, because Android kills the app as soon as you lock the screen.

Android's native geofencing alone also failed field testing. An alarm was set 150 m away with a 100 m radius; the phone walked in and waited 30 seconds. Nothing. It rang the instant the app was reopened, because Doze had **deferred** the geofence broadcast until the app became active.

Geofencing was therefore dropped entirely in favour of a foreground service that watches location itself. The alarm is native Kotlin — the Flutter engine can be completely dead and it still rings — and the app uses only platform APIs, so it needs no Google Play Services and works on de-Googled and HMS-only devices.

```
                     ┌──────────────────┐
                     │   Flutter UI     │  search · pin · radius
                     │  (config only)   │  settings · reliability
                     └────────┬─────────┘
                              │  arms alarm
              ┌───────────────┴───────────────┐
              ▼                               ▼
              ┌──────────────────────────────┐
              │  Foreground location watcher │
              │  platform LocationManager    │
              │  adaptive polling            │
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
```

| Layer | Role |
|---|---|
| **Foreground watcher** | The whole detection mechanism. Polls adaptively — 5 min beyond 10 km, 10 s within 500 m. Holding a foreground service keeps the process out of the idle state that defers everything else. |
| **Alarm service** | Looping `USAGE_ALARM` audio, vibration, wake lock, full-screen activity. Auto-stops after 10 minutes. |
| **Watchdog** | Inexact allow-while-idle alarm, restarts the watcher if a vendor power manager killed it. |
| **Boot receiver** | Restores alarms, geofences and the watcher after a restart. |

</details>

<br/>

### Built with

```
┌─────────────────────────────────────────────────────────────┐
│  UI               Flutter 3 · Dart 3 · Material 3           │
│  Native engine    Kotlin (geofencing, watcher, alarm, boot) │
├─────────────────────────────────────────────────────────────┤
│  Maps             OpenStreetMap via flutter_map — no key    │
│  Search           Nominatim geocoding — no key              │
│  Location         Platform LocationManager — no Play Services│
├─────────────────────────────────────────────────────────────┤
│  Storage          SharedPreferences (device-local only)     │
│  Build            Gradle 9 · AGP 9 · R8 shrinking           │
│  CI/CD            GitHub Actions → release APK              │
└─────────────────────────────────────────────────────────────┘
```

<br/>

---

<br/>

## 🚀 Building it yourself

### Prerequisites

- **[Flutter SDK](https://flutter.dev/docs/get-started/install)** (stable channel)
- **[Android SDK](https://developer.android.com/studio)** + **JDK 17**

No Maps API key, no Google Cloud billing account, no signup — the map is OpenStreetMap.

```bash
git clone https://github.com/zaifears/locreminder.git
cd locreminder
flutter pub get
flutter run --release
```

> `--release` is recommended even for testing — background location behaves closest to real conditions in a release build.

> **App icons** under `android/app/src/main/res/mipmap-*` are hand-authored and committed as-is. Don't run `flutter_launcher_icons`; it would overwrite them.

### Commands

| Command | Description |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter analyze` | Static analysis (CI treats warnings as failures) |
| `flutter test` | Run unit tests |
| `flutter build apk --release` | Build a release APK |

### Signing a release build

Release builds fall back to Android's debug key, so `flutter build apk --release` always produces an installable APK. For a production signature:

```bash
keytool -genkey -v -keystore locreminder-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias locreminder
cp android/key.properties.example android/key.properties
```

Fill in your keystore path and passwords (git-ignored). For CI, add `RELEASE_KEYSTORE_BASE64`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_ALIAS` and `RELEASE_KEY_PASSWORD` as repository secrets — none are required to build, they only change the signature.

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

| | |
|---|---|
| **Source code** | [MIT](LICENSE) — free to use, modify, and distribute, commercially or otherwise |
| **Logo, app icon & the name "LocReminder"** | © Shahoriar Hossain — all rights reserved |

Fork the code freely. Please use your own name and artwork when publishing a derivative.

Map data and search © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors, under the Open Database License.

<br/>

---

<br/>

<div align="center">

  <strong>🚏 Never miss your stop again.</strong>

  <br/><br/>

  <a href="https://github.com/zaifears/locreminder/releases">Download</a> &nbsp;·&nbsp; <a href="https://github.com/zaifears/locreminder/issues">Report an issue</a> &nbsp;·&nbsp; <a href="https://shahoriar.bd/">Website</a> &nbsp;·&nbsp; <a href="mailto:shahoriar.connect@gmail.com">Contact</a>

  <br/><br/>

  <sub>Built with ❤️ by <a href="https://github.com/zaifears">Shahoriar Hossain</a></sub>

</div>
