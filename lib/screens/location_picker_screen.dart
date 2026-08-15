import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_result.dart';
import '../services/geocoding_service.dart';
import '../widgets/map_pin.dart';
import '../widgets/map_tiles.dart';

class PickedLocation {
  const PickedLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String label;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}

/// Full-screen destination picker: search by name, or drag the map under a
/// fixed centre crosshair. Replaces blind tapping — you can look up "Dhaka
/// Airport" instead of hunting for it on the map.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, required this.initialCenter});

  final LatLng initialCenter;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  final _geocoder = GeocodingService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  late LatLng _center = widget.initialCenter;
  List<PlaceResult> _results = const [];
  bool _searching = false;
  bool _showResults = false;
  bool _searchFailed = false;
  Timer? _searchDebounce;

  String? _address;
  bool _resolvingAddress = false;
  Timer? _addressDebounce;

  double _radius = 500;
  String? _chosenName;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _addressDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _results = const [];
        _showResults = false;
      });
      return;
    }
    setState(() => _showResults = true);
    _searchDebounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _searching = true);
      final outcome = await _geocoder.search(query);
      if (!mounted) return;
      setState(() {
        _results = outcome.results;
        _searchFailed = !outcome.reachedService;
        _searching = false;
      });
    });
  }

  void _selectResult(PlaceResult place) {
    _searchFocus.unfocus();
    final target = LatLng(place.latitude, place.longitude);
    _mapController.move(target, 16);
    setState(() {
      _center = target;
      _chosenName = place.shortName;
      _address = place.displayName;
      _showResults = false;
      _searchController.text = place.shortName;
    });
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    if (!hasGesture) return;
    // The user dragged the map, so whatever name came from search no longer
    // describes the pin — fall back to reverse geocoding the new centre.
    _chosenName = null;
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 700), _resolveAddress);
  }

  Future<void> _resolveAddress() async {
    setState(() => _resolvingAddress = true);
    final address = await _geocoder.reverse(_center.latitude, _center.longitude);
    if (!mounted) return;
    setState(() {
      _address = address;
      _resolvingAddress = false;
    });
  }

  void _confirm() {
    final fallback = _address?.split(',').first.trim();
    final label = _chosenName?.trim().isNotEmpty == true
        ? _chosenName!.trim()
        : (fallback?.isNotEmpty == true ? fallback! : 'Destination');

    Navigator.of(context).pop(
      PickedLocation(
        label: label,
        latitude: _center.latitude,
        longitude: _center.longitude,
        radiusMeters: _radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15,
              onPositionChanged: _onMapMoved,
              onTap: (_, __) => _searchFocus.unfocus(),
            ),
            children: [
              buildTileLayer(context),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    radius: _radius,
                    useRadiusInMeter: true,
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderColor: scheme.primary.withValues(alpha: 0.7),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            ],
          ),

          // Fixed centre crosshair: the map moves under it, so the pin is
          // always exactly where the alarm will be placed.
          IgnorePointer(
            child: Center(
              child: Padding(
                // Lifts the pin by its own height so its tip — not its middle
                // — rests exactly on the map centre, matching the circle.
                padding: const EdgeInsets.only(bottom: 52),
                child: MapPin(size: 52, color: scheme.primary, borderColor: scheme.surface),
              ),
            ),
          ),

          // Kept clear of the bottom panel so the required OSM credit stays
          // visible while picking.
          const Positioned(left: 8, bottom: 232, child: MapAttribution()),

          _buildSearchBar(context),
          if (_showResults) _buildResultsOverlay(context),
          _buildBottomPanel(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onTap: () {
                    if (_results.isNotEmpty) setState(() => _showResults = true);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search for a place or address',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = const [];
                      _showResults = false;
                    });
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.search),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsOverlay(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 76, 12, 12),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _searching && _results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Icon(
                              _searchFailed ? Icons.wifi_off : Icons.search_off,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _searchFailed
                                    ? "Couldn't reach the search service. Check "
                                        'your connection, or drag the map to '
                                        'pick the spot manually.'
                                    : 'No places found. Try a different search.',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _results[index];
                          return ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(
                              place.shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: place.context.isEmpty
                                ? null
                                : Text(
                                    place.context,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            onTap: () => _selectResult(place),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 12,
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _resolvingAddress
                          ? Text(
                              'Finding this place…',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            )
                          : Text(
                              _address ?? 'Dropped pin',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Wake me within',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      _radius >= 1000
                          ? '${(_radius / 1000).toStringAsFixed(1)} km'
                          : '${_radius.round()} m',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                    ),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 100,
                  max: 3000,
                  divisions: 29,
                  onChanged: (value) => setState(() => _radius = value),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.alarm_add),
                    label: const Text('Set alarm here'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
