import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location_alarm.dart';
import '../services/alarm_repository.dart';
import '../services/native_bridge.dart';
import 'add_alarm_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _defaultPosition = LatLng(23.8103, 90.4125); // Dhaka

  final _repository = AlarmRepository();
  final _nativeBridge = NativeBridge();

  GoogleMapController? _mapController;
  List<LocationAlarm> _alarms = [];
  LatLng _initialPosition = _defaultPosition;
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
    _mapController?.dispose();
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

  Future<void> _locateUser() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _initialPosition = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 14));
    } catch (_) {
      // Keep the default position; the user can still pan the map.
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

  Future<void> _onMapTap(LatLng position) async {
    final result = await AddAlarmSheet.show(context);
    if (result == null) return;

    final alarm = LocationAlarm(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: result.label,
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: result.radiusMeters,
      isActive: true,
      createdAt: DateTime.now(),
    );

    try {
      await _nativeBridge.addGeofence(alarm);
      setState(() => _alarms = [..._alarms, alarm]);
      await _repository.saveAll(_alarms);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarm set at "${alarm.label}"')),
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
    setState(() => _alarms = _alarms.where((a) => a.id != alarm.id).toList());
    await _repository.saveAll(_alarms);
  }

  void _focusAlarm(LocationAlarm alarm) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(alarm.latitude, alarm.longitude), 15),
    );
  }

  Set<Marker> get _markers => _alarms
      .map(
        (alarm) => Marker(
          markerId: MarkerId(alarm.id),
          position: LatLng(alarm.latitude, alarm.longitude),
          infoWindow: InfoWindow(title: alarm.label),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            alarm.isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
          ),
        ),
      )
      .toSet();

  Set<Circle> get _circles => _alarms
      .where((a) => a.isActive)
      .map(
        (alarm) => Circle(
          circleId: CircleId(alarm.id),
          center: LatLng(alarm.latitude, alarm.longitude),
          radius: alarm.radiusMeters,
          fillColor: Colors.blue.withValues(alpha: 0.12),
          strokeColor: Colors.blue.withValues(alpha: 0.6),
          strokeWidth: 2,
        ),
      )
      .toSet();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            padding: const EdgeInsets.only(bottom: 120),
          ),
          if (_alarmRinging)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Alarm ringing',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FilledButton(onPressed: _stopAlarm, child: const Text('Stop')),
                    ],
                  ),
                ),
              ),
            ),
          DraggableScrollableSheet(
            initialChildSize: 0.16,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      _alarms.isEmpty
                          ? 'Tap anywhere on the map to set a destination alarm'
                          : '${_alarms.length} ${_alarms.length == 1 ? 'alarm' : 'alarms'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final alarm in _alarms) _AlarmCard(
                      alarm: alarm,
                      onTap: () => _focusAlarm(alarm),
                      onToggle: () => _toggleAlarm(alarm),
                      onDelete: () => _deleteAlarm(alarm),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: alarm.isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.location_on),
        ),
        title: Text(alarm.label),
        subtitle: Text('Radius ${alarm.radiusMeters.round()} m'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: alarm.isActive, onChanged: (_) => onToggle()),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
