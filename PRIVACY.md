# Privacy Policy

**LocReminder** · last updated 15 August 2026

## The short version

LocReminder has no account system, no analytics, no advertising and no
server of its own. Your destinations and your location never leave your
phone, because there is nowhere for them to go.

## What the app stores

Everything below is stored **only on your device**, in the app's private
storage, and is deleted when you uninstall the app:

| Data | Why | Where |
|---|---|---|
| Saved destinations (name, coordinates, radius) | To know when to wake you | Device only |
| Your alarm sound choice | To play the sound you picked | Device only |
| Theme preference | To remember light/dark | Device only |

## Location

LocReminder uses your location **solely** to work out how far you are from
a destination you have saved, and to ring an alarm when you arrive.

- Your location is processed on your device and is **never transmitted**
  anywhere.
- It is **not stored** — each position is compared against your saved
  destinations and then discarded.
- Background location access is required because the alarm's entire purpose
  is to work while the app is closed and your screen is off.
- Location access stops entirely when you have no active alarms.

## Network connections

The app makes network requests to exactly one third party:

**OpenStreetMap** (`tile.openstreetmap.org`, `nominatim.openstreetmap.org`)
— to download map tiles and to search for places by name. These requests
necessarily reveal your IP address and the map area or search term to the
OpenStreetMap Foundation, as with any map application. See the
[OpenStreetMap privacy policy](https://osmfoundation.org/wiki/Privacy_Policy).

Map tiles are only requested for areas you actually look at, and a search
is only sent when you type one. Your saved destinations are never sent.

No other network connections are made. There is no LocReminder server.

## Permissions and why each is needed

| Permission | Purpose |
|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Measure distance to your destination |
| `ACCESS_BACKGROUND_LOCATION` | Let the alarm work while the app is closed |
| `FOREGROUND_SERVICE` + `_LOCATION` + `_MEDIA_PLAYBACK` | Keep watching, and play the alarm, without being killed |
| `POST_NOTIFICATIONS` | Show the alarm and the "watching" status |
| `USE_FULL_SCREEN_INTENT` | Show the alarm over your lock screen |
| `WAKE_LOCK` | Stay awake long enough to ring |
| `VIBRATE` | Vibrate with the alarm |
| `RECEIVE_BOOT_COMPLETED` | Restore your alarms after a restart |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Ask to be exempt so alarms are not delayed |
| `INTERNET` | Download map tiles and search for places |

## Children

LocReminder collects no personal data from anyone, including children.

## Changes

Any change to this policy will appear in this file, which is public in the
project's Git history.

## Contact

Shahoriar Hossain — <shahoriar.connect@gmail.com> — <https://shahoriar.bd/>
