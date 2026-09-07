import 'package:flutter/material.dart';

import '../main.dart';
import '../services/app_version.dart';
import '../services/offline_maps.dart';
import '../services/permission_service.dart';
import '../widgets/alarm_sound_section.dart';
import 'reliability_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  PermissionStatusSummary? _status;
  String? _version;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    AppVersion.get().then((value) {
      if (mounted) setState(() => _version = value);
    });
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
          const _SectionHeader(label: 'Alarm sound'),
          const AlarmSoundSection(),
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
                    subtitle: 'Required — Android delays alarms without it',
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
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.health_and_safety_outlined,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              title: const Text('Alarm reliability'),
              subtitle: const Text(
                'Device-specific setup and a test that proves alarms get through',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReliabilityScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _permissionService.openSystemAppSettings,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open system app settings'),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(label: 'Offline maps'),
          const _OfflineMapsSection(),
          const SizedBox(height: 24),
          const _SectionHeader(label: 'About this build'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              subtitle: Text(_version ?? '…'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Explains — and gives control over — the one part of this app that does
/// need the internet.
///
/// Worth a section of its own because the question behind it comes up
/// constantly and the answer is not obvious: the alarm has never needed a
/// connection, and the map always will, because a map is pictures held on
/// somebody else's server. What can be done is to keep the pictures, which is
/// what this does.
class _OfflineMapsSection extends StatefulWidget {
  const _OfflineMapsSection();

  @override
  State<_OfflineMapsSection> createState() => _OfflineMapsSectionState();
}

class _OfflineMapsSectionState extends State<_OfflineMapsSection> {
  bool? _prefetch;
  int? _bytes;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefetch = await OfflineMaps.prefetchEnabled();
    final bytes = await OfflineMaps.cacheSizeBytes();
    if (mounted) {
      setState(() {
        _prefetch = prefetch;
        _bytes = bytes;
      });
    }
  }

  String get _sizeLabel {
    final bytes = _bytes;
    if (bytes == null) return 'Saved as you use the map';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB saved';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB saved';
  }

  Future<void> _clear() async {
    setState(() => _clearing = true);
    await OfflineMaps.clearCache();
    if (!mounted) return;
    setState(() => _clearing = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'The alarm never needs a connection — it works off GPS, which '
              'is a receive-only radio. Only the map pictures and searching '
              'by name do. Everywhere you look at on the map is kept for a '
              'month so it still draws with no signal.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          SwitchListTile(
            value: _prefetch ?? true,
            title: const Text('Save the map around new alarms'),
            subtitle: const Text(
              'Fetches the streets around a stop when you set it, so they are '
              'already on the phone for the journey',
            ),
            onChanged: _prefetch == null
                ? null
                : (value) async {
                    setState(() => _prefetch = value);
                    await OfflineMaps.setPrefetchEnabled(value);
                  },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sd_storage_outlined),
            title: const Text('Saved map data'),
            subtitle: Text(_sizeLabel),
            trailing: _clearing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(onPressed: _clear, child: const Text('Clear')),
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
