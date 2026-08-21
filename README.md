<div align="center">

  <img src="store/playstore-icon.png" alt="LocReminder Logo" width="140" />

  <h1>LocReminder</h1>

  <h3>An alarm that rings when you <em>arrive</em>, not at a set time</h3>

  <p><em>Sleep on the bus. Read your book. We'll wake you at your stop.</em></p>

  <br/>

  <a href="#-download"><img src="https://img.shields.io/badge/⬇️_Download-APK-2563EB?style=for-the-badge&logo=android&logoColor=white" alt="Download"/></a>
  <a href="#-how-to-use-it"><img src="https://img.shields.io/badge/📖_How_to-Use_it-475569?style=for-the-badge" alt="How to use"/></a>

</div>

<br/>

---

<br/>

## 🛡️ Safe to install — and here's the proof

Anyone can *claim* an app is safe. These are the parts you can check yourself.

<div align="center">
  <br/>
  <a href="docs/SECURITY-SCAN.md">
    <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fzaifears%2Flocreminder%2Fmain%2F.github%2Fbadges%2Fvirustotal.json&style=for-the-badge&logo=virustotal&logoColor=white&labelColor=394EFF" alt="VirusTotal scan result" height="32"/>
  </a>
  &nbsp;&nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-16A34A?style=for-the-badge" alt="MIT licensed" height="32"/></a>
  &nbsp;&nbsp;
  <img src="https://img.shields.io/badge/Trackers-none-7C3AED?style=for-the-badge" alt="No trackers" height="32"/>
  <br/><br/>
</div>

| | | |
|---|---|---|
| 🔬 | **Scanned by VirusTotal** | Every release is checked by ~70 antivirus engines **before** it's published — a build that looks like malware never reaches you. [See every scan, with checksums →](docs/SECURITY-SCAN.md) |
| ✍️ | **Signed and verifiable** | Each release carries LocReminder's own signature, and its SHA-256 checksum is published so you can confirm your download is the exact file that was scanned. |
| 👀 | **Open source, all of it** | Every line is public and MIT licensed. Nothing is hidden, and you can build it yourself from the same source. |
| 🚫 | **No tracking, no accounts, no server** | No analytics, no ads, no sign-up. There is nowhere for your locations to go — they never leave your phone. |
| 🧩 | **No Google Play Services** | Runs on de-Googled phones, Huawei/HMS devices and LineageOS. Maps come from OpenStreetMap. |

<br/>

<details>
<summary><strong>What's inside it</strong> (click to expand)</summary>

<br/>

| Part | What it uses |
|---|---|
| **App** | Flutter 3 · Dart 3 · Material 3 |
| **Alarm engine** | Native Kotlin — keeps working with the app fully closed |
| **Maps & search** | OpenStreetMap + Nominatim — no API key, no Google |
| **Location** | Android's own `LocationManager` — no Play Services |
| **Your data** | Stored on your device only, in Android's private app storage |

</details>

<br/>

---

<br/>

## 📱 Download

<div align="center">
  <br/>
  <a href="https://github.com/zaifears/locreminder/releases/latest/download/app-release.apk">
    <img src="https://img.shields.io/badge/⬇️_Download_the_latest_APK-2563EB?style=for-the-badge&logo=android&logoColor=white" alt="Download APK" height="38"/>
  </a>
  <br/><br/>
  <img src="https://img.shields.io/badge/📥_Also_coming_to_F--Droid-9E9E9E?style=for-the-badge&logo=fdroid&logoColor=white" alt="F-Droid: coming soon" height="28"/>
  <br/><br/>
</div>

| | |
|---|---|
| **Latest version** | `v1.6.7` — see [what changed](CHANGELOG.md) |
| **Works on** | Android 6.0 or newer |
| **Size** | About 53 MB |
| **Price** | Free. No ads, no accounts, no in-app purchases. |

**Installing an APK:** open the downloaded file and Android will ask permission to install from your browser or file manager. That prompt is normal for any app installed outside the Play Store — allow it once, and you're done.

> ⚠️ **Already have an older LocReminder from GitHub (before v1.6.6)?** Uninstall it first — those builds were signed with a different key by mistake, and Android won't replace one with the other. Your saved alarms will be lost in the swap. Sorry about that; it only affects this one upgrade.

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

<br/>

> ### ⚡ Do this before your first real journey
>
> Open **Menu → Alarm reliability** and tap **Run alarm test**. It rings the alarm after 15 seconds, so you can lock your phone and confirm it gets through.
>
> Much better to find out at home than on a train.

