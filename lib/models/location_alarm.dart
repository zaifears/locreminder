class LocationAlarm {
  const LocationAlarm({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;

  LocationAlarm copyWith({
    String? label,
    double? radiusMeters,
    bool? isActive,
  }) {
    return LocationAlarm(
      id: id,
      label: label ?? this.label,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocationAlarm.fromJson(Map<String, dynamic> json) => LocationAlarm(
        id: json['id'] as String,
        label: json['label'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
        isActive: json['isActive'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
