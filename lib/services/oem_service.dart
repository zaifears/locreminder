import 'package:flutter/services.dart';

import 'native_bridge.dart';

/// One manufacturer-specific setting the user needs to configure.
class OemStep {
  const OemStep({required this.title, required this.path});

  /// What the setting achieves.
  final String title;

  /// Where to find it in the device menus.
  final String path;
}

/// Complete setup guide for a phone brand, covering both full-screen lock-screen
/// display and background reliability. Exposed so users can view instructions
/// for their detected phone or browse any other phone brand.
class PhoneSetupGuide {
  const PhoneSetupGuide({
    required this.name,
    required this.modelsHint,
    required this.fullScreenSteps,
    required this.backgroundSteps,
  });

  final String name;
  final String modelsHint;
  final List<OemStep> fullScreenSteps;
  final List<OemStep> backgroundSteps;
}

class DeviceProfile {
  const DeviceProfile({
    required this.manufacturer,
    required this.model,
    required this.sdkInt,
    required this.needsExtraSetup,
    required this.vendorName,
    required this.steps,
    required this.fullScreenSteps,
    required this.note,
  });

  final String manufacturer;
  final String model;
  final int sdkInt;

  /// True for vendors that restrict background services beyond standard Android.
  final bool needsExtraSetup;

  /// Display name for the manufacturer or software skin.
  final String vendorName;

  /// Background / autostart / battery steps for this phone.
  final List<OemStep> steps;

  /// Full-screen / lock-screen alarm display steps for this phone.
  final List<OemStep> fullScreenSteps;

  final String note;

  bool get isXiaomi {
    final combined = '$manufacturer $model $vendorName'.toLowerCase();
    return combined.contains('xiaomi') ||
        combined.contains('redmi') ||
        combined.contains('poco') ||
        combined.contains('miui') ||
        combined.contains('hyperos');
  }
}

class _VendorProfile {
  const _VendorProfile({
    required this.keys,
    required this.name,
    required this.modelsHint,
    required this.note,
    required this.fullScreenSteps,
    this.steps = const [],
    this.aggressive = true,
  });

  final List<String> keys;
  final String name;
  final String modelsHint;
  final String note;
  final List<OemStep> fullScreenSteps;
  final List<OemStep> steps;
  final bool aggressive;
}

const _defaultFullScreenSteps = <OemStep>[
  OemStep(
    title: 'Allow Full-screen notifications (Android 14+)',
    path:
        'Settings > Apps > Special app access > Full screen notifications (or Manage full screen intents) > LocReminder > Allow',
  ),
  OemStep(
    title: 'Show notifications on lock screen',
    path:
        'Settings > Apps > LocReminder > Notifications > Location alarms > Lock screen > Show all notification content',
  ),
  OemStep(
    title: 'Enable Pop on screen / Banners',
    path:
        'Settings > Apps > LocReminder > Notifications > Location alarms > turn on Pop on screen',
  ),
];

