import 'package:flutter/material.dart';

import '../main.dart';
import '../services/oem_service.dart';
import '../services/permission_service.dart';
import '../services/unit_controller.dart';
import 'home_screen.dart';
import 'reliability_screen.dart';

/// Greets the user with a clean, scannable introduction followed by four
/// concise permission steps — including phone-specific full-screen alarm
/// setup instructions for every phone brand.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  final _oemService = OemService();
  final _pageController = PageController();

  PermissionStatusSummary? _status;
  DeviceProfile? _device;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
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

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _advanceMissingStep(PermissionStatusSummary status) async {
    if (!status.locationServiceEnabled || !status.foregroundLocationGranted) {
      _goToPage(1);
      return;
    }
    if (!status.backgroundLocationGranted) {
      _goToPage(2);
      return;
    }
    if (!status.notificationsGranted || !status.fullScreenIntentAllowed) {
      _goToPage(3);
      return;
    }
    if (!status.batteryOptimizationDisabled) {
      await _permissionService.requestDisableBatteryOptimization();
      await _refresh();
    }
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
    final device = _device;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final permissionPages = <Widget>[
      _PermissionPage(
        icon: Icons.location_on_outlined,
        title: 'Location access',
        headline: 'Know when you reach your stop.',
        body:
            'LocReminder compares your GPS position against your destination '
            'and rings when you arrive. Your location never leaves your phone.',
        granted:
            status.locationServiceEnabled && status.foregroundLocationGranted,
        grantedLabel: 'Location access granted',
        actionLabel: status.locationServiceEnabled
            ? 'Allow location'
            : 'Turn on location services',
        onRequest: () async {
          await _permissionService.requestForegroundLocation();
          await _refresh();
        },
      ),
      _PermissionPage(
        icon: Icons.nightlight_outlined,
        title: 'Background location',
        headline: 'Choose "Allow all the time" on the next screen.',
        body:
            'So you can lock your phone and sleep through the ride. '
            'If set to "Only while using the app", the alarm cannot ring once '
            'your screen is off.',
        granted: status.backgroundLocationGranted,
        grantedLabel: 'Background location granted',
        actionLabel: 'Open location permission',
        onRequest: () async {
          await _permissionService.requestBackgroundLocation();
          await _refresh();
        },
      ),
      _PermissionPage(
        icon: Icons.notifications_active_outlined,
        title: 'Full-screen alarm display',
        headline: 'Wake and show the Stop button over your lock screen.',
        body:
            'Android uses notification and full-screen permissions to show the '
            'alarm over a locked screen, just like a regular alarm clock.',
        granted: status.notificationsGranted && status.fullScreenIntentAllowed,
        grantedLabel: 'Full-screen alarms ready',
        actionLabel: !status.notificationsGranted
            ? 'Allow notifications'
            : (device != null && device.isXiaomi
                ? 'Allow Lock screen & Pop-ups'
                : 'Allow full-screen alarms'),
        onRequest: () async {
          if (!status.notificationsGranted) {
            await _permissionService.requestNotifications();
          } else {
            await _permissionService.requestFullScreenIntent();
          }
          await _refresh();
        },
        customSection: device == null
            ? null
            : _OnboardingFullScreenGuide(
                device: device,
                onBrowseAllPhones: () =>
                    showAllPhonesFullScreenSheet(context, currentDevice: device),
              ),
      ),
      _PermissionPage(
        icon: Icons.battery_saver_outlined,
        title: 'Unrestricted battery',
        headline: 'Keep Android from putting the alarm to sleep.',
        body:
            'Choose "Unrestricted" or "Don\'t optimize" so Android does not '
            'pause GPS tracking while your screen is locked.',
        granted: status.batteryOptimizationDisabled,
        grantedLabel: 'Battery optimization disabled',
        actionLabel: 'Allow unrestricted battery',
        secondaryNote:
            'Xiaomi, Samsung, Oppo, Vivo, OnePlus, Huawei, and Transsion '
            'phones have extra background settings. Tap below to check your '
            'phone model and run a 15-second lock-screen test.',
        onRequest: () async {
          await _permissionService.requestDisableBatteryOptimization();
          await _refresh();
        },
        extraAction: _openReliability,
        extraActionLabel: 'Phone-specific setup & alarm test',
      ),
    ];

    final allPages = <Widget>[
      const _WelcomePage(),
      ...permissionPages,
    ];

    final isLastPage = _pageIndex == allPages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  for (int i = 0; i < permissionPages.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: EdgeInsets.only(
                          right: i == permissionPages.length - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i < _pageIndex
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _pageIndex == 0
                        ? 'Welcome'
                        : 'Step $_pageIndex of ${permissionPages.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  if (!isLastPage && _pageIndex > 0)
                    TextButton(
                      onPressed: () => _goToPage(allPages.length - 1),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: allPages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_pageIndex > 0)
                    IconButton.filledTonal(
                      onPressed: () => _goToPage(_pageIndex - 1),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  if (_pageIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _pageIndex == 0
                        ? FilledButton(
                            onPressed: () => _goToPage(1),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Start setup'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          )
                        : isLastPage
                            ? FilledButton(
                                onPressed: status.isFullyReady
                                    ? _finish
                                    : () => _advanceMissingStep(status),
                                child: Text(
                                  status.isFullyReady
                                      ? 'Start using LocReminder'
                                      : 'Grant the required permissions',
                                ),
                              )
                            : FilledButton(
                                onPressed: () => _goToPage(_pageIndex + 1),
                                child: const Text('Next'),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unitController = LocReminderApp.unitOf(context);

    return ValueListenableBuilder<DistanceUnit>(
      valueListenable: unitController,
      builder: (context, unit, _) {
        final rangeText = unit == DistanceUnit.miles
            ? '330 ft to 1.9 mi out.'
            : '100 m to 3 km out.';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.20),
                      blurRadius: 16,
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
              const SizedBox(height: 16),
              Text(
                'LocReminder',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reminds you at the right place',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const _StepItem(
                        icon: Icons.place_outlined,
                        title: 'Pick your destination',
                        body: 'Search by name, paste coordinates, or drag the map.',
                      ),
                      const SizedBox(height: 16),
                      _StepItem(
                        icon: Icons.radar_outlined,
                        title: 'Set your distance',
                        body: 'Choose how early to ring — $rangeText',
                      ),
                      const SizedBox(height: 16),
                      const _StepItem(
                        icon: Icons.lock_clock_outlined,
                        title: 'Put your phone away',
                        body: 'Works offline via GPS and wakes your lock screen.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Distance unit:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 10),
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
                    onSelectionChanged: (s) => unitController.setUnit(s.first),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '100% offline & private · No account or tracking',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingFullScreenGuide extends StatelessWidget {
  const _OnboardingFullScreenGuide({
    required this.device,
    required this.onBrowseAllPhones,
  });

  final DeviceProfile device;
  final VoidCallback onBrowseAllPhones;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smartphone, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Full-screen setup for ${device.vendorName}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < device.fullScreenSteps.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${i + 1}. ${device.fullScreenSteps[i].title}\n'
                '   ${device.fullScreenSteps[i].path}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBrowseAllPhones,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.list_alt_outlined, size: 16),
              label: const Text('All phone brands (Samsung, Xiaomi, Pixel, Vivo…)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({
    required this.icon,
    required this.title,
    required this.headline,
    required this.body,
    required this.granted,
    required this.grantedLabel,
    required this.actionLabel,
    required this.onRequest,
    this.secondaryNote,
    this.customSection,
    this.extraAction,
    this.extraActionLabel,
  });

  final IconData icon;
  final String title;
  final String headline;
  final String body;
  final bool granted;
  final String grantedLabel;
  final String actionLabel;
  final VoidCallback onRequest;
  final String? secondaryNote;
  final Widget? customSection;
  final VoidCallback? extraAction;
  final String? extraActionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: granted
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              granted ? Icons.check_rounded : icon,
              size: 36,
              color: granted ? scheme.onPrimaryContainer : scheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            headline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          if (customSection != null) ...[
            const SizedBox(height: 14),
            customSection!,
          ],
          if (secondaryNote != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      secondaryNote!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: granted
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(grantedLabel),
                  )
                : FilledButton(onPressed: onRequest, child: Text(actionLabel)),
          ),
          if (extraAction != null && extraActionLabel != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: extraAction,
                icon: const Icon(Icons.smartphone),
                label: Text(extraActionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