<br/>

---

<br/>

## 🚏 Why it exists

You know roughly *where* you're going, but not exactly *when* you'll get there — traffic, delays, and unfamiliar routes make that impossible to predict. So you can't set a normal alarm. Instead you spend the whole journey glancing out of the window, unable to properly rest or focus.

LocReminder fixes that. Drop a pin on your destination, choose how close you want to get, and put your phone away. When you arrive, it **rings a real alarm** — a looping sound that plays even on silent, vibration, and a full-screen alert over your lock screen. Exactly like a morning alarm, except triggered by arriving somewhere.

| | |
|---|---|
| 😴 **Long bus or train rides** | Actually sleep, instead of half-watching for your stop. |
| 🌏 **An unfamiliar city** | You don't know what your stop looks like — so let the phone know for you. |
| 📚 **Commuters** | Read, work, or listen to something without keeping one eye on the route. |
| 🚗 **Passengers on road trips** | Get woken before the turn-off instead of 20 km past it. |
| 📦 **Pickups and errands** | A nudge when you're near the shop, the post office, or a friend's place. |

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
    <td><strong>🔊</strong></td>
    <td><strong>Your own alarm sound</strong></td>
    <td>Any system ringtone, or an audio file of your own.</td>
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
| **Huawei / Honor** | App launch → Manage manually, all three switches on |
| **Google, Motorola, Sony, Nokia, Nothing, Fairphone** | Nothing extra — stock Android respects the standard settings |

<br/>

---

<br/>

<div align="center">

### 👩‍💻 For developers

<sub>Everything below is about building and contributing to LocReminder.<br/>If you just want to use the app, you're all set.</sub>

</div>

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
                              ▼
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
| **Foreground watcher** | The whole detection mechanism. Polls adaptively — 5 min beyond 10 km, 10 s within 500 m. Holding a foreground service keeps the process out of the idle state that defers everything else. Ignores fixes too imprecise to confirm arrival, so a coarse cell-tower fix can't ring the alarm kilometres early. |
| **Alarm service** | Looping `USAGE_ALARM` audio, vibration, wake lock, full-screen activity. Auto-stops after 10 minutes. |
| **Watchdog** | Inexact allow-while-idle alarm. Restarts the watcher if a vendor power manager killed it, or if it is running but receiving no fixes — the state left behind when location is switched off at the OS level. |
| **Boot receiver** | Restores alarms and the watcher after a restart. |

</details>

<br/>

### Built with

```
┌─────────────────────────────────────────────────────────────┐
│  UI               Flutter 3 · Dart 3 · Material 3           │
│  Native engine    Kotlin (watcher, alarm, watchdog, boot)   │
├─────────────────────────────────────────────────────────────┤
│  Maps             OpenStreetMap via flutter_map — no key    │
│  Search           Nominatim geocoding — no key              │
│  Location         Platform LocationManager — no Play Services│
├─────────────────────────────────────────────────────────────┤
│  Storage          SharedPreferences (device-local only)     │
│  Build            Gradle 9 · AGP 9 · R8 shrinking           │
│  CI/CD            GitHub Actions → signed, scanned release  │
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

### Signing

For local builds, signing falls back to Android's debug key so `flutter build apk --release` always produces something installable. To sign with your own key instead:

```bash
keytool -genkey -v -keystore locreminder-release.jks -keyalg RSA \
  -keysize 4096 -validity 10000 -alias locreminder
cp android/key.properties.example android/key.properties
```

Fill in your keystore path and passwords — `key.properties` is git-ignored.

> **Published releases are different.** Tagged builds refuse to publish unless all four of `RELEASE_KEYSTORE_BASE64`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_ALIAS` and `RELEASE_KEY_PASSWORD` are set as repository secrets, and CI reads the certificate back out of the finished APK to prove the debug key wasn't used. That check exists because the fallback is silent, and every release up to v1.6.5 shipped debug-signed without anything complaining.

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

  <a href="https://github.com/zaifears/locreminder/releases/latest/download/app-release.apk">Download</a> &nbsp;·&nbsp; <a href="https://github.com/zaifears/locreminder/issues">Report an issue</a> &nbsp;·&nbsp; <a href="https://shahoriar.bd/">Website</a> &nbsp;·&nbsp; <a href="mailto:shahoriar.connect@gmail.com">Contact</a>

  <br/><br/>

</div>
