# Every word in LocReminder

This is the complete list of text a translator would replace. Nothing in the
app is missing from it, including the parts Android draws rather than Flutter.

## How to use this

1. Copy this file, or work through it in place.
2. Fill in the empty **Your language** column. You do not have to do all of
   it. Anything left blank stays English, and a part-finished translation is
   still worth sending.
3. Hand the filled-in file to Claude Code and ask it to produce
   `locale/<code>.yaml` from it. That is one file, and it is the only file
   the app needs.

You never have to touch Dart, Kotlin, or XML. If you would rather write the
YAML yourself, copy `locale/en.yaml` and translate the right-hand side; the
keys in the tables below are the same keys.

## Rules

**Words in curly braces** like `{place}` are filled in by the app while it is
running. Keep every one of them, spelled exactly the same. You may move them
anywhere in the sentence, which is the whole reason they exist: word order is
not the same in every language.

**Plurals** appear as two rows, *one* and *other*. If your language does not
split them the way English does, put the same text in both.

**Do not translate these**, ever:

| | Why |
|---|---|
| LocReminder | The app's name. |
| OpenStreetMap, OpenTopoMap, CyclOSM | Project names, and the map credit is a licence requirement. |
| Xiaomi, MIUI, HyperOS, Samsung, One UI, Oppo, ColorOS, Vivo, Funtouch, OnePlus, OxygenOS, Huawei, EMUI, Honor, MagicOS, Meizu, Flyme, Asus, ZenUI, Transsion, HiOS, XOS, TCL, Alcatel, HTC, Sense, Sharp, Kyocera, MediaTek, DuraSpeed, Amazon, Fire OS, Walton, Symphony, Lava, Micromax | Phone makers and their software. |
| Settings menu names in the **Phone-specific advice** section | Those menus appear on the phone in *its* language. If your phone shows them in your language, translate them to match exactly what is on screen. If it shows them in English, leave them in English. Getting this wrong sends someone hunting for a setting that does not exist. |

**Keep the arrows** (→) in settings paths. They separate one menu level from
the next.


## What is here

