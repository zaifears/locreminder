import 'package:flutter/material.dart';

import '../services/native_bridge.dart';
import '../services/oem_service.dart';
import '../services/permission_service.dart';

/// Everything that governs whether an alarm will actually ring, in one place:
/// the platform permissions, this phone's own vendor restrictions, and a test
/// that proves the alarm can break through a locked screen.
///
/// The point is to surface failures at home rather than on a train.
class ReliabilityScreen extends StatefulWidget {
  const ReliabilityScreen({super.key});

  @override
  State<ReliabilityScreen> createState() => _ReliabilityScreenState();
}

class _ReliabilityScreenState extends State<ReliabilityScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  final _oemService = OemService();
  final _nativeBridge = NativeBridge();

  PermissionStatusSummary? _permissions;
  DeviceProfile? _device;
  bool _watchRunning = false;

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
    final permissions = await _permissionService.currentStatus();
    final device = await _oemService.profile();
    final watching = await _nativeBridge.isLocationWatchRunning();
    if (!mounted) return;
    setState(() {
      _permissions = permissions;
      _device = device;
      _watchRunning = watching;
    });
  }

  Future<void> _runTestAlarm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.science_outlined),
        title: const Text('Test the alarm'),
        content: const Text(
          'The alarm will ring in 15 seconds.\n\n'
          'Lock your phone now and put it down. If the alarm sounds and its '
          'screen appears over your lock screen, background alarms work on '
          'this device.\n\n'
          'If nothing happens, your phone is blocking the app — work through '
          'the steps on this page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start test'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _nativeBridge.triggerTestAlarm(delaySeconds: 15);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lock your phone now — the alarm rings in 15 seconds.'),
        duration: Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = _permissions;
    final device = _device;

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm reliability')),
      body: permissions == null || device == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _StatusHeader(
                  ready: permissions.isFullyReady,
                  watching: _watchRunning,
                ),
                const SizedBox(height: 24),
                const _Section(label: 'Android permissions'),
                Card(
                  child: Column(
                    children: [
                      _CheckRow(
                        title: 'Location "Allow all the time"',
                        granted: permissions.backgroundLocationGranted,
                        onFix: () async {
                          await _permissionService.requestBackgroundLocation();
                          await _refresh();
                        },
                      ),
                      const Divider(height: 1),
                      _CheckRow(
                        title: 'Notifications',
                        granted: permissions.notificationsGranted,
                        onFix: () async {
                          await _permissionService.requestNotifications();
                          await _refresh();
                        },
                      ),
                      const Divider(height: 1),
                      _CheckRow(
                        title: 'Full-screen alarms',
                        granted: permissions.fullScreenIntentAllowed,
                        onFix: () async {
                          await _permissionService.requestFullScreenIntent();
                          await _refresh();
                        },
                      ),
                      const Divider(height: 1),
                      _CheckRow(
                        title: 'Battery optimisation off',
                        granted: permissions.batteryOptimizationDisabled,
                        onFix: () async {
                          await _permissionService.requestDisableBatteryOptimization();
                          await _refresh();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _Section(label: 'Your device'),
                _DeviceCard(
                  device: device,
                  onOpenAutoStart: () async {
                    final opened = await _oemService.openAutoStartSettings();
                    if (!opened) await _oemService.openAppSettings();
                    await _refresh();
                  },
                ),
                const SizedBox(height: 24),
                const _Section(label: 'Prove it works'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test the alarm from a locked screen',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rings the real alarm after 15 seconds so you can '
                          'lock your phone and see whether it gets through. '
                          'Much better to find out here than on the bus.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: _runTestAlarm,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Run alarm test'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.ready, required this.watching});

  final bool ready;
  final bool watching;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final good = ready;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: good ? scheme.primaryContainer : scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            good ? Icons.verified_outlined : Icons.error_outline,
            size: 40,
            color: good ? scheme.onPrimaryContainer : scheme.onErrorContainer,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  good ? 'Ready to wake you' : 'Alarms may not ring',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: good ? scheme.onPrimaryContainer : scheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  good
                      ? (watching
                          ? 'Watching for your destination now.'
                          : 'Everything is granted. Tracking starts when you arm an alarm.')
                      : 'Some required permissions are missing.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: good ? scheme.onPrimaryContainer : scheme.onErrorContainer,
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

class _Section extends StatelessWidget {
  const _Section({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.title, required this.granted, required this.onFix});

  final String title;
  final bool granted;
  final Future<void> Function() onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.cancel_outlined,
        color: granted ? Colors.green.shade600 : scheme.error,
      ),
      title: Text(title),
      trailing: granted
          ? null
          : TextButton(onPressed: onFix, child: const Text('Fix')),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.onOpenAutoStart});

  final DeviceProfile device;
  final VoidCallback onOpenAutoStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smartphone, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.model.isEmpty ? 'This device' : device.model,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        device.vendorName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!device.needsExtraSetup)
              Text(
                'This manufacturer follows Android\'s standard background '
                'rules, so the permissions above should be all you need.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              )
            else ...[
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
                        device.note,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onTertiaryContainer,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Do these by hand',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Android gives apps no way to set these themselves.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < device.steps.length; i++) ...[
                _StepTile(index: i + 1, step: device.steps[i]),
                if (i != device.steps.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenAutoStart,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open these settings'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step});

  final int index;
  final OemStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(
                step.path,
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
