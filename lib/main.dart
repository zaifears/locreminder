import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/permission_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LocReminderApp());
}

class LocReminderApp extends StatelessWidget {
  const LocReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocReminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _StartupGate(),
    );
  }
}

/// Routes to onboarding until every permission LocReminder needs to work
/// reliably in the background has been granted, then to the map.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  final _permissionService = PermissionService();
  bool? _ready;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final status = await _permissionService.currentStatus();
    if (mounted) setState(() => _ready = status.isFullyReady);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _ready! ? const HomeScreen() : const OnboardingScreen();
  }
}
