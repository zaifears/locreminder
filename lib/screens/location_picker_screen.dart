import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_alarm.dart';
import '../models/place_result.dart';
import '../services/geocoding_service.dart';
import '../services/radius_advice.dart';
import '../widgets/map_pin.dart';
import '../widgets/map_tiles.dart';

class PickedLocation {
  const PickedLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.repeatDays,
  });

  final String label;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  /// Weekdays the alarm is armed on; empty means once. See [RepeatSchedule].
  final Set<int> repeatDays;
}

/// Full-screen destination picker: search by name, or drag the map under a
/// fixed centre crosshair. Replaces blind tapping — you can look up "Dhaka
/// Airport" instead of hunting for it on the map.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.initialCenter,
    this.autofocusSearch = false,
    this.travelSpeed,
  });

  final LatLng initialCenter;

  /// Whether to raise the keyboard on arrival.
  ///
  /// True when the user tapped the search field on the map, where they have
  /// already said what they want to do and a second tap to summon the
  /// keyboard is pure friction. False when they tapped "Add alarm", which
  /// asks for a place on the map, not a name.
  final bool autofocusSearch;

  /// The user's current speed in metres per second, where it is known.
  /// Decides the starting radius: see [minimumRadiusForSpeed].
  final double? travelSpeed;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  final _geocoder = GeocodingService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  /// What the alarm is *for*, in the user's words. Left empty on purpose.
  ///
  /// The place name is offered as the hint rather than written into the
  /// field, so there is nothing to clear before typing "Buy medicine" and
  /// nothing for a reverse-geocode landing 700ms later to overwrite. Empty
  /// simply means "call it after the place", which [_confirm] resolves.
  final _labelController = TextEditingController();

  Set<int> _repeatDays = RepeatSchedule.once;
  MapStyle _mapStyle = MapStyle.standard;

  late LatLng _center = widget.initialCenter;
  List<PlaceResult> _results = const [];
  bool _searching = false;
  bool _showResults = false;
  bool _searchFailed = false;
  Timer? _searchDebounce;

  String? _address;
  bool _resolvingAddress = false;
  Timer? _addressDebounce;

  late double _radius = _initialRadius();
  String? _chosenName;

  /// Whether the starting radius was raised because of [widget.travelSpeed],
  /// which is worth explaining rather than silently doing.
  late final double? _speedFloor = minimumRadiusForSpeed(widget.travelSpeed);

  /// Opens wider than the 500m default when the user is moving fast enough
  /// that 500m could be crossed between two location checks. Defaulting to
  /// the safe value and explaining it beats showing a hint next to a slider
  /// already sitting on a number that will not work.
  double _initialRadius() {
    const fallback = 500.0;
    final floor = minimumRadiusForSpeed(widget.travelSpeed);
    return floor == null || floor < fallback ? fallback : floor;
  }

  @override
  void initState() {
    super.initState();
    _resolveAddress();
    // Follows whatever the map screen is showing, rather than asking again.
    MapStyleStore.load().then((style) {
      if (mounted) setState(() => _mapStyle = style);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _addressDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _labelController.dispose();
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

  /// What to call this place when the user does not name the task themselves.
  /// One getter so the hint and the fallback can never drift apart.
  String get _placeName {
    final chosen = _chosenName?.trim();
    if (chosen != null && chosen.isNotEmpty) return chosen;
    final first = _address?.split(',').first.trim();
    if (first != null && first.isNotEmpty) return first;
    return 'Destination';
  }

  void _confirm() {
    final typed = _labelController.text.trim();
    Navigator.of(context).pop(
      PickedLocation(
        label: typed.isNotEmpty ? typed : _placeName,
        latitude: _center.latitude,
        longitude: _center.longitude,
        radiusMeters: _radius,
        repeatDays: _repeatDays,
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
              // See [mapMinZoom]: unbounded zoom is what lets a fast pinch
              // put a non-finite value into the camera.
              minZoom: mapMinZoom,
              maxZoom: mapMaxZoom,
              onPositionChanged: _onMapMoved,
              onTap: (_, __) => _searchFocus.unfocus(),
            ),
            children: [
              buildTileLayer(context, style: _mapStyle),
              _RadiusCircle(radius: _radius, color: scheme.primary),
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

          _buildSearchBar(context),
          if (_showResults) _buildResultsOverlay(context),

          // The credit rides directly on top of the panel rather than at a
          // measured offset from the bottom of the screen. It used to sit at
          // a hard-coded 232, which was the panel's height at the time; adding
          // the task field and the repeat row to that panel would have slid it
          // underneath, and covering the OpenStreetMap credit is a licence
          // problem, not a layout one. Stacked, it cannot happen again.
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: MapAttribution(style: _mapStyle),
                ),
                // Flexible, not a bare child: the Column hands an unbounded
                // height to a non-flex child, which a SingleChildScrollView
                // would happily grow into and overflow. Loose flex caps it at
                // whatever the stack has left, and the panel scrolls inside.
                Flexible(child: _buildBottomPanel(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Explains a radius that was widened for the speed the user is travelling
  /// at, and warns if they then drag it back below what that speed needs.
  ///
  /// Silent when standing still or walking, which is most of the time: a note
  /// that is always on screen is one nobody reads when it matters.
  Widget _buildSpeedNote(BuildContext context) {
    final floor = _speedFloor;
    final speed = widget.travelSpeed;
    if (floor == null || speed == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final tooTight = _radius < floor;
    final asText = floor >= 1000
        ? '${(floor / 1000).toStringAsFixed(1)} km'
        : '${floor.round()} m';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tooTight ? Icons.warning_amber_rounded : Icons.speed,
            size: 16,
            color: tooTight ? scheme.error : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tooTight
                  ? "You're moving at ${kilometresPerHour(speed)} km/h. Below "
                      '$asText the alarm can pass your stop between location '
                      'checks.'
                  : "You're moving at ${kilometresPerHour(speed)} km/h, so "
                      'this starts at $asText to give the alarm room to catch '
                      'you.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tooTight ? scheme.error : scheme.onSurfaceVariant,
                  ),
            ),
          ),
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
                  autofocus: widget.autofocusSearch,
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
    return Material(
      elevation: 12,
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        // Scrollable because this panel is no longer a fixed height: the task
        // field and the repeat row added roughly 140px, and with the keyboard
        // up on a short screen there is not always that much left. Scrolling
        // is the difference between a cramped panel and a RenderFlex overflow
        // across the one control the user came here to press.
        child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                TextField(
                  controller: _labelController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  // Long enough for a real errand, short enough to stay one
                  // line on the alarm screen and in the notification.
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: 'Remind me to',
                    // The place name, so leaving it blank is visibly a
                    // choice with a known result rather than a gap.
                    hintText: _resolvingAddress ? 'Buy medicine…' : _placeName,
                    prefixIcon: const Icon(Icons.edit_note),
                    counterText: '',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                _buildRepeatRow(context),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Remind me within',
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
                _buildSpeedNote(context),
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

  /// One compact row rather than a grid of chips, because the panel already
  /// competes with the map for the screen and most alarms are still one-shot.
  Widget _buildRepeatRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _pickRepeat,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.repeat, size: 20, color: scheme.primary),
            const SizedBox(width: 12),
            Text('Repeat', style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(
              RepeatSchedule.describe(_repeatDays),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRepeat() async {
    _searchFocus.unfocus();
    final picked = await showRepeatSheet(context, _repeatDays);
    if (picked == null || !mounted) return;
    setState(() => _repeatDays = picked);
  }
}

/// The radius circle under the picker's fixed crosshair.
///
/// It reads the centre from the live [MapCamera] rather than being handed a
/// coordinate by the screen, because the screen only learns the new centre
/// through `onPositionChanged` and rebuilding the whole picker on every frame
/// of a drag to pass it down would be wasteful. Taking it from the camera
/// here rebuilds one layer instead — and fixes the circle drifting off the
/// crosshair mid-drag and snapping back once the address lookup settled,
/// which made the pin look like it was not where the alarm would go.
class _RadiusCircle extends StatelessWidget {
  const _RadiusCircle({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleLayer(
      circles: [
        CircleMarker(
          point: MapCamera.of(context).center,
          radius: radius,
          useRadiusInMeter: true,
          color: color.withValues(alpha: 0.12),
          borderColor: color.withValues(alpha: 0.7),
          borderStrokeWidth: 2,
        ),
      ],
    );
  }
}

/// Asks how often the alarm should ring, returning the weekdays it is armed
/// on — or null if the user backed out. See [RepeatSchedule] for the encoding.
Future<Set<int>?> showRepeatSheet(BuildContext context, Set<int> current) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _RepeatSheet(initial: current),
  );
}

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({required this.initial});

  final Set<int> initial;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  // Final because it is only ever mutated in place, never reassigned. The
  // copy matters though: mutating widget.initial directly would edit the
  // caller's set, so backing out of the sheet would still have changed it.
  late final Set<int> _days = widget.initial.toSet();

  void _toggle(int day) {
    setState(() {
      if (!_days.remove(day)) _days.add(day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOnce = _days.isEmpty;
    final isDaily = RepeatSchedule.setEquals(_days, RepeatSchedule.daily);

    return SafeArea(
      // Seven chips wrap to two rows at large system text sizes, and the
      // explanation above them grows too. Scrollable so the "Set to …" button
      // stays reachable on a short screen instead of being pushed off it.
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'A repeating alarm rings once each day it is set for, and stays '
                'armed afterwards. A one-off deletes itself once it has rung.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.looks_one_outlined, color: scheme.primary),
                title: const Text('Once'),
                trailing: isOnce ? Icon(Icons.check, color: scheme.primary) : null,
                onTap: () => Navigator.of(context).pop(RepeatSchedule.once),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.today_outlined, color: scheme.primary),
                title: const Text('Every day'),
                trailing: isDaily ? Icon(Icons.check, color: scheme.primary) : null,
                onTap: () => Navigator.of(context).pop(RepeatSchedule.daily),
              ),
              const Divider(height: 24),
              Text(
                'Or pick the days',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              // Wrap rather than Row: seven chips do not fit across a narrow
              // phone at a large font scale, and this is exactly the screen
              // where the system text size is likely to be turned up.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(RepeatSchedule.shortName(day)),
                      selected: _days.contains(day),
                      onSelected: (_) => _toggle(day),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_days),
                  // Says what the choice actually means, so clearing every chip
                  // reading as "Once" is visible before it is committed.
                  child: Text('Set to ${RepeatSchedule.describe(_days)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