const _vendorProfiles = <_VendorProfile>[
  _VendorProfile(
    keys: ['xiaomi', 'redmi', 'poco', 'blackshark'],
    name: 'Xiaomi / Redmi / Poco (MIUI & HyperOS)',
    modelsHint: 'Redmi Note 12 4G, Redmi, Poco, Xiaomi series',
    note:
        'MIUI and HyperOS block lock-screen alarm pop-ups and background location by default until "Other permissions" and Autostart are enabled.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Show on Lock screen',
        path:
            'Settings > Apps > Manage apps > LocReminder > Other permissions > Show on Lock screen > Always allow',
      ),
      OemStep(
        title: 'Allow Display pop-up windows while running in the background',
        path:
            'Settings > Apps > Manage apps > LocReminder > Other permissions > Display pop-up windows while running in the background > Always allow',
      ),
      OemStep(
        title: 'Enable Lock screen & Floating notifications',
        path:
            'Settings > Apps > Manage apps > LocReminder > Notifications > turn on Lock screen notifications & Floating notifications (and inside "Location alarms")',
      ),
      OemStep(
        title: 'Allow Full screen intents (HyperOS / Android 14+)',
        path:
            'Settings > Apps > Special app access > Full screen intents > LocReminder > Allow',
      ),
    ],
    steps: [
      OemStep(
        title: 'Turn on Autostart (or Background autostart)',
        path:
            'Settings > Apps > Manage apps > LocReminder > Autostart (or Background autostart)',
      ),
      OemStep(
        title: 'Set Battery saver to No restrictions',
        path:
            'Settings > Apps > Manage apps > LocReminder > Battery saver > No restrictions',
      ),
      OemStep(
        title: 'Allow Show on Lock screen & Background pop-ups',
        path:
            'Settings > Apps > Manage apps > LocReminder > Other permissions > enable "Show on Lock screen" & "Display pop-up windows while running in the background"',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, long-press or pull down on LocReminder, tap the lock icon',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['samsung'],
    name: 'Samsung (One UI)',
    modelsHint: 'Galaxy S, A, M, F, Z series',
    note:
        'One UI puts unused apps to sleep and requires Full screen alerts permission on Android 14+.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen alerts (One UI 6 / Android 14+)',
        path:
            'Settings > Apps > Three-dot menu > Special access > Full screen alerts > turn on LocReminder',
      ),
      OemStep(
        title: 'Show notifications on Lock screen',
        path:
            'Settings > Apps > LocReminder > Notifications > Notification categories > Location alarms > Lock screen > Show content',
      ),
      OemStep(
        title: 'Enable Show as pop-up',
        path:
            'Settings > Apps > LocReminder > Notifications > Notification categories > Location alarms > turn on Show as pop-up',
      ),
    ],
    steps: [
      OemStep(
        title: 'Add to Never sleeping apps',
        path:
            'Settings > Battery > Background usage limits > Never sleeping apps > + > add LocReminder',
      ),
      OemStep(
        title: 'Set battery to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
      OemStep(
        title: 'Allow alarm in Do Not Disturb',
        path:
            'Settings > Notifications > Do not disturb > App notifications > Add LocReminder',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['oppo', 'realme'],
    name: 'Oppo / Realme (ColorOS & Realme UI)',
    modelsHint: 'Oppo Find, Reno, A series & Realme phones',
    note:
        'ColorOS stops background apps and hides lock-screen banners unless explicitly enabled.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen notifications (Android 14+)',
        path:
            'Settings > Apps > Special app access > Full screen notifications > LocReminder > Allow',
      ),
      OemStep(
        title: 'Allow Lock screen & Banner notifications',
        path:
            'Settings > Apps > App management > LocReminder > Manage notifications > Location alarms > enable Lock screen & Banner',
      ),
      OemStep(
        title: 'Allow Display over other apps if prompted',
        path:
            'Settings > Apps > Special app access > Display over other apps > LocReminder',
      ),
    ],
    steps: [
      OemStep(
        title: 'Allow Auto-startup',
        path:
            'Settings > Apps > App management > LocReminder > Allow Auto-startup',
      ),
      OemStep(
        title: 'Allow background activity',
        path:
            'Settings > Battery > App battery management > LocReminder > Allow background activity',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, tap the three-dot menu on LocReminder, tap Lock',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['vivo', 'iqoo'],
    name: 'Vivo / iQOO (FuntouchOS & OriginOS)',
    modelsHint: 'Vivo X, V, Y, T series & iQOO phones',
    note:
        'FuntouchOS restricts lock-screen display and background location unless enabled in Permission Manager.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Display on lock screen & Background pop-ups',
        path:
            'Settings > Apps > View all apps > LocReminder > Permissions > All permissions > enable "Display on lock screen" & "Pop-up window in background"',
      ),
      OemStep(
        title: 'Allow Full screen notifications (Android 14+)',
        path:
            'Settings > Apps > Special app access > Full screen notifications > LocReminder > Allow',
      ),
      OemStep(
        title: 'Enable Lock screen & Floating notifications',
        path:
            'Settings > Apps > LocReminder > Notifications > Location alarms > enable On lock screen & Floating notifications',
      ),
    ],
    steps: [
      OemStep(
        title: 'Allow high background power use',
        path:
            'Settings > Battery > Background power consumption management > LocReminder > High background power usage',
      ),
      OemStep(
        title: 'Allow Autostart & Display on lock screen',
        path:
            'Settings > Apps > Permission manager > Autostart & Display on lock screen > LocReminder',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, swipe down or tap the menu on LocReminder to lock it',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['oneplus'],
    name: 'OnePlus (OxygenOS)',
    modelsHint: 'OnePlus numbered & Nord series',
    note:
        'OxygenOS has extra battery optimization and notification settings that can block lock-screen alarms.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen notifications (Android 14+)',
        path:
            'Settings > Apps > Special app access > Full screen notifications > LocReminder > Allow',
      ),
      OemStep(
        title: 'Enable Lock screen & Banner notifications',
        path:
            'Settings > Apps > App management > LocReminder > Manage notifications > Location alarms > enable Lock screen & Banner',
      ),
    ],
    steps: [
      OemStep(
        title: 'Allow background activity & Don\'t optimize',
        path: 'Settings > Apps > App management > LocReminder > Battery usage > Allow background activity',
      ),
      OemStep(
        title: 'Allow Auto-launch',
        path: 'Settings > Apps > Auto-launch > LocReminder',
      ),
      OemStep(
        title: 'Disable Sleep standby optimization',
        path: 'Settings > Battery > More settings > Sleep standby optimization > Off',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['google', 'pixel'],
    name: 'Google Pixel (Stock Android)',
    modelsHint: 'Pixel series & AOSP / GrapheneOS / LineageOS',
    aggressive: false,
    note:
        'Pixel follows standard Android rules. Ensure Full screen notifications and Unrestricted battery are enabled.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen notifications (Android 14+)',
        path:
            'Settings > Apps > Special app access > Full screen notifications > LocReminder > Allow',
      ),
      OemStep(
        title: 'Show notifications on lock screen',
        path:
            'Settings > Notifications > Notifications on lock screen > Show conversations, default, and silent',
      ),
      OemStep(
        title: 'Enable Pop on screen for Location alarms',
        path:
            'Settings > Apps > See all apps > LocReminder > Notifications > Location alarms > Pop on screen',
      ),
    ],
    steps: [
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > See all apps > LocReminder > App battery usage > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['motorola', 'moto'],
    name: 'Motorola (My UX / Hello UI)',
    modelsHint: 'Moto G, Edge, Razr series',
    aggressive: false,
    note:
        'Motorola follows standard Android rules. Allow Full screen notifications and Unrestricted battery.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen notifications (Android 14+)',
        path:
            'Settings > Apps > Special app access > Full screen notifications > LocReminder > Allow',
      ),
      OemStep(
        title: 'Allow Lock screen & Pop on screen alerts',
        path:
            'Settings > Apps > All apps > LocReminder > Notifications > Location alarms > Pop on screen & Lock screen',
      ),
    ],
    steps: [
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > LocReminder > App battery usage > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['nothing', 'cmf'],
    name: 'Nothing / CMF (Nothing OS)',
    modelsHint: 'Nothing Phone & CMF Phone series',
    aggressive: false,
    note:
        'Nothing OS follows standard Android rules. Enable Full screen notifications and Unrestricted battery.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen notifications (Android 14+)',
        path:
            'Settings > Apps > Special app access > Full screen notifications > LocReminder > Allow',
      ),
      OemStep(
        title: 'Enable Pop on screen & Lock screen display',
        path:
            'Settings > Apps > All apps > LocReminder > Notifications > Location alarms > Pop on screen',
      ),
    ],
    steps: [
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > LocReminder > App battery usage > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['huawei'],
    name: 'Huawei (EMUI & HarmonyOS)',
    modelsHint: 'Huawei Pura, P, Mate, Nova series',
    note: 'EMUI manages app launching strictly and hides lock-screen banners unless enabled.',
    fullScreenSteps: [
      OemStep(
        title: 'Enable Lock screen & Banner notifications',
        path:
            'Settings > Apps > Apps > LocReminder > Notifications > Location alarms > enable Lock screen notifications & Banners',
      ),
      OemStep(
        title: 'Allow Draw over other apps / Dropzone',
        path:
            'Settings > Apps > Apps > LocReminder > Permissions > Dropzone / Draw over other apps > Allow',
      ),
    ],
    steps: [
      OemStep(
        title: 'Set App launch to Manage manually',
        path:
            'Settings > Battery > App launch > LocReminder > Manage manually > turn on Auto-launch, Secondary launch & Run in background',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, swipe down on LocReminder to lock it',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['honor', 'hihonor'],
    name: 'Honor (MagicOS)',
    modelsHint: 'Honor Magic, Numbered & X series',
    note: 'MagicOS manages app launches manually and requires lock-screen & banner permissions.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen notifications & Lock screen alerts',
        path:
            'Settings > Apps > Apps > LocReminder > Notifications > Location alarms > enable Lock screen & Banners',
      ),
      OemStep(
        title: 'Allow Display over other apps',
        path:
            'Settings > Apps > Special access > Display over other apps > LocReminder > Allow',
      ),
    ],
    steps: [
      OemStep(
        title: 'Set App launch to Manage manually',
        path:
            'Settings > Battery > App launch > LocReminder > Manage manually > turn on all three options',
      ),
      OemStep(
        title: 'Set battery to No restrictions',
        path: 'Settings > Apps > Apps > LocReminder > Power usage details > App launch',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['tecno', 'infinix', 'itel'],
    name: 'Tecno / Infinix / itel (HiOS & XOS)',
    modelsHint: 'Tecno Camon, Spark, Pova & Infinix Note, Hot, Zero',
    note: 'Transsion devices use Phone Master which blocks background apps and lock-screen pop-ups.',
    fullScreenSteps: [
      OemStep(
        title: 'Allow Full screen notifications (Android 14+)',
        path:
            'Settings > App management > Special app access > Full screen notifications > LocReminder > Allow',
      ),
      OemStep(
        title: 'Enable Lock screen & Banner notifications',
        path:
            'Settings > App management > App list > LocReminder > Notifications > Location alarms > Lock screen & Banners',
      ),
    ],
    steps: [
      OemStep(
        title: 'Allow Auto-start in Phone Master',
        path: 'Phone Master > Toolbox > Auto-start management > enable LocReminder',
      ),
      OemStep(
        title: 'Set Battery to Unrestricted',
        path: 'Settings > App management > App list > LocReminder > Battery > Unrestricted',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, pull down or tap the lock icon on LocReminder',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['asus'],
    name: 'Asus (ZenUI & ROG UI)',
    modelsHint: 'Zenfone & ROG Phone series',
    note: 'Asus Mobile Manager controls background permissions and lock-screen alerts.',
    fullScreenSteps: _defaultFullScreenSteps,
    steps: [
      OemStep(
        title: 'Allow Auto-start in Mobile Manager',
        path: 'Settings > Battery > PowerMaster > Auto-start Manager > LocReminder > Allow',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['sony', 'nokia', 'hmd', 'fairphone', 'lge'],
    name: 'Sony / Nokia / HMD / Fairphone',
    modelsHint: 'Xperia, Nokia, HMD, Fairphone',
    aggressive: false,
    note: 'Follows standard Android rules. Allow Full screen notifications and Unrestricted battery.',
    fullScreenSteps: _defaultFullScreenSteps,
    steps: [
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['lenovo', 'zte', 'nubia', 'redmagic', 'letv', 'leeco', 'meizu', 'tcl', 'alcatel', 'htc', 'sharp', 'kyocera'],
    name: 'Lenovo / ZTE / Nubia / Meizu / TCL',
    modelsHint: 'Lenovo, ZTE, RedMagic, Meizu, TCL, Sharp',
    note: 'Enable autostart, unrestricted battery, and lock-screen notification display.',
    fullScreenSteps: _defaultFullScreenSteps,
    steps: [
      OemStep(
        title: 'Allow Autostart and background running',
        path: 'Settings > Apps > LocReminder > Autostart / Background settings > Allow',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: [
      'ulefone', 'doogee', 'blackview', 'cubot', 'umidigi', 'oukitel', 'oscal', 'hotwav',
      'walton', 'symphony', 'lava', 'micromax', 'karbonn', 'blu', 'wiko', 'amazon',
    ],
    name: 'MediaTek / DuraSpeed & Other Android Phones',
    modelsHint: 'Lava, Symphony, Walton, Ulefone, Doogee, Blackview, etc.',
    note: 'Disable DuraSpeed or battery savers for LocReminder and allow full-screen notifications.',
    fullScreenSteps: _defaultFullScreenSteps,
    steps: [
      OemStep(
        title: 'Turn DuraSpeed off or allow LocReminder (if present)',
        path: 'Settings > DuraSpeed (or Special features > DuraSpeed) > enable LocReminder',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
];

class OemService {
  OemService({NativeBridge? nativeBridge})
      : _nativeBridge = nativeBridge ?? NativeBridge();

  final NativeBridge _nativeBridge;

  /// Every phone brand's full-screen and background setup guide, so any user
  /// can view instructions for their phone or browse other brands.
  static List<PhoneSetupGuide> get allPhoneGuides => _vendorProfiles
      .map(
        (v) => PhoneSetupGuide(
          name: v.name,
          modelsHint: v.modelsHint,
          fullScreenSteps: v.fullScreenSteps,
          backgroundSteps: v.steps,
        ),
      )
      .toList(growable: false);

  Future<DeviceProfile> profile() async {
    Map<Object?, Object?> info;
    try {
      info = await _nativeBridge.getDeviceInfo();
    } on PlatformException {
      info = const {};
    }

    final manufacturer = (info['manufacturer'] as String? ?? '').trim();
    final brand = (info['brand'] as String? ?? '').trim();
    final model = (info['model'] as String? ?? '').trim();
    final sdkInt = (info['sdkInt'] as int?) ?? 0;
    final lookupKey = '$manufacturer $brand $model'.toLowerCase().trim();

    final vendor = _lookup(lookupKey);

    return DeviceProfile(
      manufacturer: manufacturer.isNotEmpty ? manufacturer : brand,
      model: model,
      sdkInt: sdkInt,
      needsExtraSetup: vendor != null && vendor.aggressive && vendor.steps.isNotEmpty,
      vendorName: (vendor?.name.isNotEmpty ?? false)
          ? vendor!.name
          : _fallbackName(manufacturer.isNotEmpty ? manufacturer : brand),
      steps: vendor?.steps ??
          const [
            OemStep(
              title: 'Set battery usage to Unrestricted',
              path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
            ),
            OemStep(
              title: 'Allow autostart or background running if listed',
              path: 'Settings > Apps > LocReminder > Autostart / Background activity',
            ),
          ],
      fullScreenSteps: vendor?.fullScreenSteps ?? _defaultFullScreenSteps,
      note: vendor?.note ?? _fallbackNote,
    );
  }

  Future<bool> openAutoStartSettings() async {
    try {
      return await _nativeBridge.openAutoStartSettings();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> openLockScreenSettings() async {
    try {
      return await _nativeBridge.openLockScreenSettings();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> openAlarmChannelSettings() async {
    try {
      return await _nativeBridge.openAlarmChannelSettings();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await _nativeBridge.openAppSettings();
    } on PlatformException {
      return false;
    }
  }

  _VendorProfile? _lookup(String key) {
    if (key.isEmpty) return null;
    for (final profile in _vendorProfiles) {
      if (profile.keys.any(key.contains)) return profile;
    }
    return null;
  }

  String _fallbackName(String key) {
    if (key.isEmpty) return 'Your Android phone';
    return key[0].toUpperCase() + key.substring(1);
  }

  static const _fallbackNote =
      'Allow Full-screen notifications, Lock-screen notifications, and Unrestricted battery in Settings so the alarm always wakes your screen.';
}
