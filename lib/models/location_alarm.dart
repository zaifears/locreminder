/// How often an alarm may ring, held as the set of weekdays it is armed on.
///
/// One field covers every choice the picker offers, in `DateTime.weekday`
/// numbering (1 = Monday … 7 = Sunday). Empty means once and then it is gone;
/// a single day is weekly; all seven is daily; anything else is a custom set.
///
/// Deliberately a set rather than an enum plus a payload. "Weekly" and "every
/// Tuesday and Thursday" differ only in how many days are in the set, and an
/// enum would have to carry the set anyway — then the two could disagree, and
/// the one the alarm actually fires on would be whichever the native side
/// happened to read.
abstract final class RepeatSchedule {
  /// Fires once, then deletes itself. The default, and what every alarm
  /// saved before repeats existed becomes on upgrade.
  static const Set<int> once = <int>{};

  static const Set<int> daily = {1, 2, 3, 4, 5, 6, 7};
  static const Set<int> weekdays = {1, 2, 3, 4, 5};
  static const Set<int> weekends = {6, 7};

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _longNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Short name for weekday [day], 1 = Monday.
  static String shortName(int day) => _names[day - 1];

  /// How to say this schedule in a sentence.
  static String describe(Set<int> days) {
    if (days.isEmpty) return 'Once';
    if (days.length == 7) return 'Every day';
    if (setEquals(days, weekdays)) return 'Weekdays';
    if (setEquals(days, weekends)) return 'Weekends';
    if (days.length == 1) return 'Every ${_longNames[days.first - 1]}';
    final sorted = days.toList()..sort();
    return sorted.map(shortName).join(', ');
  }

  /// Keeps only real weekday numbers, so a corrupt or hand-edited record
  /// cannot put an out-of-range day in front of the native side.
  static Set<int> sanitize(Iterable<int> days) =>
      days.where((d) => d >= 1 && d <= 7).toSet();

  static bool setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}

class LocationAlarm {
  const LocationAlarm({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    required this.createdAt,
    this.repeatDays = RepeatSchedule.once,
  });

  final String id;

  /// What the user is here to do, in their words — "Buy medicine" — falling
  /// back to the name of the place when they do not type anything.
  final String label;

  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;

  /// Weekdays this alarm is armed on; see [RepeatSchedule].
  final Set<int> repeatDays;

  bool get repeats => repeatDays.isNotEmpty;

  /// How this alarm's schedule reads in the list.
  String get scheduleLabel => RepeatSchedule.describe(repeatDays);

  LocationAlarm copyWith({
    String? label,
    double? radiusMeters,
    bool? isActive,
    Set<int>? repeatDays,
  }) {
    return LocationAlarm(
      id: id,
      label: label ?? this.label,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      repeatDays: repeatDays ?? this.repeatDays,
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
        // Sorted so an unchanged alarm serialises identically every time,
        // which keeps a rewrite of the list from looking like an edit.
        'repeatDays': (repeatDays.toList()..sort()),
      };

  factory LocationAlarm.fromJson(Map<String, dynamic> json) => LocationAlarm(
        id: json['id'] as String,
        label: json['label'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
        isActive: json['isActive'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        // Absent on every alarm saved before repeats existed, which is
        // exactly what those alarms were: one-shot.
        repeatDays: RepeatSchedule.sanitize(
          (json['repeatDays'] as List<dynamic>? ?? const [])
              .map((d) => (d as num).toInt()),
        ),
      );
}
