# Privacy Policy

**LocReminder** · last updated 9 September 2026

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

**The alarm makes none.** Working out that you have arrived uses GPS, which
is a receive-only radio, and the comparison happens on your phone. It rings
with no connection at all.

Two parts of the app do use the network, and only while you are using them.
Both are free OpenStreetMap-based services run by other people:

**OpenStreetMap Foundation** (`tile.openstreetmap.org`,
`nominatim.openstreetmap.org`) — map images, converting a coordinate you
have picked into an address, and place search when Photon is unavailable or
finds nothing. See the
[OpenStreetMap privacy policy](https://osmfoundation.org/wiki/Privacy_Policy).

**Photon** (`photon.komoot.io`) — place search as you type. Photon is free
software (Apache 2.0) and its public instance is provided by Komoot. See the
[Photon project](https://github.com/komoot/photon).

As with any map application, these requests necessarily reveal your IP
address to whoever runs the service, along with the map area you are looking
at or the words you typed. When you search, the app also sends the
approximate centre of the map you are looking at, so that nearby places rank
above distant ones with similar names.

Be clear about what that last part means: the map opens centred on you, so
if you search without panning first, the coordinate sent as the search bias
is roughly where you are. It is sent as a hint for ranking, not stored, and
it moves wherever you move the map.

What is **not** sent, to either of them or anywhere else:

- your saved destinations
- your GPS position itself, at any point, to anybody
- anything at all once a search is over

Map images are only requested for areas you actually look at, and are then
kept on your phone for a month so the same ones are not fetched again. A
search is only sent while you are typing one. Typing coordinates directly
sends nothing at all.

There is no LocReminder server, and no other network connection is made.

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
