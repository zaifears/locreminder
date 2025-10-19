import 'dart:async';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter/material.dart';

// Import Google Maps - its LatLng will be the default
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// Import Geofencing API with a prefix 'geo' to avoid name conflicts
import 'package:geofencing_api/geofencing_api.dart' as geo;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';

// --- Notification Setup ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// This function MUST be a top-level function (not inside a class)
// to be used for background execution.
@pragma('vm:entry-point')
void geofenceEventHandler(
    geo.Geofence geofence, geo.GeofenceEvent event, geo.Location location) async {
  // Use debugPrint instead of print for better debugging practices
  debugPrint(
      'Geofence event: ${event.toString()} for ID ${geofence.id} at $location');

  if (event == geo.GeofenceEvent.enter) {
    await showAlarmNotification(geofence.id);
    // Check if the device has a vibrator
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 5000); // Vibrate for 5 seconds
    }
  }
}

// Function to show the notification
Future<void> showAlarmNotification(String geofenceId) async {
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

  // Initialize Geofencing API
  // Check permission status before initializing geofencing
  var locationAlwaysStatus = await Permission.locationAlways.status;
  if (!locationAlwaysStatus.isGranted) {
    debugPrint("Background location permission not granted. Geofencing may not work until granted.");
    // Optionally request permissions here, but it's better done in the UI
  }

  try {
     await geo.GeofencingAPI.instance.initialize(
      eventHandler: geofenceEventHandler,
      foregroundNotificationChannelId: 'locreminder_foreground_service',
      foregroundNotificationChannelName: 'LocReminder Background Service',
      foregroundNotificationContentTitle: 'LocReminder is active',
      foregroundNotificationContentText: 'Monitoring your location for alarms.',
    );
     debugPrint("GeofencingAPI Initialized");
  } catch (e) {
     debugPrint("Error initializing GeofencingAPI: $e");
     // Handle initialization error, maybe show an error message to the user
  }


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

  Future<void> _requestPermissions() async {
     debugPrint("Requesting permissions...");
    // Request fine location first
    PermissionStatus statusFine = await Permission.location.request();
    if (statusFine.isGranted) {
       debugPrint("Fine location granted.");
      // Request background location ONLY if fine location is granted
      PermissionStatus statusBackground = await Permission.locationAlways.request();
      if (statusBackground.isGranted) {
         debugPrint("Background location granted.");
      } else {
         debugPrint("Background location denied.");
         // Optionally explain why background location is needed
      }
    } else {
       debugPrint("Fine location denied.");
    }

    // Request notification permission
    PermissionStatus statusNotification = await Permission.notification.request();
     if(statusNotification.isGranted) {
       debugPrint("Notification permission granted.");
     } else {
       debugPrint("Notification permission denied.");
     }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      // Optionally prompt user to enable services
      return;
    }

    // Use permission_handler to check status
    var permission = await Permission.location.status;
    if (permission.isDenied || permission.isPermanentlyDenied) {
      debugPrint("Location permissions are denied.");
      return; // Permissions requested elsewhere
    }

    try {
      // Updated getCurrentPosition call without deprecated parameter
      Position position = await Geolocator.getCurrentPosition(
         // Optionally use LocationSettings for accuracy control if needed:
         // desiredAccuracy: LocationAccuracy.high // Example if needed, but often default is fine
      );
      if (mounted) { // Check if the widget is still in the tree
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
      // Check permission status first
       var locationAlwaysStatus = await Permission.locationAlways.status;
       if (!locationAlwaysStatus.isGranted) {
         debugPrint("Background location permission needed to check geofences.");
         return;
       }

      List<geo.Geofence> geofences = await geo.GeofencingAPI.instance.getAllGeofences();
      bool found = geofences.any((gf) => gf.id == _geofenceId);

      if (found && mounted) {
        geo.Geofence existing = geofences.firstWhere((gf) => gf.id == _geofenceId);
        debugPrint("Existing geofence found: ${existing.id}");
        setState(() {
          isAlarmSet = true;
          selectedLocation = LatLng(existing.latitude, existing.longitude); // Use Google Maps LatLng
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

  void _onMapTap(LatLng position) { // Google Maps LatLng
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
    if (!mounted) return; // Check mount status at the beginning

    if (isAlarmSet) {
      // --- Remove Geofence ---
      try {
        await geo.GeofencingAPI.instance.removeGeofence(id: _geofenceId);
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
      // --- Add Geofence ---
      if (selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a location on the map first!')),
        );
        return;
      }

      var status = await Permission.locationAlways.status;
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permission "Always Allow" is required! Please grant in settings.')),
        );
        openAppSettings(); // Guide user directly to settings
        return;
      }

      // Create the geofence object using the prefixed class
      final geofence = geo.Geofence(
        id: _geofenceId,
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
        radius: 500, // meters
        triggers: [geo.GeofenceEvent.enter], // Use prefixed enum
      );

      try {
        await geo.GeofencingAPI.instance.addGeofence(geofence);
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
}