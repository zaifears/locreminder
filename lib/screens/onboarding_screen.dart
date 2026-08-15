import 'package:flutter/material.dart';

import '../services/permission_service.dart';
import 'home_screen.dart';

/// Four full-screen pages, one per permission, each explaining *why* the
/// permission is needed before asking for it. Android only ever shows its
/// own dialog once, so an unexplained prompt that gets dismissed leaves the
/// app permanently broken — the explanation has to come first.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  final _pageController = PageController();

  PermissionStatusSummary? _status;
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
    // Several of these are granted in system settings rather than a dialog,
    // so re-check whenever the user comes back to the app.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await _permissionService.currentStatus();
    if (mounted) setState(() => _status = status);
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

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <_PermissionPage>[
      _PermissionPage(
        icon: Icons.location_on_outlined,
        title: 'Find where you are',
        headline: 'LocReminder needs your location.',
        body: "That's the whole trick: the app compares where you are against "
            'where you want to be woken up, and rings when the two match.\n\n'
            'Your location never leaves your phone. There is no account, no '
            'server, and nothing is uploaded anywhere — this app has no '
            'internet backend at all.',
        granted: status.locationServiceEnabled && status.foregroundLocationGranted,
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
        title: 'Keep watch while you rest',
        headline: 'Choose "Allow all the time" on the next screen.',
        body: 'This is the most important one, and the easiest to get wrong.\n\n'
            'The entire point of LocReminder is that you can put your phone in '
            'your pocket and sleep through the ride. Android only lets the '
            'alarm fire while the app is closed if you pick "Allow all the '
            'time".\n\n'
            'If you pick "Only while using the app", everything will look fine '
            '— but the alarm will never go off once you lock your screen.',
        granted: status.backgroundLocationGranted,
        grantedLabel: 'Background location granted',
        actionLabel: 'Open location settings',
        onRequest: () async {
          await _permissionService.requestBackgroundLocation();
          await _refresh();
        },
      ),
      _PermissionPage(
        icon: Icons.notifications_active_outlined,
        title: 'Show the alarm on screen',
        headline: 'LocReminder needs to post notifications.',
        body: 'When you arrive, the app takes over your screen with a '
            'full-screen alarm and a Stop button — like a normal alarm clock, '
            'even over the lock screen.\n\n'
            'Android treats that as a notification. Without this permission '
            'the alarm may make noise with no way to see or silence it.',
        granted: status.notificationsGranted && status.fullScreenIntentAllowed,
        grantedLabel: 'Notifications granted',
        actionLabel: status.notificationsGranted
            ? 'Allow full-screen alarms'
            : 'Allow notifications',
        secondaryNote: status.notificationsGranted && !status.fullScreenIntentAllowed
            ? 'One more step: Android 14 and newer ask separately for '
                'permission to show full-screen alarms.'
            : null,
        onRequest: () async {
          if (!status.notificationsGranted) {
            await _permissionService.requestNotifications();
          } else {
            await _permissionService.requestFullScreenIntent();
          }
          await _refresh();
        },
      ),
      _PermissionPage(
        icon: Icons.battery_saver_outlined,
        title: "Don't let Android doze off",
        headline: 'Turn off battery optimization for LocReminder.',
        body: 'Android aggressively suspends background apps to save power. '
            'For most apps that is fine. For an alarm it means the ring can '
            'arrive several minutes late — long past your stop.\n\n'
            'This costs very little battery: LocReminder uses the system\'s '
            'built-in geofencing, so it is not running or polling GPS in the '
            'background. It stays asleep until Android itself wakes it.',
        granted: status.batteryOptimizationDisabled,
        grantedLabel: 'Battery optimization disabled',
        actionLabel: 'Open battery settings',
        optional: true,
        onRequest: () async {
          await _permissionService.requestDisableBatteryOptimization();
          await _refresh();
        },
      ),
    ];

    final isLastPage = _pageIndex == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  for (int i = 0; i < pages.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: EdgeInsets.only(right: i == pages.length - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _pageIndex
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    'Step ${_pageIndex + 1} of ${pages.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  if (!isLastPage)
                    TextButton(
                      onPressed: () => _goToPage(pages.length - 1),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: pages,
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
                    child: isLastPage
                        ? FilledButton(
                            onPressed: status.isFullyReady ? _finish : null,
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
    this.optional = false,
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
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: granted ? scheme.primaryContainer : scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              granted ? Icons.check_rounded : icon,
              size: 44,
              color: granted ? scheme.onPrimaryContainer : scheme.primary,
            ),
          ),
          const SizedBox(height: 28),
          if (optional)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Recommended',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            headline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          if (secondaryNote != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      secondaryNote!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
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
        ],
      ),
    );
  }
}
