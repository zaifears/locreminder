import 'package:flutter/material.dart';

import '../main.dart';
import '../services/permission_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  PermissionStatusSummary? _status;

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
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final controller = LocReminderApp.themeOf(context);
    final status = _status;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(label: 'Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: controller,
                builder: (context, mode, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto),
                              label: Text('System'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {mode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) =>
                              controller.setMode(selection.first),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        switch (mode) {
                          ThemeMode.system => 'Matching your phone\'s theme.',
                          ThemeMode.light => 'Always light, whatever your phone uses.',
                          ThemeMode.dark => 'Always dark, whatever your phone uses.',
                        },
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(label: 'Alarm reliability'),
          if (status == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  _PermissionRow(
                    title: 'Location',
                    granted: status.locationServiceEnabled &&
                        status.foregroundLocationGranted,
                    onFix: () async {
                      await _permissionService.requestForegroundLocation();
                      await _refresh();
                    },
                  ),
                  const Divider(height: 1),
                  _PermissionRow(
                    title: 'Background location',
                    subtitle: 'Must be "Allow all the time"',
                    granted: status.backgroundLocationGranted,
                    onFix: () async {
                      await _permissionService.requestBackgroundLocation();
                      await _refresh();
                    },
                  ),
                  const Divider(height: 1),
                  _PermissionRow(
                    title: 'Notifications',
                    granted: status.notificationsGranted,
                    onFix: () async {
                      await _permissionService.requestNotifications();
                      await _refresh();
                    },
                  ),
                  const Divider(height: 1),
                  _PermissionRow(
                    title: 'Full-screen alarms',
                    subtitle: 'Needed on Android 14 and newer',
                    granted: status.fullScreenIntentAllowed,
                    onFix: () async {
                      await _permissionService.requestFullScreenIntent();
                      await _refresh();
                    },
                  ),
                  const Divider(height: 1),
                  _PermissionRow(
                    title: 'Battery optimization off',
                    subtitle: 'Stops Android delaying the alarm',
                    granted: status.batteryOptimizationDisabled,
                    onFix: () async {
                      await _permissionService.requestDisableBatteryOptimization();
                      await _refresh();
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'If an alarm ever fails to ring, check this list first — Android '
              'silently revokes background permissions for apps you have not '
              'opened in a while.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _permissionService.openSystemAppSettings,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open system app settings'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.granted,
    required this.onFix,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool granted;
  final Future<void> Function() onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.error_outline,
        color: granted ? Colors.green.shade600 : scheme.error,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: granted ? null : TextButton(onPressed: onFix, child: const Text('Fix')),
    );
  }
}
