import 'package:flutter/material.dart';

import 'l10n/strings.g.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/offline_maps.dart';
import 'services/permission_service.dart';
import 'services/theme_controller.dart';
import 'services/unit_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before the first map is built, not lazily: flutter_map creates its own
  // tile store the first time a tile is asked for, and whichever store exists
  // first is the one it keeps for the run. Losing that race would mean tiles
  // cached where Android may delete them, expiring after a day instead of a
  // month — the offline map quietly not working.
  await OfflineMaps.initialise();
  final themeController = ThemeController();
  await themeController.load();
  final unitController = UnitController();
  await unitController.load();
  runApp(
    LocReminderApp(
      themeController: themeController,
      unitController: unitController,
    ),
  );
}

class LocReminderApp extends StatefulWidget {
  const LocReminderApp({
    super.key,
    required this.themeController,
    this.unitController,
  });

  final ThemeController themeController;
  final UnitController? unitController;

  static final UnitController _fallbackUnitController = UnitController();

  /// Lets any screen read the app-wide theme controller without pulling in a
  /// state-management dependency for a single setting.
  static ThemeController themeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScope>();
    assert(scope != null, 'No LocReminderApp found in context');
    return scope!.themeController;
  }

  /// Lets any screen read or change the app-wide distance unit (KM vs Miles).
  static UnitController unitOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScope>();
    return scope?.unitController ?? _fallbackUnitController;
  }

  @override
  State<LocReminderApp> createState() => _LocReminderAppState();
}

class _LocReminderAppState extends State<LocReminderApp> {
  late final UnitController _unitController =
      widget.unitController ?? LocReminderApp._fallbackUnitController;

  @override
  Widget build(BuildContext context) {
    return _AppScope(
      themeController: widget.themeController,
      unitController: _unitController,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.themeController,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'LocReminder',
            debugShowCheckedModeBanner: false,
            // Follows the phone's language, falling back to English for one
            // nobody has contributed yet. Both come from locale/*.yaml; see
            // docs/LOCALISATION.md.
            localizationsDelegates: const [S.delegate],
            supportedLocales: S.supported,
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

class _AppScope extends InheritedWidget {
  const _AppScope({
    required this.themeController,
    required this.unitController,
    required super.child,
  });

  final ThemeController themeController;
  final UnitController unitController;

  @override
  bool updateShouldNotify(_AppScope oldWidget) =>
      themeController != oldWidget.themeController ||
      unitController != oldWidget.unitController;
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
