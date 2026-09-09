/// A single geocoding search result from Nominatim.
class PlaceResult {
  const PlaceResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;

  /// The first comma-separated component, which is usually the place's own
  /// name — used as the headline in search results and as a default alarm label.
  String get shortName => displayName.split(',').first.trim();

  /// Everything after the headline, shown as dimmed context under it.
  String get context {
    final parts = displayName.split(',');
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(',').trim();
  }

  factory PlaceResult.fromNominatimJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] as String? ?? 'Unknown place',
      latitude: double.parse(json['lat'] as String),
      longitude: double.parse(json['lon'] as String),
    );
  }

  /// Builds a result from one GeoJSON feature returned by Photon.
  ///
  /// Photon has no `display_name` — it returns the address in pieces, which
  /// is more useful data and slightly more work. Composing them back into one
  /// comma-separated line keeps [shortName] and [context] doing exactly what
  /// they already do for Nominatim, so the search list does not need to know
  /// which service answered.
  ///
  /// Returns null for a feature with no usable position or nothing to call
  /// it, rather than a row reading "Unknown place" that goes nowhere.
  static PlaceResult? fromPhotonFeature(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    if (geometry is! Map<String, dynamic>) return null;
    final coordinates = geometry['coordinates'];
    // GeoJSON is longitude first, which is the opposite of every other
    // coordinate in this app and the easiest thing in the world to get
    // backwards.
    if (coordinates is! List || coordinates.length < 2) return null;
    final longitude = (coordinates[0] as num?)?.toDouble();
    final latitude = (coordinates[1] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;

    final properties = json['properties'];
    final props = properties is Map<String, dynamic> ? properties : const {};

    String? field(String key) {
      final value = props[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    // The headline: what the place is called, or failing that where it is.
    final street = field('street');
    final houseNumber = field('housenumber');
    final headline = field('name') ??
        (street != null && houseNumber != null ? '$houseNumber $street' : null) ??
        street ??
        field('city') ??
        field('state') ??
        field('country');
    if (headline == null) return null;

    // Everything after it, coarsest last, skipping anything already said.
    final parts = <String>[headline];
    for (final part in [
      if (field('name') != null) street,
      field('district'),
      field('city'),
      field('county'),
      field('state'),
      field('country'),
    ]) {
      if (part != null && !parts.contains(part)) parts.add(part);
    }

    return PlaceResult(
      displayName: parts.join(', '),
      latitude: latitude,
      longitude: longitude,
    );
  }
}