| Section | Strings |
|---|---:|
| [First run](#first-run) | 30 |
| [The map screen](#the-map-screen) | 35 |
| [Choosing a destination](#choosing-a-destination) | 14 |
| [Will it ring?](#will-it-ring) | 26 |
| [Phone-specific advice](#phone-specific-advice) | 105 |
| [Settings](#settings) | 21 |
| [Alarm sound](#alarm-sound) | 11 |
| [About](#about) | 10 |
| [Map styles](#map-styles) | 6 |
| [Search failures](#search-failures) | 5 |
| [Search results](#search-results) | 1 |
| [Version](#version) | 1 |
| [App shell](#app-shell) | 1 |
| [Already moved over](#already-moved-over) | 15 |
| [The alarm](#the-alarm) | 25 |
| [The F-Droid listing](#the-f-droid-listing) | 3 |
| **Everything** | **309** |

## First run

Shown once, before anything else. The user has not agreed to anything yet, so this text is what persuades them the permissions are reasonable.

`lib/screens/onboarding_screen.dart`

| Key | English | Your language |
|---|---|---|
| `findWhereYouAre` | Find where you are | |
| `locreminderNeedsYourLocation` | LocReminder needs your location. | |
| `thatSTheWholeTrick` | That's the whole trick: the app compares where you are against where you want to be woken up, and rings when the two match.\n\nYour location never leaves your phone. There is no account, no server, and nothing is uploaded anywhere — this app has no internet backend at all. | |
| `locationAccessGranted` | Location access granted | |
| `allowLocation` | Allow location | |
| `turnOnLocationServices` | Turn on location services | |
| `keepWatchWhileYouRest` | Keep watch while you rest | |
| `chooseAllowAllTheTime` | Choose "Allow all the time" on the next screen. | |
| `thisIsTheMostImportant` | This is the most important one, and the easiest to get wrong.\n\nThe entire point of LocReminder is that you can put your phone in your pocket and sleep through the ride. Android only lets the alarm fire while the app is closed if you pick "Allow all the time".\n\nIf you pick "Only while using the app", everything will look fine — but the alarm will never go off once you lock your screen. | |
| `backgroundLocationGranted` | Background location granted | |
| `openLocationSettings` | Open location settings | |
| `showTheAlarmOnScreen` | Show the alarm on screen | |
| `locreminderNeedsToPostNotifications` | LocReminder needs to post notifications. | |
| `whenYouArriveTheApp` | When you arrive, the app takes over your screen with a full-screen alarm and a Stop button — like a normal alarm clock, even over the lock screen.\n\nAndroid treats that as a notification. Without this permission the alarm may make noise with no way to see or silence it. | |
| `notificationsGranted` | Notifications granted | |
| `allowFullScreenAlarms` | Allow full-screen alarms | |
| `allowNotifications` | Allow notifications | |
| `oneMoreStepAndroidAnd` | One more step: Android 14 and newer ask separately for permission to show full-screen alarms. | |
| `donTLetAndroidDoze` | Don't let Android doze off | |
| `turnOffBatteryOptimizationFor` | Turn off battery optimization for LocReminder. | |
| `thisOneIsNotOptional` | This one is not optional, and it is the reason most location alarms fail.\n\nWith battery optimization on, Android puts the app to sleep once your screen is off and postpones its location work. The alarm then stays silent for the entire journey and only goes off when you next unlock and open the app — by which point you have already gone past your stop.\n\nOn the next screen choose LocReminder, then "Don\'t optimize" or "Unrestricted". | |
| `batteryOptimizationDisabled` | Battery optimization disabled | |
| `openBatterySettings` | Open battery settings | |
| `phoneMakersLikeXiaomiSamsung` | Phone makers like Xiaomi, Samsung, Oppo, Vivo and OnePlus add their own app-killer on top of this one. After finishing setup, open Alarm reliability from the menu — it shows the exact steps for your model and lets you test the alarm. | |
| `deviceSpecificSetup` | Device-specific setup | |
| `stepPageindexOfLength` | Step {_pageIndex} of {length} | |
| `skip` | Skip | |
| `startUsingLocreminder` | Start using LocReminder | |
| `grantTheRequiredPermissions` | Grant the required permissions | |
| `next` | Next | |

## The map screen

The screen people actually live in. Includes every transient message.

`lib/screens/home_screen.dart`

| Key | English | Your language |
|---|---|---|
| `metresM` | {metres} m | |
| `metresKm` | {metres} km | |
| `metresKm2` | {metres} km | |
| `backgroundTrackingCouldNotStart` | Background tracking could not start ({code}). Alarms may be delayed — check permissions in Settings. | |
| `couldnTGetALocation` | Couldn't get a location fix. Try again outdoors. | |
| `locationIsSwitchedOff` | Location is switched off. | |
| `turnOn` | Turn on | |
| `alreadyRangTriggeredlabels` | Already rang: {triggeredLabels} | |
| `alarmSetButYouRe` | Alarm set — but you're already inside this area, so it will ring when you leave and come back. | |
| `alarmSetForLabel` | Alarm set for {label} | |
| `couldNotSetAlarmE` | Could not set alarm: {e} | |
| `deletedLabel` | Deleted {label} | |
| `undo` | Undo | |
| `labelRingsWithinFormatdistance` | {label} · rings within {formatDistance} | |
| `labelFormatdistanceAway` | {label} · {formatDistance} away | |
| `centreOnMyLocation` | Centre on my location | |
| `addAlarm` | Add alarm | |
| `menu` | Menu | |
| `searchForADestination` | Search for a destination | |
| `locationServices` | location services | |
| `locationAccess` | location access | |
| `allowAllTheTime` | "Allow all the time" | |
| `yourAlarmsWillNotRing` | Your alarms will not ring | |
| `missingMissing` | Missing {missing}. | |
| `fix` | Fix | |
| `alarmRinging` | Alarm ringing | |
| `stop` | Stop | |
| `noAlarmsYet` | No alarms yet | |
| `tapAddAlarmToSearch` | Tap "Add alarm" to search for where you\'re heading, then choose how close you want to be before it rings. | |
| `alarmsAlarms` | {_alarms} {_alarms} | |
| `activecountArmed` | {activeCount} armed | |
| `pausedRingsWithinRadiuslabel` | Paused · rings within {radiusLabel} | |
| `ringsWithinRadiuslabel` | Rings within {radiusLabel} | |
| `formatdistanceAwayRingsWithinRadiuslabel` | {formatDistance} away · rings within {radiusLabel} | |
| `delete` | Delete | |

## Choosing a destination

Search, the radius slider, and the speed advice.

`lib/screens/location_picker_screen.dart`

| Key | English | Your language |
|---|---|---|
| `destination` | Destination | |
| `floorKm` | {floor} km | |
| `floorM` | {floor} m | |
| `youReMovingAtKilometresperhour` | You're moving at {kilometresPerHour} km/h. Below {asText} the alarm can pass your stop between location checks. | |
| `youReMovingAtKilometresperhour2` | You're moving at {kilometresPerHour} km/h, so this starts at {asText} to give the alarm room to catch you. | |
| `searchForAPlaceOr` | Search for a place or address | |
| `couldnTReachTheSearch` | Couldn't reach the search service. Check your connection, or drag the map to pick the spot manually. | |
| `noPlacesFoundTryA` | No places found. Try a different search. | |
| `findingThisPlace` | Finding this place… | |
| `droppedPin` | Dropped pin | |
| `wakeMeWithin` | Wake me within | |
| `radiusKm` | {_radius} km | |
| `radiusM` | {_radius} m | |
| `setAlarmHere` | Set alarm here | |

## Will it ring?

The diagnostics screen. The most important text in the app after the alarm itself.

`lib/screens/reliability_screen.dart`

| Key | English | Your language |
|---|---|---|
| `testTheAlarm` | Test the alarm | |
| `theAlarmWillRingIn` | The alarm will ring in 15 seconds.\n\nLock your phone now and put it down. If the alarm sounds and its screen appears over your lock screen, background alarms work on this device.\n\nIf nothing happens, your phone is blocking the app — work through the steps on this page. | |
| `cancel` | Cancel | |
| `startTest` | Start test | |
| `lockYourPhoneNowThe` | Lock your phone now — the alarm rings in 15 seconds. | |
| `androidPermissions` | Android permissions | |
| `locationAllowAllTheTime` | Location "Allow all the time" | |
| `notifications` | Notifications | |
| `fullScreenAlarms` | Full-screen alarms | |
| `batteryOptimizationOff` | Battery optimization off | |
| `yourDevice` | Your device | |
| `proveItWorks` | Prove it works | |
| `testTheAlarmFromA` | Test the alarm from a locked screen | |
| `ringsTheRealAlarmAfter` | Rings the real alarm after 15 seconds so you can lock your phone and see whether it gets through. Much better to find out here than on the bus. | |
| `runAlarmTest` | Run alarm test | |
| `readyToWakeYou` | Ready to wake you | |
| `alarmsMayNotRing` | Alarms may not ring | |
| `watchingForYourDestinationNow` | Watching for your destination now. | |
| `everythingIsGrantedTrackingStarts` | Everything is granted. Tracking starts when you arm an alarm. | |
| `someRequiredPermissionsAreMissing` | Some required permissions are missing. | |
| `fix2` | Fix | |
| `thisDevice` | This device | |
| `doTheseByHand` | Do these by hand | |
| `androidGivesAppsNoWay` | Android gives apps no way to set these themselves. | |
| `openTheseSettings` | Open these settings | |
| `index` | {index} | |

## Phone-specific advice

Per-manufacturer instructions for stopping the phone killing background apps. The largest block, and the one most worth translating: a user who cannot follow it gets no alarm at all.

`lib/services/oem_service.dart`

| Key | English | Your language |
|---|---|---|
| `xiaomiMiuiHyperos` | Xiaomi (MIUI / HyperOS) | |
| `miuiBlocksAutostartForApps` | MIUI blocks autostart for apps by default and will not restart background work without it. Autostart plus "No restrictions" are both needed — one alone is not enough. | |
| `turnOnAutostart` | Turn on Autostart | |
| `settingsAppsManageAppsLocreminder` | Settings → Apps → Manage apps → LocReminder → Autostart | |
| `setBatterySaverToNo` | Set battery saver to No restrictions | |
| `settingsAppsManageAppsLocreminder2` | Settings → Apps → Manage apps → LocReminder → Battery saver → No restrictions | |
| `lockTheAppInRecents` | Lock the app in Recents | |
| `openRecentsPullDownOn` | Open Recents, pull down on the LocReminder card, tap the padlock | |
| `samsungOneUi` | Samsung (One UI) | |
| `samsungPutsAppsYouHave` | Samsung puts apps you have not opened for a few days into "sleeping", which stops their alarms. Adding LocReminder to "Never sleeping apps" is the setting that prevents this. | |
| `addToNeverSleepingApps` | Add to Never sleeping apps | |
| `settingsBatteryBackgroundUsageLimits` | Settings → Battery → Background usage limits → Never sleeping apps → add LocReminder | |
| `makeSureItIsNot` | Make sure it is not in Sleeping or Deep sleeping apps | |
| `settingsBatteryBackgroundUsageLimits2` | Settings → Battery → Background usage limits → Sleeping apps | |
| `setBatteryUsageToUnrestricted` | Set battery usage to Unrestricted | |
| `settingsAppsLocreminderBatteryUnrestricted` | Settings → Apps → LocReminder → Battery → Unrestricted | |
| `oppoRealmeColoros` | Oppo / Realme (ColorOS) | |
| `colorosStopsBackgroundAppsUnless` | ColorOS stops background apps unless they are given both auto-startup and permission to keep running in the background. | |
| `allowAutoStartup` | Allow Auto-startup | |
| `settingsAppsAppManagementLocreminder` | Settings → Apps → App management → LocReminder → Allow Auto-startup | |
| `allowBackgroundRunning` | Allow background running | |
| `settingsBatteryAppBatteryManagement` | Settings → Battery → App battery management → LocReminder → Allow background running | |
| `openRecentsTapTheMenu` | Open Recents, tap the menu on the LocReminder card, tap Lock | |
| `vivoIqooFuntouchOriginos` | Vivo / iQOO (Funtouch / OriginOS) | |
| `funtouchTreatsSteadyBackgroundLocation` | Funtouch treats steady background location as "high power consumption" and cuts it off unless the app is allowed explicitly. | |
| `allowHighBackgroundPowerConsumption` | Allow high background power consumption | |
| `settingsBatteryHighBackgroundPower` | Settings → Battery → High background power consumption → LocReminder | |
| `allowAutostart` | Allow autostart | |
| `settingsAppsPermissionManagerAutostart` | Settings → Apps → Permission manager → Autostart → LocReminder | |
| `openRecentsSwipeDownOn` | Open Recents, swipe down on the LocReminder card to lock it | |
| `oneplusOxygenos` | OnePlus (OxygenOS) | |
| `oxygenosHasASecondLayer` | OxygenOS has a second layer of "advanced" optimization on top of the standard battery setting, and it needs turning off separately. | |
| `turnOffBatteryOptimization` | Turn off battery optimization | |
| `settingsAppsLocreminderBatteryDon` | Settings → Apps → LocReminder → Battery → Don't optimize | |
| `allowAutoLaunch` | Allow auto-launch | |
| `settingsAppsAutoLaunchLocreminder` | Settings → Apps → Auto-launch → LocReminder | |
| `disableAdvancedOptimizationDeepOptimization` | Disable Advanced optimization / Deep optimization | |
| `settingsBatteryMoreSettingsTurn` | Settings → Battery → More settings → turn off Advanced optimization | |
| `huaweiEmuiHarmonyos` | Huawei (EMUI / HarmonyOS) | |
| `emuiResetsBackgroundPermissionsDuring` | EMUI resets background permissions during its own maintenance, so it is worth re-checking these after a system update. | |
| `setAppLaunchToManage` | Set app launch to Manage manually | |
| `settingsBatteryAppLaunchLocreminder` | Settings → Battery → App launch → LocReminder → Manage manually → enable all three | |
| `turnOffPowerGenieBattery` | Turn off Power Genie / battery optimization | |
| `settingsBatteryMoreBatterySettings` | Settings → Battery → More battery settings | |
| `honorMagicos` | Honor (MagicOS) | |
| `magicosKeepsHuaweiStyleApp` | MagicOS keeps Huawei-style app-launch controls. Its menus moved after Honor split from Huawei, so the wording may differ slightly from older guides. | |
| `settingsAppsLocreminderBatteryNo` | Settings → Apps → LocReminder → Battery → No restrictions | |
| `meizuFlyme` | Meizu (Flyme) | |
| `flymeKeepsItsOwnStandby` | Flyme keeps its own standby and autostart lists, separate from Android\'s battery settings. | |
| `settingsAppsPermissionManagementAutostart` | Settings → Apps → Permission management → Autostart → LocReminder | |
| `turnOffStandbyManagement` | Turn off standby management | |
| `settingsBatteryStandbyManagementLocreminder` | Settings → Battery → Standby management → LocReminder → allow background | |
| `asusZenui` | Asus (ZenUI) | |
| `zenuiShipsAMobileManager` | ZenUI ships a Mobile Manager app that manages autostart separately from Android\'s own settings. | |
| `allowAutoStart` | Allow auto-start | |
| `mobileManagerAutoStartManager` | Mobile Manager → Auto-start Manager → LocReminder → Allow | |
| `transsionHiosXos` | Transsion (HiOS / XOS) | |
| `theseDevicesShipAPhone` | These devices ship a Phone Master app whose power saving overrides Android\'s own battery settings. | |
| `settingsAppsLocreminderAutostart` | Settings → Apps → LocReminder → Autostart | |
| `setBatteryToNoRestrictions` | Set battery to No restrictions | |
| `settingsBatteryBackgroundPowerConsumption` | Settings → Battery → Background power consumption → LocReminder | |
| `addToTheProtectedList` | Add to the protected list in Phone Master | |
| `phoneMasterPowerSavingProtected` | Phone Master → Power saving → Protected apps → LocReminder | |
| `lenovoZteLeeco` | Lenovo / ZTE / LeEco | |
| `theseSkinsKeepABackground` | These skins keep a background autostart list separate from Android\'s battery settings; an app missing from it gets stopped. | |
| `allowAutostartBackgroundRunning` | Allow autostart / background running | |
| `settingsAppsLocreminderAutostartOr` | Settings → Apps → LocReminder → Autostart (or Background settings) | |
| `settingsBatteryLocreminderUnrestricted` | Settings → Battery → LocReminder → Unrestricted | |
| `tclAlcatel` | TCL / Alcatel | |
| `tclDevicesPairAndroid` | TCL devices pair Android | |
| `separateManagerAppAndBeing` | separate manager app, and being allowed by one does not mean being allowed by the other. | |
| `setBatteryUseToUnrestricted` | Set battery use to Unrestricted | |
| `settingsBatteryBatteryOptimisationLocreminde` | Settings → Battery → Battery optimisation → LocReminder → Don | |
| `allowItToStartAutomatically` | Allow it to start automatically | |
| `settingsAppsLocreminderAutostartIf` | Settings → Apps → LocReminder → Autostart, if your model has it | |
| `htcSense` | HTC (Sense) | |
| `whichIsSeparateFromAndroid` | which is separate from Android | |
| `setBatteryOptimisationToDon` | Set battery optimisation to Don | |
| `settingsBatteryBatteryOptimisationLocreminde2` | Settings → Battery → Battery optimisation → LocReminder | |
| `excludeItFromBoost` | Exclude it from Boost+ | |
| `boostOptimiseBackgroundAppsUntick` | Boost+ → Optimise background apps → untick LocReminder | |
| `sharpKyocera` | Sharp / Kyocera | |
| `theseModelsShipAnEco` | These models ship an eco or long-life battery mode that suspends background apps more aggressively than stock Android does. | |
| `excludeItFromTheBattery` | Exclude it from the battery saver | |
| `settingsBatteryEcoModeOr` | Settings → Battery → Eco mode (or Long life battery) → exclude LocReminder | |
| `mediatekBasedDevice` | MediaTek-based device | |
| `phonesBuiltOnMediatek` | Phones built on MediaTek | |
| `duraspeedWhichClosesBackgroundApps` | DuraSpeed, which closes background apps to speed up the foreground one. It is separate from Android | |
| `byDefault` | by default. | |
| `turnDuraspeedOffOrAllow` | Turn DuraSpeed off, or allow LocReminder in it | |
| `settingsDuraspeedOrSettingsSpecial` | Settings → DuraSpeed (or Settings → Special features → DuraSpeed) | |
| `amazonFireOs` | Amazon (Fire OS) | |
| `fireOsRestrictsBackgroundApps` | Fire OS restricts background apps on its own terms, and has no Google location services at all. LocReminder does not need them, but the background limits still apply. | |
| `turnOffBatteryOptimisationFor` | Turn off battery optimisation for it | |
| `settingsAppsNotificationsLocreminderAdvanced` | Settings → Apps & Notifications → LocReminder → Advanced → Battery | |
| `turnOffLowPowerMode` | Turn off Low Power Mode while an alarm is armed | |
| `settingsBatteryLowPowerMode` | Settings → Battery → Low Power Mode | |
| `thisBrandShipsCloseTo` | This brand ships close to stock Android, so there is usually no vendor app to fight. The one setting that still matters is Android | |
| `ownBatteryOptimisationWhichIs` | own battery optimisation, which is on by default for every app. | |
| `ifYourPhoneHasA` | If your phone has a power or phone manager app, allow it there too | |
| `lookForProtectedAppsAutostart` | Look for "protected apps", "autostart" or "background activity" | |
| `stockAndroid` | stock Android | |
| `thisManufacturerFollowsAndroidS` | This manufacturer follows Android\'s standard background rules, so the permissions above should be all you need. | |
| `yourDevice2` | your device | |
| `weHaveNoNotesSpecific` | We have no notes specific to this manufacturer. Nearly every Android skin has a setting under some name that stops background apps, so if an alarm is ever late, look for "autostart", "background activity", "protected apps" or "unrestricted battery" and allow LocReminder in whichever of them your phone has. | |

## Settings

`lib/screens/settings_screen.dart`

| Key | English | Your language |
|---|---|---|
| `appearance` | Appearance | |
| `system` | System | |
| `light` | Light | |
| `dark` | Dark | |
| `matchingYourPhoneSTheme` | Matching your phone\'s theme. | |
| `alwaysLightWhateverYourPhone` | Always light, whatever your phone uses. | |
| `alwaysDarkWhateverYourPhone` | Always dark, whatever your phone uses. | |
| `alarmSound` | Alarm sound | |
| `location` | Location | |
| `backgroundLocation` | Background location | |
| `mustBeAllowAllThe` | Must be "Allow all the time" | |
| `notifications2` | Notifications | |
| `fullScreenAlarms2` | Full-screen alarms | |
| `neededOnAndroidAndNewer` | Needed on Android 14 and newer | |
| `batteryOptimizationOff2` | Battery optimization off | |
| `requiredAndroidDelaysAlarmsWithout` | Required — Android delays alarms without it | |
| `deviceSpecificSetupAndA` | Device-specific setup and a test that proves alarms get through | |
| `openSystemAppSettings` | Open system app settings | |
| `aboutThisBuild` | About this build | |
| `version` | Version | |
| `fix3` | Fix | |

## Alarm sound

`lib/widgets/alarm_sound_section.dart`

| Key | English | Your language |
|---|---|---|
| `couldNotOpenThePicker` | Could not open the picker: {e} | |
| `alarmSound2` | Alarm sound | |
| `defaultAlarmTone` | Default alarm tone | |
| `stop2` | Stop | |
| `play` | Play | |
| `ringtones` | Ringtones | |
| `myFiles` | My files | |
| `useTheDefaultAlarmTone` | Use the default alarm tone | |
| `vibrate` | Vibrate | |
| `alongsideTheAlarmSound` | Alongside the alarm sound | |
| `playsOnTheAlarmChannel` | Plays on the alarm channel, so it sounds even when your phone is on silent. If a chosen file is later deleted or becomes unreadable, the default tone is used instead. | |

## About

`lib/screens/about_screen.dart`

| Key | English | Your language |
|---|---|---|
| `couldNotOpenUri` | Could not open {uri} | |
| `version2` | Version… | |
| `versionVersion` | Version {_version} | |
| `aLocationBasedAlarmThat` | A location-based alarm that wakes you when you approach your destination — so you can sleep on the bus without missing your stop.\n\nIt keeps watching in the background, so the alarm still fires when the app is closed, and uses OpenStreetMap for maps, so it needs no API keys or accounts.\n\nFree software with no Google services, no ads and no tracking. Your locations stay on your phone. | |
| `shahoriarHossain` | Shahoriar Hossain | |
| `website` | Website | |
| `github` | GitHub | |
| `contact` | Contact | |
| `mapDataAndSearchOpenstreetmap` | Map data and search © OpenStreetMap contributors, available under the Open Database License.\n\nLocReminder\'s source code is open source under the MIT licence. The app icon, logo and name remain © Shahoriar Hossain, all rights reserved. | |
| `freePalestineOpensRevolutionarypapersOrg` | Free Palestine. Opens revolutionarypapers.org in your browser. | |

## Map styles

`lib/widgets/map_tiles.dart`

| Key | English | Your language |
|---|---|---|
| `theUsualOpenstreetmapLook` | The usual OpenStreetMap look | |
| `openstreetmap` | © OpenStreetMap | |
| `openstreetmapHot` | © OpenStreetMap · HOT | |
| `openstreetmapOpentopomapCcBySa` | © OpenStreetMap · OpenTopoMap (CC-BY-SA) | |
| `openstreetmapCyclosm` | © OpenStreetMap · CyclOSM | |
| `noSatelliteViewEveryProvider` | No satellite view: every provider of satellite imagery is a closed service, and LocReminder keeps to open data so it works without any account or tracking. | |

## Search failures

`lib/services/geocoding_service.dart`

| Key | English | Your language |
|---|---|---|
| `userAgent` | User-Agent | |
| `search` | /search | |
| `reverse` | /reverse | |
| `latitude` | {latitude} | |
| `longitude` | {longitude} | |

## Search results

`lib/models/place_result.dart`

| Key | English | Your language |
|---|---|---|
| `unknownPlace` | Unknown place | |

## Version

`lib/services/app_version.dart`

| Key | English | Your language |
|---|---|---|
| `versionBuildBuildnumber` | {version} (build {buildNumber}) | |

## App shell

`lib/main.dart`

| Key | English | Your language |
|---|---|---|
| `noLocreminderappFoundInContext` | No LocReminderApp found in context | |

## Already moved over

App text that has already been moved into the language file. Nothing
special about it: it needs translating like the rest.

`locale/en.yaml`, under `app:`

| Key | English | Your language |
|---|---|---|
| `appTitle` | LocReminder | |
| `appTagline` | Never miss your stop | |
| `drawerReliability` | Alarm reliability | |
| `drawerReliabilitySubtitle` | Make sure it will ring | |
| `drawerSettings` | Settings | |
| `drawerAbout` | About | |
| `mapAttribution` | Map data © OpenStreetMap contributors | |
| `mapStyleTitle` | Map style | |
| `mapStyleStandard` | Standard | |
| `mapStyleHumanitarian` | Humanitarian | |
| `mapStyleHumanitarianDescription` | Higher contrast, clearer labels | |
| `mapStyleTopographic` | Topographic | |
| `mapStyleTopographicDescription` | Contours and terrain | |
| `mapStyleCycle` | Cycle | |
| `mapStyleCycleDescription` | Paths, lanes and cycle routes | |

## The alarm

What the alarm itself says, plus the ongoing notification while it is
watching. Drawn by Android rather than by the app, so that it still works
when the app is not running.

`locale/en.yaml`, under `alarm:`

| Key | English | Your language |
|---|---|---|
| `alarm_arrived_default` | You've arrived! | |
| `alarm_arrived_message` | You're near {place} | |
| `alarm_stop_button` | Stop alarm | |
| `alarm_default_destination` | your destination | |
| `alarm_label_joiner` |  and  | |
| `alarm_notification_title` | You're near {place} | |
| `alarm_notification_body` | Tap to open the alarm, or stop it below. | |
| `channel_alarm_name` | Location alarms | |
| `channel_alarm_description` | Alerts you when you arrive near a saved destination | |
| `channel_watch_name` | Watching for destinations | |
| `channel_watch_description` | Shows while LocReminder is watching for your destination | |
| `notify_arrived_body` | Tap to open your alarm. | |
| `notify_stopped_title` | Your alarm stopped watching | |
| `notify_stopped_body` | Tap to reopen LocReminder and re-arm it. | |
| `notify_location_off_title` | Location is off — your alarm can't ring | |
| `notify_location_off_body` | Tap to turn location on. | |
| `watch_title_active` | Watching for your destination | |
| `watch_title_inactive` | Not watching | |
| `watch_location_off` | Turn on location — the alarm can't ring without it | |
| `watch_distance_km` | {distance} km from {place} | |
| `watch_distance_m` | {distance} m from {place} | |
| `watch_armed` (one) | {count} alarm armed | |
| `watch_armed` (other) | {count} alarms armed | |
| `test_alarm_label` | Test alarm | |
| `custom_sound_name` | Custom sound | |

## The F-Droid listing

What people read before they install. Not shown inside the app.

`locale/en.yaml`, under `store:`

### `title`

```
LocReminder
```

### `shortDescription`

```
An alarm that rings when you arrive, not at a set time.
```

### `fullDescription`

```
LocReminder is an alarm clock that goes off at a place instead of a time.

You know roughly where you are going, but not exactly when you will get there. Traffic, delays and unfamiliar routes make that impossible to predict, so a normal alarm is no use. Instead you spend the whole journey glancing out of the window, unable to properly rest or focus.

Drop a pin on your destination, choose how close you want to get, and put your phone away. When you arrive, LocReminder rings a real alarm: a looping sound that plays even on silent, vibration, and a full-screen alert over your lock screen.

<b>What it is good for</b>

* Long bus or train rides, so you can actually sleep
* Arriving somewhere unfamiliar, where you would not recognise your stop
* Commuting, so you can read or work without watching the route
* Road trips as a passenger, to be woken before the turn-off
* Errands, as a nudge when you are near the shop or post office

<b>Features</b>

* A real alarm, not a quiet notification: loops on the alarm audio channel so it sounds even on silent
* Choose your own alarm sound: any system ringtone, or an audio file of your own
* Search for a destination by name, or drag the map to place the pin exactly
* Multiple alarms, each with its own label and trigger radius, and live distance to each
* Adjustable radius from 100 m to 3 km, so you get as much warning as you need
* Light and dark themes
* Battery-aware: checks rarely when you are far away, more often as you approach
* Reliability screen that detects your phone's manufacturer and shows the exact settings needed, plus a test that proves the alarm gets through a locked screen

<b>Privacy</b>

LocReminder has no account, no analytics, no advertising and no server. Your saved destinations never leave your device. Maps and place search come from OpenStreetMap.

<b>Important: background restrictions</b>

Many manufacturers (Xiaomi, Samsung, Oppo, Vivo, OnePlus, Huawei) run their own battery managers that stop background apps, which will prevent the alarm from ringing. No app can change those settings on your behalf. After installing, open Menu, then Alarm reliability, and follow the steps shown for your device. It takes a minute and is the difference between an alarm that works and one that does not.
```
