import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/native_bridge.dart';
import '../services/permission_service.dart';
import '../widgets/permission_tile.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();
  final _nativeBridge = NativeBridge();

  PermissionStatusSummary? _status;
  bool _ignoringBatteryOptimizations = false;

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
    final ignoringOptimizations = await _nativeBridge.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _status = status;
      _ignoringBatteryOptimizations = ignoringOptimizations;
    });
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Set up LocReminder')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'LocReminder rings a real alarm when you get close to a '
                    'destination you set — even if the app is closed. It needs '
                    'a few permissions to do that reliably.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  PermissionTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    description: 'Used to detect when you arrive near a saved destination.',
                    granted: status.locationServiceEnabled && status.foregroundLocationGranted,
                    onRequest: () async {
                      if (!status.locationServiceEnabled) {
                        await Geolocator.openLocationSettings();
                      } else {
                        await _permissionService.requestForegroundLocation();
                      }
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  PermissionTile(
                    icon: Icons.my_location,
                    title: 'Allow location "All the time"',
                    description: 'Required so the alarm can still trigger while '
                        'the app is in the background or closed. On the next '
                        'screen, choose "Allow all the time".',
                    granted: status.backgroundLocationGranted,
                    onRequest: () async {
                      await _permissionService.requestBackgroundLocation();
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  PermissionTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    description: 'Needed to show the full-screen alarm when you arrive.',
                    granted: status.notificationsGranted,
                    onRequest: () async {
                      await _permissionService.requestNotifications();
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  PermissionTile(
                    icon: Icons.battery_saver_outlined,
                    title: 'Disable battery optimization (recommended)',
                    description: 'Stops Android from delaying the alarm to save power.',
                    granted: _ignoringBatteryOptimizations,
                    buttonLabel: 'Open settings',
                    onRequest: () async {
                      await _nativeBridge.requestIgnoreBatteryOptimizations();
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: status.isFullyReady ? _continue : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Continue'),
                    ),
                  ),
                  if (!status.isFullyReady)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Grant location, background location, and notifications to continue.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
