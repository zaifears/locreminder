import 'package:flutter/services.dart';

import 'native_bridge.dart';

/// One manufacturer-specific step the user has to perform by hand.
class OemStep {
  const OemStep({required this.title, required this.path});

  /// What the setting achieves, in the user's terms.
  final String title;

  /// Where to find it, using the vendor's own menu wording.
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

  /// True for vendors that kill background work beyond stock Android's rules.
  final bool needsExtraSetup;

  /// Display name for the vendor's OS, e.g. "Xiaomi (MIUI / HyperOS)", or
  /// the manufacturer's own name where the profile covers several brands.
  final String vendorName;
  final List<OemStep> steps;
  final String note;
}

/// A manufacturer, the name of its Android skin, and what it takes to stop
/// that skin killing a background alarm.
class _VendorProfile {
  const _VendorProfile({
    required this.keys,
    required this.name,
    required this.note,
    this.steps = const [],
    this.aggressive = true,
  });

  /// Lowercase substrings matched against `Build.MANUFACTURER`.
  final List<String> keys;
  final String name;
  final String note;
  final List<OemStep> steps;

  /// Whether this vendor restricts background apps beyond stock Android.
  final bool aggressive;
}

/// Every vendor we have specific guidance for.
///
/// Deliberately one table rather than parallel switches on name, steps and
/// notes: those drift apart silently, and a device being told it "needs
/// extra setup" while being shown only generic advice is worse than saying
/// nothing.
const _vendorProfiles = <_VendorProfile>[
  _VendorProfile(
    keys: ['xiaomi', 'redmi', 'poco'],
    name: 'Xiaomi (MIUI / HyperOS)',
    note: 'MIUI blocks autostart for apps by default and will not restart '
        'background work without it. Autostart plus "No restrictions" are '
        'both needed — one alone is not enough.',
    steps: [
      OemStep(
        title: 'Turn on Autostart',
        path: 'Settings → Apps → Manage apps → LocReminder → Autostart',
      ),
      OemStep(
        title: 'Set battery saver to No restrictions',
        path: 'Settings → Apps → Manage apps → LocReminder → Battery saver → No restrictions',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, pull down on the LocReminder card, tap the padlock',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['samsung'],
    name: 'Samsung (One UI)',
    note: 'Samsung puts apps you have not opened for a few days into '
        '"sleeping", which stops their alarms. Adding LocReminder to '
        '"Never sleeping apps" is the setting that prevents this.',
    steps: [
      OemStep(
        title: 'Add to Never sleeping apps',
        path: 'Settings → Battery → Background usage limits → Never sleeping apps → add LocReminder',
      ),
      OemStep(
        title: 'Make sure it is not in Sleeping or Deep sleeping apps',
        path: 'Settings → Battery → Background usage limits → Sleeping apps',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings → Apps → LocReminder → Battery → Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['oppo', 'realme'],
    name: 'Oppo / Realme (ColorOS)',
    note: 'ColorOS stops background apps unless they are given both '
        'auto-startup and permission to keep running in the background.',
    steps: [
      OemStep(
        title: 'Allow Auto-startup',
        path: 'Settings → Apps → App management → LocReminder → Allow Auto-startup',
      ),
      OemStep(
        title: 'Allow background running',
        path: 'Settings → Battery → App battery management → LocReminder → Allow background running',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, tap the menu on the LocReminder card, tap Lock',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['vivo', 'iqoo'],
    name: 'Vivo / iQOO (Funtouch / OriginOS)',
    note: 'Funtouch treats steady background location as "high power '
        'consumption" and cuts it off unless the app is allowed explicitly.',
    steps: [
      OemStep(
        title: 'Allow high background power consumption',
        path: 'Settings → Battery → High background power consumption → LocReminder',
      ),
      OemStep(
        title: 'Allow autostart',
        path: 'Settings → Apps → Permission manager → Autostart → LocReminder',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, swipe down on the LocReminder card to lock it',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['oneplus'],
    name: 'OnePlus (OxygenOS)',
    note: 'OxygenOS has a second layer of "advanced" optimization on top of '
        'the standard battery setting, and it needs turning off separately.',
    steps: [
      OemStep(
        title: 'Turn off battery optimization',
        path: "Settings → Apps → LocReminder → Battery → Don't optimize",
      ),
      OemStep(
        title: 'Allow auto-launch',
        path: 'Settings → Apps → Auto-launch → LocReminder',
      ),
      OemStep(
        title: 'Disable Advanced optimization / Deep optimization',
        path: 'Settings → Battery → More settings → turn off Advanced optimization',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['huawei'],
    name: 'Huawei (EMUI / HarmonyOS)',
    note: 'EMUI resets background permissions during its own maintenance, so '
        'it is worth re-checking these after a system update.',
    steps: [
      OemStep(
        title: 'Set app launch to Manage manually',
        path: 'Settings → Battery → App launch → LocReminder → Manage manually → enable all three',
      ),
      OemStep(
        title: 'Turn off Power Genie / battery optimization',
        path: 'Settings → Battery → More battery settings',
      ),
      OemStep(
        title: 'Lock the app in Recents',
        path: 'Open Recents, swipe down on the LocReminder card to lock it',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['honor'],
    name: 'Honor (MagicOS)',
    note: 'MagicOS keeps Huawei-style app-launch controls. Its menus moved '
        'after Honor split from Huawei, so the wording may differ slightly '
        'from older guides.',
    steps: [
      OemStep(
        title: 'Set app launch to Manage manually',
        path: 'Settings → Battery → App launch → LocReminder → Manage manually → enable all three',
      ),
      OemStep(
        title: 'Turn off battery optimization',
        path: 'Settings → Apps → LocReminder → Battery → No restrictions',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['meizu'],
    name: 'Meizu (Flyme)',
    note: 'Flyme keeps its own standby and autostart lists, separate from '
        'Android\'s battery settings.',
    steps: [
      OemStep(
        title: 'Allow autostart',
        path: 'Settings → Apps → Permission management → Autostart → LocReminder',
      ),
      OemStep(
        title: 'Turn off standby management',
        path: 'Settings → Battery → Standby management → LocReminder → allow background',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['asus'],
    name: 'Asus (ZenUI)',
    note: 'ZenUI ships a Mobile Manager app that manages autostart separately '
        'from Android\'s own settings.',
    steps: [
      OemStep(
        title: 'Allow auto-start',
        path: 'Mobile Manager → Auto-start Manager → LocReminder → Allow',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings → Apps → LocReminder → Battery → Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['tecno', 'infinix', 'itel'],
    name: 'Transsion (HiOS / XOS)',
    note: 'These devices ship a Phone Master app whose power saving overrides '
        'Android\'s own battery settings.',
    steps: [
      OemStep(
        title: 'Allow autostart',
        path: 'Settings → Apps → LocReminder → Autostart',
      ),
      OemStep(
        title: 'Set battery to No restrictions',
        path: 'Settings → Battery → Background power consumption → LocReminder',
      ),
      OemStep(
        title: 'Add to the protected list in Phone Master',
        path: 'Phone Master → Power saving → Protected apps → LocReminder',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['lenovo', 'zte', 'nubia', 'letv', 'leeco'],
    name: 'Lenovo / ZTE / LeEco',
    note: 'These skins keep a background autostart list separate from '
        'Android\'s battery settings; an app missing from it gets stopped.',
    steps: [
      OemStep(
        title: 'Allow autostart / background running',
        path: 'Settings → Apps → LocReminder → Autostart (or Background settings)',
      ),
      OemStep(
        title: 'Set battery usage to Unrestricted',
        path: 'Settings → Battery → LocReminder → Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['tcl', 'alcatel'],
    name: 'TCL / Alcatel',
    note: 'TCL devices pair Android's own battery optimisation with a '
        'separate manager app, and being allowed by one does not mean being '
        'allowed by the other.',
    steps: [
      OemStep(
        title: 'Set battery use to Unrestricted',
        path: 'Settings → Battery → Battery optimisation → LocReminder → Don't optimise',
      ),
      OemStep(
        title: 'Allow it to start automatically',
        path: 'Settings → Apps → LocReminder → Autostart, if your model has it',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['htc'],
    name: 'HTC (Sense)',
    note: 'HTC's Boost+ app has its own list of apps it is allowed to close, '
        'which is separate from Android's battery settings.',
    steps: [
      OemStep(
        title: 'Set battery optimisation to Don't optimise',
        path: 'Settings → Battery → Battery optimisation → LocReminder',
      ),
      OemStep(
        title: 'Exclude it from Boost+',
        path: 'Boost+ → Optimise background apps → untick LocReminder',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['sharp', 'kyocera'],
    name: 'Sharp / Kyocera',
    note: 'These models ship an eco or long-life battery mode that suspends '
        'background apps more aggressively than stock Android does.',
    steps: [
      OemStep(
        title: 'Exclude it from the battery saver',
        path: 'Settings → Battery → Eco mode (or Long life battery) → exclude LocReminder',
      ),
      OemStep(
        title: 'Set battery optimisation to Don't optimise',
        path: 'Settings → Apps → LocReminder → Battery → Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['ulefone', 'doogee', 'blackview', 'cubot', 'umidigi', 'oukitel', 'oscal', 'hotwav'],
    name: 'MediaTek-based device',
    note: 'Phones built on MediaTek's reference software usually ship '
        'DuraSpeed, which closes background apps to speed up the foreground '
        'one. It is separate from Android's battery settings and switched on '
        'by default.',
    steps: [
      OemStep(
        title: 'Turn DuraSpeed off, or allow LocReminder in it',
        path: 'Settings → DuraSpeed (or Settings → Special features → DuraSpeed)',
      ),
      OemStep(
        title: 'Set battery use to Unrestricted',
        path: 'Settings → Apps → LocReminder → Battery → Unrestricted',
      ),
    ],
  ),
  _VendorProfile(
    keys: ['amazon'],
    name: 'Amazon (Fire OS)',
    note: 'Fire OS restricts background apps on its own terms, and has no '
        'Google location services at all. LocReminder does not need them, but '
        'the background limits still apply.',
    steps: [
      OemStep(
        title: 'Turn off battery optimisation for it',
        path: 'Settings → Apps & Notifications → LocReminder → Advanced → Battery',
      ),
      OemStep(
        title: 'Turn off Low Power Mode while an alarm is armed',
        path: 'Settings → Battery → Low Power Mode',
      ),
    ],
  ),
  // Brands that ship close to stock Android but still carry a battery
  // optimiser worth checking. Named individually so a user in one of these
  // markets sees their own phone recognised rather than a shrug.
  _VendorProfile(
    keys: [
      'walton', 'symphony', 'lava', 'micromax', 'karbonn', 'blu', 'wiko',
      'energizer', 'vsmart', 'coolpad', 'gionee', 'panasonic', 'xolo',
    ],
    // Empty so the phone's own manufacturer name is shown. This entry covers
    // a dozen unrelated brands across as many markets, and a Walton owner
    // should see "Walton" rather than a label invented to cover the group.
    name: '',
    note: 'This brand ships close to stock Android, so there is usually no '
        'vendor app to fight. The one setting that still matters is Android's '
        'own battery optimisation, which is on by default for every app.',
    steps: [
      OemStep(
        title: 'Set battery use to Unrestricted',
        path: 'Settings → Apps → LocReminder → Battery → Unrestricted',
      ),
      OemStep(
        title: 'If your phone has a power or phone manager app, allow it there too',
        path: 'Look for "protected apps", "autostart" or "background activity"',
      ),
    ],
  ),
  // Vendors that follow stock Android closely. Listed so the app can name
  // them and say plainly that no extra work is needed, rather than nagging.
  _VendorProfile(
    keys: ['google', 'motorola', 'lge', 'sony', 'nokia', 'hmd', 'nothing', 'fairphone'],
    name: 'stock Android',
    aggressive: false,
    note: 'This manufacturer follows Android\'s standard background rules, so '
        'the permissions above should be all you need.',
  ),
];

/// Works out which vendor-specific background restrictions apply to this
/// exact phone, and what the user must do about them.
///
/// This is unavoidable rather than defensive programming: Xiaomi, Samsung,
/// Oppo, Vivo, OnePlus and Huawei each run their own app-killer on top of
/// Android, none of them expose an API to opt out, and an app that is not
/// whitelisted in them gets stopped regardless of the permissions the
/// platform has granted. Telling the user exactly which switch to flip on
/// their model is the only real remedy.
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
      // Driven by whether we actually have advice to give, so the app can
      // never warn about a device and then have nothing useful to show.
      needsExtraSetup: vendor != null && vendor.aggressive && vendor.steps.isNotEmpty,
      vendorName: (vendor?.name.isNotEmpty ?? false)
          ? vendor!.name
          : _fallbackName(key),
      steps: vendor?.steps ?? const [],
      note: vendor?.note ?? _fallbackNote,
    );
  }

  Future<bool> openAutoStartSettings() => _nativeBridge.openAutoStartSettings();
  Future<bool> openAppSettings() => _nativeBridge.openAppSettings();

  _VendorProfile? _lookup(String key) {
    if (key.isEmpty) return null;
    for (final profile in _vendorProfiles) {
      if (profile.keys.any(key.contains)) return profile;
    }
    return null;
  }

  String _fallbackName(String key) {
    if (key.isEmpty) return 'your device';
    return key[0].toUpperCase() + key.substring(1);
  }

  /// Shown for a manufacturer with no entry in the table above.
  ///
  /// Deliberately still actionable. There are hundreds of Android brands and
  /// this app is used well beyond the dozen with the largest market shares,
  /// so an unrecognised phone is a normal case rather than an edge one, and
  /// telling that user nothing is the one outcome worth avoiding.
  static const _fallbackNote =
      'We have no notes specific to this manufacturer. Nearly every Android '
      'skin has a setting under some name that stops background apps, so if '
      'an alarm is ever late, look for "autostart", "background activity", '
      '"protected apps" or "unrestricted battery" and allow LocReminder in '
      'whichever of them your phone has.';
}
