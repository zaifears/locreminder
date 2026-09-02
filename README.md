<div align="center">

  <img src="https://i.ibb.co.com/xK4dptyr/icon.png" alt="LocReminder Logo" width="140" />

  <h1>LocReminder</h1>

  <h3>Reminds you at the right place</h3>

  <p><em>Sleep on the bus. Remember the errand. It goes off when you arrive.</em></p>

  <br/>

  <a href="https://github.com/zaifears/locreminder/releases/latest/download/app-release.apk">
    <img src="https://i.ibb.co.com/WNGyLFhY/Download-from-Github.png" alt="Download APK directly from GitHub" height="56"/>
  </a>
  <br/><br/>
  <a href="https://locreminder.en.uptodown.com/android" title="Download LocReminder">
    <img src="https://stc.utdstc.com/img/mediakit/download-gio-big-b.png" alt="Download LocReminder" height="46"/>
  </a>
  &nbsp;&nbsp;
  <a href="https://gitlab.com/fdroid/fdroiddata/-/merge_requests/46299" title="Track the F-Droid submission">
    <img src="https://i.ibb.co.com/HTcdVbNr/Coming-to-F-droid.png" alt="Coming to F-Droid" height="46"/>
  </a>

  <br/><br/>

  <a href="https://gitlab.com/fdroid/fdroiddata/-/merge_requests/46299"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fzaifears%2Flocreminder%2Fmain%2F.github%2Fbadges%2Ffdroid.json&style=flat-square&logo=fdroid&logoColor=white" alt="F-Droid status"/></a>

  <br/><br/>

  <a href="#-how-to-use-it"><img src="https://img.shields.io/badge/📖_How_to-Use_it-475569?style=for-the-badge" alt="How to use"/></a>

  <br/><br/>

  <img src="https://img.shields.io/badge/Android-6.0%2B-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android"/>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Kotlin-2.0-7F52FF?style=flat-square&logo=kotlin&logoColor=white" alt="Kotlin"/>
  <img src="https://img.shields.io/badge/Maps-OpenStreetMap-7EBC6F?style=flat-square&logo=openstreetmap&logoColor=white" alt="OpenStreetMap"/>
  <br/>
  <a href="docs/SECURITY-SCAN.md"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fzaifears%2Flocreminder%2Fmain%2F.github%2Fbadges%2Fvirustotal.json&style=flat-square&logo=virustotal&logoColor=white" alt="VirusTotal scan result"/></a>
  <img src="https://img.shields.io/badge/100%25-FOSS-blue?style=flat-square" alt="FOSS"/>
  <img src="https://img.shields.io/badge/No_Ads-No_Tracking-blueviolet?style=flat-square" alt="No ads, no tracking"/>
  <a href="LICENSE"><img src="https://img.shields.io/badge/Code-MIT-green?style=flat-square" alt="MIT licensed"/></a>

</div>

<br/>

---

<br/>

## 📱 Download

| | |
|---|---|
| **Latest version** | `v1.9.2`, see [what changed](CHANGELOG.md) |
| **Works on** | Android 6.0 or newer |
| **Size** | 53 MB (universal), or about 16-20 MB if you pick a device-matched build (see below) |
| **Price** | Free. No ads, no accounts, no in-app purchases. |
| **F-Droid** | [![F-Droid status](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fzaifears%2Flocreminder%2Fmain%2F.github%2Fbadges%2Ffdroid.json&style=flat-square&logo=fdroid&logoColor=white)](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/46299) — this badge tracks the submission live, no need to keep checking back |

**What's new in v1.9.2.** The alarm could ring several minutes late when GPS accuracy stayed poor near your stop — an elevated rail platform or a covered station being the clearest case. It now trusts a fix that has consistently placed you inside the radius for a short while, instead of holding out indefinitely for a sharper one. If you're on an older version, this update is worth grabbing. See the [changelog](CHANGELOG.md) for the full history.

**Installing an APK.** Open the downloaded file and Android will ask for permission to install from your browser or file manager. That prompt is normal for any app installed outside the Play Store. Allow it once and you are done.

