import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/permission_service.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.load();
  runApp(LocReminderApp(themeController: themeController));
}

class LocReminderApp extends StatefulWidget {
  const LocReminderApp({super.key, required this.themeController});

  final ThemeController themeController;

  /// Lets any screen read the app-wide theme controller without pulling in a
  /// state-management dependency for a single setting.
  static ThemeController themeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ThemeScope>();
    assert(scope != null, 'No LocReminderApp found in context');
    return scope!.controller;
  }

  @override
  State<LocReminderApp> createState() => _LocReminderAppState();
}

class _LocReminderAppState extends State<LocReminderApp> {
  @override
  Widget build(BuildContext context) {
    return _ThemeScope(
      controller: widget.themeController,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.themeController,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'LocReminder',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            home: const _StartupGate(),
          );
        },
      ),
    );
  }
}

class _ThemeScope extends InheritedWidget {
  const _ThemeScope({required this.controller, required super.child});

  final ThemeController controller;

  @override
  bool updateShouldNotify(_ThemeScope oldWidget) => controller != oldWidget.controller;
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
