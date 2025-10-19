import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';

// --- Notification Setup ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Simple geofence data structure
class SimpleGeofence {
  final String id;
  final double latitude;
  final double longitude;
  final double radius;
  
  SimpleGeofence({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
}

// Geofence manager class
class GeofenceManager {
  static final GeofenceManager _instance = GeofenceManager._internal();
  factory GeofenceManager() => _instance;
  GeofenceManager._internal();

  final List<SimpleGeofence> _activeGeofences = [];
  Timer? _locationTimer;

  void addGeofence(SimpleGeofence geofence) {
    _activeGeofences.add(geofence);
    _startLocationMonitoring();
  }

  void removeGeofence(String id) {
    _activeGeofences.removeWhere((g) => g.id == id);
    if (_activeGeofences.isEmpty) {
      _stopLocationMonitoring();
    }
  }

  List<SimpleGeofence> getAllGeofences() => List.from(_activeGeofences);

  void _startLocationMonitoring() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkLocation();
    });
  }

  void _stopLocationMonitoring() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _checkLocation() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      for (SimpleGeofence geofence in _activeGeofences) {
        double distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          geofence.latitude,
          geofence.longitude,
        );

        if (distance <= geofence.radius) {
          // Entered geofence
          await _showAlarmNotification(geofence.id);
          bool hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator) {
            Vibration.vibrate(duration: 5000);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking location: $e');
    }
  }

  Future<void> _showAlarmNotification(String geofenceId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'locreminder_channel_geofence',
      'Location Alarms',
      channelDescription: 'Notifications for location-based reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'Approaching Destination',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      geofenceId.hashCode,
      'Destination Approaching!',
      'You are near the location set for your alarm.',
      platformChannelSpecifics,
      payload: 'location_alarm_$geofenceId',
    );
    debugPrint('Notification shown for geofence ID: $geofenceId');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  debugPrint("Notifications Initialized");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocReminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  Set<Marker> markers = {};
  LatLng initialPosition = const LatLng(23.8103, 90.4125); // Default to Dhaka
  bool isAlarmSet = false;
  final GeofenceManager _geofenceManager = GeofenceManager();
  final String _geofenceId = 'destination_alarm_01';

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndSetup();
  }

  Future<void> _requestPermissionsAndSetup() async {
    await _requestPermissions();
    await _getCurrentLocation();
    await _checkExistingGeofences();
  }

  Future<bool> _requestPermissions() async {
    debugPrint("Requesting permissions...");
    
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
      }
      return false;
    }

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable in settings.'),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
      }
      return false;
    }

    // Request notification permission
    await Permission.notification.request();
    
    debugPrint("Permissions granted");
    return true;
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          initialPosition = LatLng(position.latitude, position.longitude);
        });
        mapController?.animateCamera(CameraUpdate.newLatLng(initialPosition));
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _checkExistingGeofences() async {
    try {
      List<SimpleGeofence> geofences = _geofenceManager.getAllGeofences();
      bool found = geofences.any((gf) => gf.id == _geofenceId);

      if (found && mounted) {
        SimpleGeofence existing = geofences.firstWhere((gf) => gf.id == _geofenceId);
        debugPrint("Existing geofence found: ${existing.id}");
        setState(() {
          isAlarmSet = true;
          selectedLocation = LatLng(existing.latitude, existing.longitude);
          markers = {
            Marker(
                markerId: MarkerId(_geofenceId),
                position: selectedLocation!,
                infoWindow: const InfoWindow(title: 'Active Alarm'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen))
          };
        });
      }
    } catch (e) {
      debugPrint("Error checking existing geofences: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(initialPosition, 14));
  }

  void _onMapTap(LatLng position) {
    if (!isAlarmSet) {
      if (mounted) {
        setState(() {
          selectedLocation = position;
          markers = {
            Marker(
              markerId: MarkerId(_geofenceId),
              position: position,
              infoWindow: const InfoWindow(title: 'Set Destination'),
            )
          };
        });
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An alarm is already set. Remove it first.')),
      );
    }
  }

  void _toggleAlarm() async {
    if (!mounted) return;

    if (isAlarmSet) {
      // Remove Geofence
      try {
        _geofenceManager.removeGeofence(_geofenceId);
        debugPrint('Geofence removed: $_geofenceId');
        if (mounted) {
          setState(() {
            isAlarmSet = false;
            selectedLocation = null;
            markers.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location alarm removed!')),
          );
        }
      } catch (e) {
        debugPrint('Error removing geofence: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove alarm: $e')),
        );
      }
    } else {
      // Add Geofence
      if (selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a location on the map first!')),
        );
        return;
      }

      bool hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        return;
      }

      try {
        final geofence = SimpleGeofence(
          id: _geofenceId,
          latitude: selectedLocation!.latitude,
          longitude: selectedLocation!.longitude,
          radius: 500, // meters
        );

        _geofenceManager.addGeofence(geofence);
        debugPrint(
            'Geofence added for ${selectedLocation!.latitude}, ${selectedLocation!.longitude}');
        if (mounted) {
          setState(() {
            isAlarmSet = true;
            markers = {
              Marker(
                  markerId: MarkerId(_geofenceId),
                  position: selectedLocation!,
                  infoWindow: const InfoWindow(title: 'Active Alarm'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen))
            };
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location alarm set!')),
          );
        }
      } catch (e) {
        debugPrint('Error adding geofence: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set alarm: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocReminder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 14.0,
            ),
            markers: markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _toggleAlarm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAlarmSet
                      ? Colors.redAccent
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(isAlarmSet ? 'Remove Alarm' : 'Set Alarm at Marker'),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
