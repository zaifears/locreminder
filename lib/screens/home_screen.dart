import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_alarm.dart';
import '../services/alarm_repository.dart';
import '../services/native_bridge.dart';
import '../widgets/app_drawer.dart';
import '../widgets/map_tiles.dart';
import 'location_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _defaultPosition = LatLng(23.8103, 90.4125); // Dhaka

  final _repository = AlarmRepository();
  final _nativeBridge = NativeBridge();
  final _mapController = MapController();

  List<LocationAlarm> _alarms = [];
  LatLng _initialPosition = _defaultPosition;
  LatLng? _userLocation;
  bool _loading = true;
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
    }
  }

  Future<void> _bootstrap() async {
    final alarms = await _repository.loadAll();
    if (mounted) setState(() => _alarms = alarms);
    await _reconcileTriggeredAlarms();
    await _refreshRingingState();
    await _locateUser();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _locateUser({bool recenter = false}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final located = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = located;
        _initialPosition = located;
      });
      if (recenter) _mapController.move(located, 15);
    } catch (_) {
      // Keep the default position; the user can still pan and search.
    }
  }

  /// If a geofence fired while the app wasn't running, the native side
  /// already removed it from Play Services and its own store. Reflect that
  /// here so the list doesn't show a "still active" alarm that has already
  /// rung and been consumed.
  Future<void> _reconcileTriggeredAlarms() async {
    if (_alarms.isEmpty) return;
    final activeIds = (await _nativeBridge.getActiveGeofenceIds()).toSet();
    final triggeredLabels = <String>[];
    final reconciled = _alarms.map((alarm) {
      if (alarm.isActive && !activeIds.contains(alarm.id)) {
        triggeredLabels.add(alarm.label);
        return alarm.copyWith(isActive: false);
      }
      return alarm;
    }).toList();

    if (triggeredLabels.isNotEmpty) {
      setState(() => _alarms = reconciled);
      await _repository.saveAll(_alarms);
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

    try {
      await _nativeBridge.addGeofence(alarm);
      if (!mounted) return;
      setState(() => _alarms = [..._alarms, alarm]);
      await _repository.saveAll(_alarms);
      _mapController.move(LatLng(alarm.latitude, alarm.longitude), 14);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarm set for ${alarm.label}')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not set alarm: ${e.message ?? e.code}')),
        );
      }
    }
  }

  Future<void> _toggleAlarm(LocationAlarm alarm) async {
    try {
      if (alarm.isActive) {
        await _nativeBridge.removeGeofence(alarm.id);
      } else {
        await _nativeBridge.addGeofence(alarm);
      }
      if (!mounted) return;
      final updated = alarm.copyWith(isActive: !alarm.isActive);
      setState(() {
        _alarms = _alarms.map((a) => a.id == alarm.id ? updated : a).toList();
      });
      await _repository.saveAll(_alarms);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update alarm: ${e.message ?? e.code}')),
        );
      }
    }
  }

  Future<void> _deleteAlarm(LocationAlarm alarm) async {
    await _nativeBridge.removeGeofence(alarm.id);
    if (!mounted) return;
    setState(() => _alarms = _alarms.where((a) => a.id != alarm.id).toList());
    await _repository.saveAll(_alarms);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${alarm.label}')),
      );
    }
  }

  void _focusAlarm(LocationAlarm alarm) {
    _mapController.move(LatLng(alarm.latitude, alarm.longitude), 15);
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
            child: Icon(
              Icons.location_on,
              size: 42,
              color: alarm.isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black38)],
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

  List<CircleMarker> get _circles => _alarms
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
                buildAttribution(),
              ],
            ),
            _buildTopBar(context),
            if (_alarmRinging) _buildRingingBanner(context),
            _buildAlarmSheet(context),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'locate',
              onPressed: () => _locateUser(recenter: true),
              child: const Icon(Icons.my_location),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _CircleButton(
              icon: Icons.menu,
              tooltip: 'Menu',
              onTap: () => Scaffold.of(context).openDrawer(),
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
      ),
    );
  }

  Widget _buildRingingBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 76, 12, 0),
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
        ),
      ),
    );
  }

  Widget _buildAlarmSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.14,
      minChildSize: 0.14,
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
                  child: Text(
                    '${_alarms.length} ${_alarms.length == 1 ? 'alarm' : 'alarms'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                for (final alarm in _alarms)
                  _AlarmCard(
                    alarm: alarm,
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: onTap,
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final LocationAlarm alarm;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radiusLabel = alarm.radiusMeters >= 1000
        ? '${(alarm.radiusMeters / 1000).toStringAsFixed(1)} km'
        : '${alarm.radiusMeters.round()} m';

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
        subtitle: Text(
          alarm.isActive ? 'Rings within $radiusLabel' : 'Paused · $radiusLabel',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: alarm.isActive, onChanged: (_) => onToggle()),
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
