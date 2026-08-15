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
}