**Smaller downloads.** The GitHub button at the top of the page downloads the universal APK (53 MB), which works on any Android device. The [GitHub Release page](https://github.com/zaifears/locreminder/releases/latest) also has architecture-specific builds, about 16-20 MB each. If you want a smaller download, pick `app-arm64-v8a-release.apk` (right for almost all phones made after 2015). F-Droid users get the right-sized APK automatically, no choice needed.

**Prefer auto-updates?** LocReminder is also on [Uptodown](https://locreminder.en.uptodown.com/android). Install it through their app store client (or just the APK from the page) and you will not have to come back here for every new version, the same convenience F-Droid will offer once it lands.

> ⚠️ **Already have an older LocReminder from GitHub, from before v1.6.6?** Please uninstall it first. Those builds went out signed with the wrong key by mistake, and Android will not replace one with the other. Your saved alarms will be lost in the swap. Sorry about that. It only affects this one upgrade.

<br/>

---

<br/>

## 📖 How to use it

<table>
  <tr>
    <td width="70" align="center"><h2>1</h2></td>
    <td><strong>Search for where you are going</strong><br/><sub>Type a place name, or drag the map under the pin. No account needed.</sub></td>
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
> Open **Menu → Alarm reliability** and tap **Run alarm test**. It rings the alarm after 15 seconds, so you can lock your phone and check that it gets through.
>
> Much better to find out at home than on a train.

<br/>

---

<br/>

## 🛡️ Safe to install

| | | |
|---|---|---|
| 🔬 | **Scanned by VirusTotal** | Every release gets checked by around 70 antivirus engines before it is published, so a build that looks like malware never reaches you. [See every scan, with checksums](docs/SECURITY-SCAN.md) |
| ✍️ | **Signed and verifiable** | Each release carries LocReminder's own signature, and its SHA-256 checksum is published so you can confirm your download is the exact file that was scanned. |
| 👀 | **Open source, all of it** | Every line is public and MIT licensed. Nothing is hidden, and you can build the app yourself from the same source. |
| 🚫 | **No tracking, no accounts, no server** | No analytics, no ads, no sign up. There is nowhere for your locations to go, so they never leave your phone. |
| 🧩 | **No Google Play Services** | Runs fine on de-Googled phones, Huawei and Honor devices, and LineageOS. Maps come from OpenStreetMap. |

<br/>

---

<br/>

## 🚏 Why it exists

You know roughly where you are going, but not exactly when you will get there. Traffic, delays and unfamiliar routes make that impossible to predict, so a normal alarm is no use. Instead you spend the whole journey glancing out of the window, unable to properly rest or focus.

LocReminder fixes that. Drop a pin on your destination, choose how close you want to get, and put your phone away. When you arrive it rings a real alarm: a looping sound that plays even on silent, vibration, and a full screen alert over your lock screen. Just like a morning alarm, except that arriving somewhere is what sets it off.

| | |
|---|---|
| 😴 **Long bus or train rides** | Actually sleep, instead of half watching for your stop. |
| 🌏 **An unfamiliar city** | You do not know what your stop looks like, so let the phone know for you. |
| 📚 **Commuters** | Read, work or listen to something without keeping one eye on the route. |
| 🚗 **Passengers on road trips** | Get woken before the turn off instead of 20 km past it. |
| 📦 **Pickups and errands** | A nudge when you are near the shop, the post office, or a friend's place. |

<br/>

---

<br/>

## ✨ Features

<table>
  <tr>
    <td width="60"><strong>⏰</strong></td>
    <td><strong>A real alarm, not a notification</strong></td>
    <td>Loops on the alarm audio stream, so it sounds even when your phone is on silent. It shows a full screen alert over your lock screen with a big Stop button.</td>
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
    <td><strong>📝</strong></td>
    <td><strong>Give it a task</strong></td>
    <td>Type what you're there to do, like "Buy medicine". Leave it blank and the place name is used instead.</td>
  </tr>
  <tr>
    <td><strong>🔁</strong></td>
    <td><strong>Repeat it</strong></td>
    <td>Set an alarm once, every day, or just on the days you pick. Good for a regular commute or a standing errand.</td>
  </tr>
  <tr>
    <td><strong>📍</strong></td>
    <td><strong>As many alarms as you like</strong></td>
    <td>Each with its own label and radius. Pause one without deleting it, and see live distance to each.</td>
  </tr>
  <tr>
    <td><strong>🔋</strong></td>
    <td><strong>Easy on the battery</strong></td>
    <td>Checks rarely when you are far away and more often as you get close, so a three hour journey does not flatten your phone.</td>
  </tr>
  <tr>
    <td><strong>🛡️</strong></td>
    <td><strong>Reliability check</strong></td>
    <td>Works out your phone's brand and shows the exact settings it needs, plus a test that proves the alarm gets through.</td>
  </tr>
  <tr>
    <td><strong>🌙</strong></td>
    <td><strong>Light and dark themes</strong></td>
    <td>Material 3 throughout, with map tiles tuned so dark mode is not a white rectangle at night.</td>
  </tr>
</table>

<br/>

---

<br/>

## 🛡️ Making sure it rings

> **Please read this once.** It is the difference between an alarm that works and one that does not.

Android lets apps ask for permission to run in the background, but phone manufacturers overrule it. Xiaomi, Samsung, Oppo, Vivo, OnePlus and Huawei each add their own app killer, and no app can switch those off by itself. You have to allow it by hand, once.

**Menu → Alarm reliability** works out which phone you have and walks you through it. For reference:

| Your phone | What to allow |
|---|---|
| **Xiaomi, Redmi, Poco** | Autostart, and Battery saver set to No restrictions |
| **Samsung** | Battery, then Background usage limits, then **Never sleeping apps** |
| **Oppo, Realme** | Allow Auto startup and Allow background running |
| **Vivo, iQOO** | High background power consumption and Autostart |
| **OnePlus** | Don't optimise, Auto launch, and turn off Advanced optimisation |
| **Huawei, Honor** | App launch, set to Manage manually, all three switches on |
| **Google, Motorola, Sony, Nokia, Nothing, Fairphone** | Nothing extra. Stock Android respects the standard settings. |

<br/>

---

<br/>

<div align="center">

### 👩‍💻 For developers

<sub>Everything below is about building and contributing to LocReminder.<br/>If you just want to use the app, you are all set.</sub>

</div>

<br/>

## 🔧 Under the hood

<details>
<summary><strong>How the alarm survives a locked screen</strong> (click to expand)</summary>

<br/>

The obvious approach, polling GPS from a Dart `Timer`, works in an emulator and fails on a real trip, because Android kills the app as soon as you lock the screen.

Android's own geofencing did not survive field testing either. An alarm was set 150 m away with a 100 m radius, then the phone walked in and waited 30 seconds. Nothing happened. It rang the instant the app was reopened, because Doze had held the geofence broadcast back until the app became active.

So geofencing was dropped entirely in favour of a foreground service that watches location itself. The alarm is native Kotlin, which means the Flutter engine can be completely dead and it still rings, and the app uses only platform APIs, so it needs no Google Play Services and works on de-Googled and HMS only devices.

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
| **Foreground watcher** | The whole detection mechanism. Polls adaptively, every 5 minutes beyond 10 km and every 10 seconds within 500 m. Holding a foreground service keeps the process out of the idle state that defers everything else. It ignores fixes too imprecise to confirm arrival, so a coarse cell tower fix cannot ring the alarm kilometres early. |
| **Alarm service** | Looping `USAGE_ALARM` audio, vibration, wake lock, full screen activity. Stops itself after 10 minutes. |
| **Watchdog** | An inexact allow-while-idle alarm. Restarts the watcher if a vendor power manager killed it, or if it is running but receiving no fixes, which is the state left behind when location is switched off at the OS level. |
| **Boot receiver** | Restores alarms and the watcher after a restart, or after the app itself is updated. |

</details>

<br/>

### Built with

```
┌─────────────────────────────────────────────────────────────┐
│  UI               Flutter 3 · Dart 3 · Material 3           │
│  Native engine    Kotlin (watcher, alarm, watchdog, boot)   │
├─────────────────────────────────────────────────────────────┤
│  Maps             OpenStreetMap via flutter_map, no key     │
│  Search           Nominatim geocoding, no key               │
│  Location         Platform LocationManager, no Play Services│
├─────────────────────────────────────────────────────────────┤
│  Storage          SharedPreferences (device-local only)     │
│  Build            Gradle 9 · AGP 9 · R8 shrinking           │
│  CI/CD            GitHub Actions, signed and scanned        │
└─────────────────────────────────────────────────────────────┘
```

<br/>

---

<br/>

## 🚀 Building it yourself

### Prerequisites

- **[Flutter SDK](https://flutter.dev/docs/get-started/install)** (stable channel)
- **[Android SDK](https://developer.android.com/studio)** and **JDK 17**

No Maps API key, no Google Cloud billing account, no signup. The map is OpenStreetMap.

```bash
git clone https://github.com/zaifears/locreminder.git
cd locreminder
flutter pub get
flutter run --release
```

> `--release` is worth using even for testing, because background location behaves closest to real conditions in a release build.

> **App icons** under `android/app/src/main/res/mipmap-*` are hand drawn and committed as they are. Do not run `flutter_launcher_icons`, as it would overwrite them.

### Commands

| Command | Description |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter analyze` | Static analysis (CI treats warnings as failures) |
| `flutter test` | Run unit tests |
| `flutter build apk --release` | Build a release APK |

### Signing

For local builds, signing falls back to Android's debug key so that `flutter build apk --release` always produces something installable. To sign with your own key instead:

```bash
keytool -genkey -v -keystore locreminder-release.jks -keyalg RSA \
  -keysize 4096 -validity 10000 -alias locreminder
cp android/key.properties.example android/key.properties
```

Fill in your keystore path and passwords. `key.properties` is git ignored.

> **Published releases work differently.** Tagged builds refuse to publish unless all four of `RELEASE_KEYSTORE_BASE64`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_ALIAS` and `RELEASE_KEY_PASSWORD` are set as repository secrets, and CI reads the certificate back out of the finished APK to prove the debug key was not used. That check exists because the fallback is silent, and every release up to v1.6.5 shipped debug signed without anything complaining.

<br/>

---

<br/>

## 🤝 Contributing

Contributions are welcome. Fork, branch, commit, and open a pull request.

1. **Fork the project**
2. **Create your feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a pull request**

<br/>

## 📄 License

| | |
|---|---|
| **Source code** | [MIT](LICENSE). Free to use, modify and distribute, commercially or otherwise. |
| **Logo, app icon and the name "LocReminder"** | © Shahoriar Hossain, all rights reserved |

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

  ---

  <br/>

  <a href="https://revolutionarypapers.org/journal/free-palestine/">
    <img src="assets/images/free_palestine.png" alt="Free Palestine" width="420"/>
  </a>

  <br/><br/>

</div>
