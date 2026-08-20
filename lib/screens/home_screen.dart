import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_alarm.dart';
import '../services/alarm_repository.dart';
import '../services/native_bridge.dart';
import '../services/permission_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/map_pin.dart';
import '../widgets/map_tiles.dart';
import 'location_picker_screen.dart';
import 'reliability_screen.dart';

/// Formats a metre distance the way a person would say it.
String formatDistance(double metres) {
  if (metres < 1000) return '${metres.round()} m';
  if (metres < 10000) return '${(metres / 1000).toStringAsFixed(1)} km';
  return '${(metres / 1000).round()} km';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _defaultPosition = LatLng(23.8103, 90.4125); // Dhaka

  final _repository = AlarmRepository();
  final _nativeBridge = NativeBridge();
  final _permissionService = PermissionService();
  final _mapController = MapController();

  List<LocationAlarm> _alarms = [];
  LatLng _initialPosition = _defaultPosition;
  LatLng? _userLocation;
  double? _userAccuracy;
  PermissionStatusSummary? _permissions;
  bool _loading = true;
  bool _locating = false;
  bool _alarmRinging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reconcileTriggeredAlarms();
      _refreshRingingState();
      _refreshPermissions();
      _locateUser();
    }
  }

  Future<void> _bootstrap() async {
    final alarms = await _repository.loadAll();
    if (mounted) setState(() => _alarms = alarms);
    await _reconcileTriggeredAlarms();
    await _refreshRingingState();
    await _refreshPermissions();
    await _locateUser();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshPermissions() async {
    final status = await _permissionService.currentStatus();
    if (mounted) setState(() => _permissions = status);
  }

  /// Keeps the native watch service running exactly while something is armed.
  /// Called after every change to the alarm list so the service never lingers
  /// with nothing to watch, and never stops while an alarm still needs it.
  Future<void> _syncLocationWatch() async {
    final shouldWatch = _alarms.any((a) => a.isActive);
    try {
      if (shouldWatch) {
        await _nativeBridge.startLocationWatch();
      } else {
        await _nativeBridge.stopLocationWatch();
      }
    } on PlatformException catch (e) {
      if (mounted && shouldWatch) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Background tracking could not start (${e.code}). Alarms may be '
              'delayed — check permissions in Settings.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// Updates the blue dot, and on [recenter] moves the map to it.
  ///
  /// A tap on the locate button asks for a *fresh* fix: the cached one the
  /// background refresh uses can be hours stale or missing entirely, which
  /// made the button appear to do nothing at all right after a reboot.
  Future<void> _locateUser({bool recenter = false}) async {
    if (recenter && _locating) return;
    if (recenter) setState(() => _locating = true);

    try {
      final fix = recenter
          ? await _nativeBridge.getCurrentLocation()
          : await _nativeBridge.getLastKnownLocation();
      final latitude = fix?['latitude'] as double?;
      final longitude = fix?['longitude'] as double?;

      if (latitude == null || longitude == null) {
        if (recenter && mounted) await _reportLocateFailure();
        return;
      }
      if (!mounted) return;

      final located = LatLng(latitude, longitude);
      setState(() {
        _userLocation = located;
        _userAccuracy = (fix?['accuracy'] as num?)?.toDouble();
        _initialPosition = located;
      });
      if (recenter) _mapController.move(located, 15);
    } catch (_) {
      // Keep the default position; the user can still pan and search.
      if (recenter && mounted) await _reportLocateFailure();
    } finally {
      if (recenter && mounted) setState(() => _locating = false);
    }
  }

  /// Says why locating failed, and offers the fix when it is the usual one.
  Future<void> _reportLocateFailure() async {
    final locationOn = await _nativeBridge.isLocationEnabled();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locationOn
              ? "Couldn't get a location fix. Try again outdoors."
              : 'Location is switched off.',
        ),
        action: locationOn
            ? null
            : SnackBarAction(
                label: 'Turn on',
                onPressed: _nativeBridge.openLocationSettings,
              ),
      ),
    );
  }

  /// If an alarm fired while the app wasn't running, the native side already
  /// consumed it from its own store. Reflect that here so the list doesn't
  /// show a "still active" alarm that has already rung.
  Future<void> _reconcileTriggeredAlarms() async {
    if (_alarms.isEmpty) return;
    final activeIds = (await _nativeBridge.getActiveAlarmIds()).toSet();
    final triggeredLabels = <String>[];
    final reconciled = _alarms.map((alarm) {
      if (alarm.isActive && !activeIds.contains(alarm.id)) {
        triggeredLabels.add(alarm.label);
        return alarm.copyWith(isActive: false);
      }
      return alarm;
    }).toList();

    if (triggeredLabels.isNotEmpty && mounted) {
      setState(() => _alarms = reconciled);
      await _repository.saveAll(_alarms);
      await _syncLocationWatch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Already rang: ${triggeredLabels.join(', ')}')),
        );
      }
    }
  }

  Future<void> _refreshRingingState() async {
    final ringing = await _nativeBridge.isAlarmRinging();
    if (mounted) setState(() => _alarmRinging = ringing);
  }

  Future<void> _stopAlarm() async {
    await _nativeBridge.stopAlarm();
    await _reconcileTriggeredAlarms();
    await _refreshRingingState();
  }

  Future<void> _addAlarm() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialCenter: _userLocation ?? _initialPosition,
        ),
      ),
    );
    if (picked == null || !mounted) return;

    final alarm = LocationAlarm(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: picked.label,
      latitude: picked.latitude,
      longitude: picked.longitude,
      radiusMeters: picked.radiusMeters,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final registered = await _register(alarm);
    if (!registered || !mounted) return;

    setState(() => _alarms = [..._alarms, alarm]);
    await _repository.saveAll(_alarms);
    await _syncLocationWatch();
    _mapController.move(LatLng(alarm.latitude, alarm.longitude), 14);
    if (!mounted) return;

    // Arrival means crossing into the radius, so an alarm set for somewhere
    // you are already standing stays silent until you leave and come back.
    // Say so rather than letting it look broken.
    final here = _userLocation;
    final alreadyInside = here != null &&
        const Distance()(here, LatLng(alarm.latitude, alarm.longitude)) <=
            alarm.radiusMeters;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadyInside
              ? "Alarm set — but you're already inside this area, so it will "
                  'ring when you leave and come back.'
              : 'Alarm set for ${alarm.label}',
        ),
        duration: Duration(seconds: alreadyInside ? 6 : 3),
      ),
    );
  }

  /// Registers the alarm natively, surfacing failures instead of leaving an
  /// alarm that looks armed in the list but the watcher never learned about.
  Future<bool> _register(LocationAlarm alarm) async {
    try {
      await _nativeBridge.addAlarm(alarm);
      return true;
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set alarm: ${e.message ?? e.code}')),
        );
      }
      return false;
    }
  }

  Future<void> _toggleAlarm(LocationAlarm alarm) async {
    if (alarm.isActive) {
      try {
        await _nativeBridge.removeAlarm(alarm.id);
      } on PlatformException catch (_) {
        // Removal failing still leaves the alarm paused in the UI; the
        // native store is reconciled on the next resume anyway.
      }
    } else {
      final registered = await _register(alarm);
      if (!registered) return;
    }
    if (!mounted) return;

    final updated = alarm.copyWith(isActive: !alarm.isActive);
    setState(() {
      _alarms = _alarms.map((a) => a.id == alarm.id ? updated : a).toList();
    });
    await _repository.saveAll(_alarms);
    await _syncLocationWatch();
  }

  Future<void> _deleteAlarm(LocationAlarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    await _nativeBridge.removeAlarm(alarm.id);
    if (!mounted) return;

    setState(() => _alarms = _alarms.where((a) => a.id != alarm.id).toList());
    await _repository.saveAll(_alarms);
    await _syncLocationWatch();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${alarm.label}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _restoreAlarm(alarm, index),
        ),
      ),
    );
  }

  Future<void> _restoreAlarm(LocationAlarm alarm, int index) async {
    if (alarm.isActive) {
      final registered = await _register(alarm);
      if (!registered) return;
    }
    if (!mounted) return;

    setState(() {
      final restored = [..._alarms];
      restored.insert(index.clamp(0, restored.length), alarm);
      _alarms = restored;
    });
    await _repository.saveAll(_alarms);
    await _syncLocationWatch();
  }

  void _focusAlarm(LocationAlarm alarm) {
    _mapController.move(LatLng(alarm.latitude, alarm.longitude), 15);
  }

  double? _distanceTo(LocationAlarm alarm) {
    final here = _userLocation;
    if (here == null) return null;
    // latlong2's Distance is a pure-Dart haversine, so this needs no plugin.
    return const Distance()(here, LatLng(alarm.latitude, alarm.longitude));
  }

  List<Marker> get _markers {
    final markers = _alarms
        .map(
          (alarm) => Marker(
            point: LatLng(alarm.latitude, alarm.longitude),
            width: 44,
            height: 44,
            // Puts the pin's tip on the coordinate rather than its middle.
            alignment: Alignment.bottomCenter,
            // Counter-rotate against the map so two-finger rotation doesn't
            // spin the pins — they stay upright like real map pins.
            rotate: true,
            child: GestureDetector(
              onTap: () => _showAlarmPreview(alarm),
              child: MapPin(
                size: 44,
                color: alarm.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                borderColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        )
        .toList();

    final userLocation = _userLocation;
    if (userLocation != null) {
      markers.add(
        Marker(
          point: userLocation,
          width: 22,
          height: 22,
          rotate: true,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _showAlarmPreview(LocationAlarm alarm) {
    final distance = _distanceTo(alarm);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          distance == null
              ? '${alarm.label} · rings within ${formatDistance(alarm.radiusMeters)}'
              : '${alarm.label} · ${formatDistance(distance)} away',
        ),
      ),
    );
  }

  List<CircleMarker> get _circles {
    final circles = _alarms
        .where((a) => a.isActive)
        .map(
          (alarm) => CircleMarker(
            point: LatLng(alarm.latitude, alarm.longitude),
            radius: alarm.radiusMeters,
            useRadiusInMeter: true,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            borderStrokeWidth: 2,
          ),
        )
        .toList();

    // How sure the fix actually is. Without this the dot claims a precision
    // it may not have — indoors it can be hundreds of metres out, which
    // matters here, because that is also roughly the scale of the radius
    // people pick. Below the dot's own size it would just be noise.
    final here = _userLocation;
    final accuracy = _userAccuracy;
    if (here != null && accuracy != null && accuracy > 30) {
      circles.insert(
        0,
        CircleMarker(
          point: here,
          radius: accuracy,
          useRadiusInMeter: true,
          color: Colors.blueAccent.withValues(alpha: 0.10),
          borderColor: Colors.blueAccent.withValues(alpha: 0.35),
          borderStrokeWidth: 1,
        ),
      );
    }
    return circles;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: Builder(
        builder: (context) => Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 14,
              ),
              children: [
                buildTileLayer(context),
                CircleLayer(circles: _circles),
                MarkerLayer(markers: _markers),
              ],
            ),
            // Sits just above the collapsed alarm sheet so the required OSM
            // credit stays visible.
            Positioned(
              left: 8,
              bottom: MediaQuery.of(context).size.height * 0.13 + 6,
              child: const MapAttribution(),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    if (_alarmRinging) _buildRingingBanner(context),
                    if (!_alarmRinging) _buildPermissionWarning(context),
                  ],
                ),
              ),
            ),
            _buildAlarmSheet(context),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'locate',
              tooltip: 'Centre on my location',
              // Getting a real fix can take a few seconds, so the button has
              // to show it is working rather than looking inert.
              onPressed: _locating ? null : () => _locateUser(recenter: true),
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: _addAlarm,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add alarm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Material(
            elevation: 3,
            color: Theme.of(context).colorScheme.surface,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _addAlarm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search for a destination',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Android silently revokes background permissions for apps that haven't
  /// been opened recently, which stops alarms without any visible sign. For
  /// an alarm app that failure mode is the worst one, so it gets a
  /// permanent, unmissable banner.
  Widget _buildPermissionWarning(BuildContext context) {
    final permissions = _permissions;
    if (permissions == null || permissions.isFullyReady) {
      return const SizedBox.shrink();
    }
    if (!_alarms.any((a) => a.isActive)) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final missing = <String>[
      if (!permissions.locationServiceEnabled) 'location services',
      if (!permissions.foregroundLocationGranted) 'location access',
      if (!permissions.backgroundLocationGranted) '"Allow all the time"',
      if (!permissions.notificationsGranted) 'notifications',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your alarms will not ring',
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Missing ${missing.join(', ')}.',
                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReliabilityScreen()),
            ),
            child: const Text('Fix'),
          ),
        ],
      ),
    );
  }

  Widget _buildRingingBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alarm ringing',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FilledButton(onPressed: _stopAlarm, child: const Text('Stop')),
        ],
      ),
    );
  }

  Widget _buildAlarmSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeCount = _alarms.where((a) => a.isActive).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.13,
      minChildSize: 0.13,
      maxChildSize: 0.62,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (_alarms.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No alarms yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap "Add alarm" to search for where you\'re heading, '
                        'then choose how close you want to be before it rings.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        '${_alarms.length} ${_alarms.length == 1 ? 'alarm' : 'alarms'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (activeCount > 0)
                        Text(
                          '$activeCount armed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final alarm in _alarms)
                  _AlarmCard(
                    alarm: alarm,
                    distanceMetres: _distanceTo(alarm),
                    onTap: () => _focusAlarm(alarm),
                    onToggle: () => _toggleAlarm(alarm),
                    onDelete: () => _deleteAlarm(alarm),
                  ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.distanceMetres,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final LocationAlarm alarm;
  final double? distanceMetres;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radiusLabel = formatDistance(alarm.radiusMeters);
    final distance = distanceMetres;

    final String subtitle;
    if (!alarm.isActive) {
      subtitle = 'Paused · rings within $radiusLabel';
    } else if (distance == null) {
      subtitle = 'Rings within $radiusLabel';
    } else {
      subtitle = '${formatDistance(distance)} away · rings within $radiusLabel';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              alarm.isActive ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          child: Icon(
            alarm.isActive ? Icons.notifications_active : Icons.notifications_off,
            color: alarm.isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
        title: Text(alarm.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alarm.isActive,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
