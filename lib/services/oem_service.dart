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

  /// Display name for the vendor's OS, e.g. "Xiaomi (MIUI / HyperOS)".
  final String vendorName;
  final List<OemStep> steps;
  final String note;

  String get androidVersionLabel => 'Android API $sdkInt';
}

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
    final needsExtraSetup = (info['needsExtraSetup'] as bool?) ?? false;
    final key = manufacturer.toLowerCase();

    return DeviceProfile(
      manufacturer: manufacturer,
      model: model,
      sdkInt: sdkInt,
      needsExtraSetup: needsExtraSetup,
      vendorName: _vendorName(key),
      steps: _stepsFor(key),
      note: _noteFor(key),
    );
  }

  Future<bool> openAutoStartSettings() => _nativeBridge.openAutoStartSettings();
  Future<bool> openAppSettings() => _nativeBridge.openAppSettings();

  String _vendorName(String key) {
    if (key.contains('xiaomi') || key.contains('redmi') || key.contains('poco')) {
      return 'Xiaomi (MIUI / HyperOS)';
    }
    if (key.contains('samsung')) return 'Samsung (One UI)';
    if (key.contains('oppo') || key.contains('realme')) return 'Oppo / Realme (ColorOS)';
    if (key.contains('vivo') || key.contains('iqoo')) return 'Vivo / iQOO (Funtouch / OriginOS)';
    if (key.contains('oneplus')) return 'OnePlus (OxygenOS)';
    if (key.contains('huawei') || key.contains('honor')) return 'Huawei / Honor (EMUI / MagicOS)';
    if (key.contains('tecno') || key.contains('infinix') || key.contains('itel')) {
      return 'Transsion (HiOS / XOS)';
    }
    if (key.isEmpty) return 'your device';
    return key[0].toUpperCase() + key.substring(1);
  }

  List<OemStep> _stepsFor(String key) {
    if (key.contains('xiaomi') || key.contains('redmi') || key.contains('poco')) {
      return const [
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
      ];
    }
    if (key.contains('samsung')) {
      return const [
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
      ];
    }
    if (key.contains('oppo') || key.contains('realme')) {
      return const [
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
      ];
    }
    if (key.contains('vivo') || key.contains('iqoo')) {
      return const [
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
      ];
    }
    if (key.contains('oneplus')) {
      return const [
        OemStep(
          title: 'Turn off battery optimisation',
          path: "Settings → Apps → LocReminder → Battery → Don't optimise",
        ),
        OemStep(
          title: 'Allow auto-launch',
          path: 'Settings → Apps → Auto-launch → LocReminder',
        ),
        OemStep(
          title: 'Disable Advanced optimisation / Deep optimisation',
          path: 'Settings → Battery → More settings → turn off Advanced optimisation',
        ),
      ];
    }
    if (key.contains('huawei') || key.contains('honor')) {
      return const [
        OemStep(
          title: 'Set app launch to Manage manually',
          path: 'Settings → Battery → App launch → LocReminder → Manage manually → enable all three',
        ),
        OemStep(
          title: 'Turn off Power Genie / battery optimisation',
          path: 'Settings → Battery → More battery settings',
        ),
      ];
    }
    if (key.contains('tecno') || key.contains('infinix') || key.contains('itel')) {
      return const [
        OemStep(
          title: 'Allow autostart',
          path: 'Settings → Apps → LocReminder → Autostart',
        ),
        OemStep(
          title: 'Set battery to No restrictions',
          path: 'Settings → Battery → Background power consumption → LocReminder',
        ),
      ];
    }
    return const [
      OemStep(
        title: 'Allow unrestricted battery usage',
        path: 'Settings → Apps → LocReminder → Battery → Unrestricted',
      ),
    ];
  }

  String _noteFor(String key) {
    if (key.contains('samsung')) {
      return 'Samsung puts apps you have not opened for a few days into '
          '"sleeping", which stops their alarms. Adding LocReminder to '
          '"Never sleeping apps" is the setting that prevents this.';
    }
    if (key.contains('xiaomi') || key.contains('redmi') || key.contains('poco')) {
      return 'MIUI blocks autostart for apps by default and will not restart '
          'background work without it. Autostart plus "No restrictions" are '
          'both needed — one alone is not enough.';
    }
    if (key.contains('huawei') || key.contains('honor')) {
      return 'EMUI resets background permissions during its own maintenance, '
          'so it is worth re-checking these after a system update.';
    }
    return 'These vendor settings sit on top of Android\'s own battery '
        'controls. Granting the in-app permissions alone is not enough on '
        'this device.';
  }
}
