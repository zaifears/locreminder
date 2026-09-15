import 'package:flutter/material.dart';

import '../services/permission_service.dart';
import 'home_screen.dart';
import 'reliability_screen.dart';

/// Greets the user with a welcome introduction followed by four permission
/// setup pages, each explaining *why* the permission is needed before asking
/// for it. Android only ever shows its own dialog once, so an unexplained
/// prompt that gets dismissed leaves the app permanently broken — the explanation
/// has to come first.
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

    final permissionPages = <_PermissionPage>[
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
        body: 'This one is not optional, and it is the reason most location '
            'alarms fail.\n\n'
            'With battery optimization on, Android puts the app to sleep once '
            'your screen is off and postpones its location work. The alarm '
            'then stays silent for the entire journey and only goes off when '
            'you next unlock and open the app — by which point you have '
            'already gone past your stop.\n\n'
            'On the next screen choose LocReminder, then "Don\'t optimize" or '
            '"Unrestricted".',
        granted: status.batteryOptimizationDisabled,
        grantedLabel: 'Battery optimization disabled',
        actionLabel: 'Open battery settings',
        secondaryNote: 'Phone makers like Xiaomi, Samsung, Oppo, Vivo and '
            'OnePlus add their own app-killer on top of this one. After '
            'finishing setup, open Alarm reliability from the menu — it shows '
            'the exact steps for your model and lets you test the alarm.',
        onRequest: () async {
          await _permissionService.requestDisableBatteryOptimization();
          await _refresh();
        },
        extraAction: _openReliability,
        extraActionLabel: 'Device-specific setup',
      ),
    ];

    final allPages = <Widget>[
      _WelcomePage(onStart: () => _goToPage(1)),
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
                            right: i == permissionPages.length - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i < _pageIndex
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App Logo
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Sleep on the bus. Remember the errand. It goes off when you arrive.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(height: 22),

          // How to use it header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'HOW TO USE IT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
          ),
          const SizedBox(height: 10),

          // Steps Card
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  const _StepItem(
                    number: '1',
                    icon: Icons.search_rounded,
                    title:
                        'Search for where you are going or where do you want me to remind you',
                    body:
                        'Type a place name, paste coordinates, or drag the map under the pin. No account needed.',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  const _StepItem(
                    number: '2',
                    icon: Icons.adjust_rounded,
                    title: 'Choose the radius you want to be notified',
                    body:
                        'Anywhere from 100 m to 3 km out. A bigger radius gives you more time to gather your things.',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  const _StepItem(
                    number: '3',
                    icon: Icons.alarm_on_rounded,
                    title: 'Put your phone away',
                    body: 'When you arrive, the alarm rings.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Privacy badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '100% offline & private. Zero data leaves your phone.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
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
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
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
  final VoidCallback? extraAction;
  final String? extraActionLabel;

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
          if (extraAction != null && extraActionLabel != null) ...[
            const SizedBox(height: 12),
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
