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

class DeviceProfile {
  const DeviceProfile({
    required this.manufacturer,
    required this.model,
    required this.sdkInt,
    required this.needsExtraSetup,
    required this.vendorName,
    required this.steps,
    required this.note,
  });

  final String manufacturer;
  final String model;
  final int sdkInt;

  /// True for vendors that restrict background services beyond standard Android.
  final bool needsExtraSetup;

  /// Display name for the manufacturer or software skin.
  final String vendorName;
  final List<OemStep> steps;
  final String note;
}

class _VendorProfile {
  const _VendorProfile({
    required this.keys,
    required this.name,
    required this.note,
    this.steps = const [],
    this.aggressive = true,
  });

  final List<String> keys;
  final String name;
  final String note;
  final List<OemStep> steps;
  final bool aggressive;
}

const _vendorProfiles = <_VendorProfile>[
  _VendorProfile(
    keys: ['xiaomi', 'redmi', 'poco'],
    name: 'Xiaomi (MIUI / HyperOS)',
    note: 'MIUI requires Autostart and No restrictions so the alarm can wake your phone on arrival.',
    steps: [
      OemStep(
        title: 'Turn on Autostart',
        path: 'Settings > Apps > Manage apps > LocReminder > Autostart',
      ),
      OemStep(
        title: 'Set battery saver to No restrictions',
        path: 'Settings > Apps > Manage apps > LocReminder > Battery saver > No restrictions',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, pull down on LocReminder, tap the lock icon',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['samsung'],
    name: 'Samsung (One UI)',
    note: 'One UI puts unused apps to sleep. Add LocReminder to Never sleeping apps so alarms fire on time.',
    steps: [
      OemStep(
        title: 'Add to Never sleeping apps',
        path: 'Settings > Battery > Background usage limits > Never sleeping apps > add LocReminder',
      ),
      OemStep(
        title: 'Remove from Sleeping apps if listed',
        path: 'Settings > Battery > Background usage limits > Sleeping apps',
      ),
      OemStep(
        title: 'Set battery to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['oppo', 'realme'],
    name: 'Oppo / Realme (ColorOS)',
    note: 'ColorOS stops background apps unless auto-startup and background running are enabled.',
    steps: [
      OemStep(
        title: 'Allow Auto-startup',
        path: 'Settings > Apps > App management > LocReminder > Allow Auto-startup',
      ),
      OemStep(
        title: 'Allow background running',
        path: 'Settings > Battery > App battery management > LocReminder > Allow background running',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, tap the card menu, tap Lock',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['vivo', 'iqoo'],
    name: 'Vivo / iQOO (Funtouch / OriginOS)',
    note: 'Funtouch restricts continuous background location unless power consumption is set to high.',
    steps: [
      OemStep(
        title: 'Allow high background power use',
        path: 'Settings > Battery > High background power consumption > LocReminder',
      ),
      OemStep(
        title: 'Allow autostart',
        path: 'Settings > Apps > Permission manager > Autostart > LocReminder',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, swipe down on LocReminder to lock it',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['oneplus'],
    name: 'OnePlus (OxygenOS)',
    note: 'OxygenOS has extra battery optimization options that can stop background tracking.',
    steps: [
      OemStep(
        title: 'Turn off battery optimization',
        path: 'Settings > Apps > LocReminder > Battery > Don\'t optimize',
      ),
      OemStep(
        title: 'Allow auto-launch',
        path: 'Settings > Apps > Auto-launch > LocReminder',
      ),
      OemStep(
        title: 'Disable Advanced optimization',
        path: 'Settings > Battery > More settings > turn off Advanced optimization',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['huawei'],
    name: 'Huawei (EMUI / HarmonyOS)',
    note: 'EMUI manages app launching strictly and may reset settings after updates.',
    steps: [
      OemStep(
        title: 'Set app launch to Manage manually',
        path: 'Settings > Battery > App launch > LocReminder > Manage manually > turn on all options',
      ),
      OemStep(
        title: 'Turn off power saving optimizations',
        path: 'Settings > Battery > More battery settings',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, swipe down on LocReminder to lock it',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['honor'],
    name: 'Honor (MagicOS)',
    note: 'MagicOS manages app launches manually to prevent background location stops.',
    steps: [
      OemStep(
        title: 'Set app launch to Manage manually',
        path: 'Settings > Battery > App launch > LocReminder > Manage manually > turn on all options',
      ),
      OemStep(
        title: 'Set battery to No restrictions',
        path: 'Settings > Apps > LocReminder > Battery > No restrictions',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['meizu'],
    name: 'Meizu (Flyme)',
    note: 'Flyme uses dedicated autostart and standby lists for background tasks.',
    steps: [
      OemStep(
        title: 'Allow autostart',
        path: 'Settings > Apps > Permission management > Autostart > LocReminder',
      ),
      OemStep(
        title: 'Allow background running in standby',
        path: 'Settings > Battery > Standby management > LocReminder > allow background',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['asus'],
    name: 'Asus (ZenUI)',
    note: 'ZenUI uses Mobile Manager to handle background app permissions.',
    steps: [
      OemStep(
        title: 'Allow auto-start',
        path: 'Mobile Manager > Auto-start Manager > LocReminder > Allow',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['tecno', 'infinix', 'itel'],
    name: 'Transsion (HiOS / XOS)',
    note: 'Transsion devices use Phone Master which can stop background apps.',
    steps: [
      OemStep(
        title: 'Allow autostart',
        path: 'Settings > Apps > LocReminder > Autostart',
      ),
      OemStep(
        title: 'Set battery to No restrictions',
        path: 'Settings > Battery > Background power consumption > LocReminder',
      ),
      OemStep(
        title: 'Add to protected list in Phone Master',
        path: 'Phone Master > Power saving > Protected apps > LocReminder',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['lenovo', 'zte', 'nubia', 'letv', 'leeco'],
    name: 'Lenovo / ZTE / LeEco',
    note: 'These skins keep a background autostart list separate from standard settings.',
    steps: [
      OemStep(
        title: 'Allow autostart and background running',
        path: 'Settings > Apps > LocReminder > Autostart or Background settings',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings > Battery > LocReminder > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['tcl', 'alcatel'],
    name: 'TCL / Alcatel',
    note: 'TCL devices require disabling battery optimization and allowing autostart.',
    steps: [
      OemStep(
        title: 'Set battery use to Don\'t optimize',
        path: 'Settings > Battery > Battery optimisation > LocReminder > Don\'t optimise',
      ),
      OemStep(
        title: 'Allow autostart if available',
        path: 'Settings > Apps > LocReminder > Autostart',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['htc'],
    name: 'HTC (Sense)',
    note: 'HTC Boost+ can stop background apps unless LocReminder is excluded.',
    steps: [
      OemStep(
        title: 'Set battery optimization to Don\'t optimize',
        path: 'Settings > Battery > Battery optimisation > LocReminder',
      ),
      OemStep(
        title: 'Exclude from Boost+',
        path: 'Boost+ > Optimise background apps > untick LocReminder',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['sharp', 'kyocera'],
    name: 'Sharp / Kyocera',
    note: 'Eco and long-life modes pause background location unless excluded.',
    steps: [
      OemStep(
        title: 'Exclude from battery saver',
        path: 'Settings > Battery > Eco mode or Long life battery > exclude LocReminder',
      ),
      OemStep(
        title: 'Set battery optimization to Don\'t optimize',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['ulefone', 'doogee', 'blackview', 'cubot', 'umidigi', 'oukitel', 'oscal', 'hotwav'],
    name: 'MediaTek-based device',
    note: 'DuraSpeed pauses background apps when the screen is off.',
    steps: [
      OemStep(
        title: 'Turn DuraSpeed off or allow LocReminder',
        path: 'Settings > DuraSpeed (or Special features > DuraSpeed)',
      ),
      OemStep(
        title: 'Set battery use to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['amazon'],
    name: 'Amazon (Fire OS)',
    note: 'Fire OS limits background activity when battery saver is active.',
    steps: [
      OemStep(
        title: 'Turn off battery optimization',
        path: 'Settings > Apps & Notifications > LocReminder > Advanced > Battery',
      ),
      OemStep(
        title: 'Turn off Low Power Mode while armed',
        path: 'Settings > Battery > Low Power Mode',
      ),
    ],
  ),
  _VendorProfile(
    keys: [
      'walton', 'symphony', 'lava', 'micromax', 'karbonn', 'blu', 'wiko',
      'energizer', 'vsmart', 'coolpad', 'gionee', 'panasonic', 'xolo',
    ],
    name: '',
    note: 'Standard Android background rules apply. Make sure battery optimization is turned off.',
    steps: [
      OemStep(
        title: 'Set battery use to Unrestricted',
        path: 'Settings > Apps > LocReminder > Battery > Unrestricted',
      ),
      OemStep(
        title: 'Check phone manager if installed',
        path: 'Look for protected apps, autostart, or background activity settings',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['google', 'motorola', 'lge', 'sony', 'nokia', 'hmd', 'nothing', 'fairphone'],
    name: 'Standard Android',
    aggressive: false,
    note: 'This device follows standard Android rules. The permissions above are all you need.',
  ),
];

class OemService {
  OemService({NativeBridge? nativeBridge})
      : _nativeBridge = nativeBridge ?? NativeBridge();

  final NativeBridge _nativeBridge;

  Future<DeviceProfile> profile() async {
    Map<Object?, Object?> info;
    try {
      info = await _nativeBridge.getDeviceInfo();
    } on PlatformException {
      info = const {};
    }

    final manufacturer = (info['manufacturer'] as String? ?? '').trim();
    final model = (info['model'] as String? ?? '').trim();
    final sdkInt = (info['sdkInt'] as int?) ?? 0;
    final key = manufacturer.toLowerCase();

    final vendor = _lookup(key);

    return DeviceProfile(
      manufacturer: manufacturer,
      model: model,
      sdkInt: sdkInt,
      needsExtraSetup: vendor != null && vendor.aggressive && vendor.steps.isNotEmpty,
      vendorName: (vendor?.name.isNotEmpty ?? false)
          ? vendor!.name
          : _fallbackName(key),
      steps: vendor?.steps ?? const [],
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
    if (key.isEmpty) return 'Your device';
    return key[0].toUpperCase() + key.substring(1);
  }

  static const _fallbackNote =
      'Look for autostart, background activity, protected apps, or unrestricted battery in settings and allow LocReminder.';
}
