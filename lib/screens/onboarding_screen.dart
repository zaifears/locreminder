import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/oem_service.dart';
import '../services/permission_service.dart';
import '../services/unit_controller.dart';
import 'home_screen.dart';
import 'reliability_screen.dart';

/// First run: a short welcome, then a single checklist that walks through
/// every permission with one button.
///
/// Earlier versions gave each permission its own page of explanation, plus
/// phone-specific menu paths up front. People skimmed, got bored, and gave
/// up. Now each permission gets one line of "why", the longer explanation
/// sits behind a help icon, and phone-specific advice only appears for the
/// step it belongs to, on the phones that need it.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// The four things the alarm needs, in the order Android lets us ask.
enum _Step { location, background, lockScreen, battery }

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  final _oemService = OemService();

  PermissionStatusSummary? _status;
  DeviceProfile? _device;
  bool _showChecklist = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await _permissionService.currentStatus();
    final device = await _oemService.profile();
    if (!mounted) return;
    setState(() {
      _status = status;
      _device = device;
    });
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  bool _isDone(_Step step, PermissionStatusSummary s) => switch (step) {
        _Step.location =>
          s.locationServiceEnabled && s.foregroundLocationGranted,
        _Step.background => s.backgroundLocationGranted,
        _Step.lockScreen => s.notificationsGranted && s.fullScreenIntentAllowed,
        _Step.battery => s.batteryOptimizationDisabled,
      };

  /// The first step still missing. Android requires foreground location
  /// before background, so the order is not cosmetic.
  _Step? _nextStep(PermissionStatusSummary s) {
    for (final step in _Step.values) {
      if (!_isDone(step, s)) return step;
    }
    return null;
  }

  Future<void> _request(_Step step, PermissionStatusSummary s) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      switch (step) {
        case _Step.location:
          await _permissionService.requestForegroundLocation();
        case _Step.background:
          await _permissionService.requestBackgroundLocation();
        case _Step.lockScreen:
          if (!s.notificationsGranted) {
            await _permissionService.requestNotifications();
          } else {
            await _permissionService.requestFullScreenIntent();
          }
        case _Step.battery:
          await _permissionService.requestDisableBatteryOptimization();
      }
    } on PlatformException {
      // A settings screen that will not open must not leave the button
      // disabled; the re-check below shows the true state either way.
    } on MissingPluginException {
      // Same as above.
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    await _refresh();
  }

  Future<void> _openReliability() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReliabilityScreen()),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _showChecklist
              ? _buildChecklist(context, status)
              : _WelcomePage(
                  key: const ValueKey('welcome'),
                  onStart: () => setState(() => _showChecklist = true),
                ),
        ),
      ),
    );
  }

  Widget _buildChecklist(BuildContext context, PermissionStatusSummary status) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final device = _device;
    final next = _nextStep(status);
    final doneCount = _Step.values.where((s) => _isDone(s, status)).length;

    return Column(
      key: const ValueKey('checklist'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _showChecklist = false),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Text(
                    '$doneCount of ${_Step.values.length} done',
                    style: textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                next == null ? 'All set' : 'A few permissions',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                next == null
                    ? 'Your alarm can ring with the app closed and the screen off.'
                    : 'So the alarm rings even when your phone is locked.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: doneCount / _Step.values.length,
                  minHeight: 4,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 20),
              for (final step in _Step.values)
                _ChecklistRow(
                  info: _infoFor(step, status, device),
                  done: _isDone(step, status),
                  current: step == next,
                  onTap: step == next && !_requesting
                      ? () => _request(step, status)
                      : null,
                  // Shown whether or not the row is ticked: on Xiaomi and
                  // similar phones Android can report the full-screen
                  // permission as granted while the maker's own "Show on
                  // Lock screen" switch is still off, and no app can read it.
                  onExtra: step == _Step.lockScreen &&
                          device != null &&
                          device.needsExtraSetup
                      ? () => showAllPhonesFullScreenSheet(
                            context,
                            currentDevice: device,
                          )
                      : null,
                  extraLabel: device == null
                      ? null
                      : 'Extra step on ${device.vendorName}',
                ),
              if (next == null) ...[
                const SizedBox(height: 8),
                _VendorTip(device: device, onTap: _openReliability),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _requesting
                  ? null
                  : next == null
                      ? _finish
                      : () => _request(next, status),
              child: Text(
                next == null
                    ? 'Start using LocReminder'
                    : _infoFor(next, status, device).action,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _StepInfo _infoFor(
    _Step step,
    PermissionStatusSummary status,
    DeviceProfile? device,
  ) {
    switch (step) {
      case _Step.location:
        return _StepInfo(
          icon: Icons.location_on_outlined,
          title: 'Location',
          why: 'To know when you reach your stop.',
          action: status.locationServiceEnabled
              ? 'Allow location'
              : 'Turn on location',
          details:
              'LocReminder compares your GPS position with your destination '
              'and rings when you arrive. Your location never leaves your '
              'phone: there is no account, server, or tracking.',
        );
      case _Step.background:
        return const _StepInfo(
          icon: Icons.nightlight_outlined,
          title: 'Location all the time',
          why: 'So it works with the screen off.',
          hint: 'Pick "Allow all the time" on the next screen.',
          action: 'Allow all the time',
          details:
              'With "Only while using the app", Android stops location '
              'updates as soon as you lock the phone, so the alarm could '
              'never ring while you sleep through the ride.',
        );
      case _Step.lockScreen:
        return _StepInfo(
          icon: Icons.notifications_active_outlined,
          title: 'Alarm on lock screen',
          why: 'To wake the screen and show a Stop button.',
          action: !status.notificationsGranted
              ? 'Allow notifications'
              : (device != null && device.isXiaomi
                  ? 'Allow Lock screen & Pop-ups'
                  : 'Allow full-screen alarm'),
          details:
              'Android uses notification and full-screen permissions to show '
              'the alarm over a locked screen, just like a regular alarm '
              'clock.',
        );
      case _Step.battery:
        return const _StepInfo(
          icon: Icons.battery_saver_outlined,
          title: 'No battery limits',
          why: 'So Android does not pause the alarm.',
          hint: 'Choose "Allow" or "Unrestricted".',
          action: 'Remove battery limits',
          details:
              'With battery optimisation on, Android delays location work '
              'until you next open the app. In testing that meant the alarm '
              'stayed silent for the whole journey. LocReminder only uses '
              'GPS while an alarm is active.',
        );
    }
  }
}

class _StepInfo {
  const _StepInfo({
    required this.icon,
    required this.title,
    required this.why,
    required this.action,
    required this.details,
    this.hint,
  });

  final IconData icon;
  final String title;

  /// One line, always visible.
  final String why;

  /// Shown only while this is the current step: what to tap on the system
  /// screen that follows.
  final String? hint;

  final String action;

  /// The longer explanation, behind the help icon.
  final String details;
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.info,
    required this.done,
    required this.current,
    required this.onTap,
    this.onExtra,
    this.extraLabel,
  });

  final _StepInfo info;
  final bool done;
  final bool current;
  final VoidCallback? onTap;
  final VoidCallback? onExtra;
  final String? extraLabel;

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(
                info.details,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = !done && !current;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: current
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: done
                            ? scheme.primary
                            : scheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : info.icon,
                        size: 22,
                        color: done
                            ? scheme.onPrimary
                            : (muted ? scheme.onSurfaceVariant : scheme.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: muted ? scheme.onSurfaceVariant : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.why,
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showDetails(context),
                      icon: const Icon(Icons.help_outline, size: 20),
                      color: scheme.onSurfaceVariant,
                      tooltip: 'Why?',
                    ),
                  ],
                ),
                if (current && info.hint != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 54, top: 6, right: 10),
                    child: Text(
                      info.hint!,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (onExtra != null && extraLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 46),
                    child: TextButton.icon(
                      onPressed: onExtra,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.smartphone, size: 16),
                      label: Text(extraLabel!),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown once everything is granted: an optional lock-screen test, worded
/// more strongly on phones whose maker adds its own background limits.
class _VendorTip extends StatelessWidget {
  const _VendorTip({required this.device, required this.onTap});

  final DeviceProfile? device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  color: scheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  device != null && device!.needsExtraSetup
                      ? '${device!.vendorName} phones can still stop alarms. '
                          'Check its settings and run a 15-second test.'
                      : 'Optional: run a 15-second lock-screen test.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                        height: 1.4,
                      ),
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onTertiaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unitController = LocReminderApp.unitOf(context);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LocReminder',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pick a place. Put your phone away.\n'
                    'It rings when you arrive.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ValueListenableBuilder<DistanceUnit>(
                    valueListenable: unitController,
                    builder: (context, unit, _) =>
                        SegmentedButton<DistanceUnit>(
                      segments: const [
                        ButtonSegment(value: DistanceUnit.km, label: Text('KM')),
                        ButtonSegment(
                          value: DistanceUnit.miles,
                          label: Text('Miles'),
                        ),
                      ],
                      selected: {unit},
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onSelectionChanged: (s) =>
                          unitController.setUnit(s.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Offline & private · No account',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStart,
                  child: const Text('Get started'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
