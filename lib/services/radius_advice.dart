/// How large an alarm radius has to be to survive the speed you are
/// travelling at.
///
/// The watcher samples your position on an interval, not continuously, so a
/// radius is only useful if you are still inside it when a sample lands. Cross
/// a circle faster than the gap between fixes and the whole thing can pass by
/// unsampled: the alarm never sees you arrive.
///
/// Approaching a destination, the watcher is polling on the 20-second band
/// (500m to 1.5km out) for the stretch that decides this, so the radius needs
/// to cover roughly `speed x 20s` of travel. That gives:
///
/// | Travelling      | Needs at least |
/// |-----------------|----------------|
/// | under 25 km/h   | 100 m (the floor) |
/// | 25 to 50 km/h   | 300 m |
/// | 50 to 90 km/h   | 500 m |
/// | over 90 km/h    | 1 km |
///
/// Under 25 km/h nothing is needed beyond the existing floor, because within
/// 500m the interval has already tightened to 10 seconds and 7 m/s only
/// covers 70m in that time.
library;

/// Smallest radius, in metres, that is dependable at [speedMetresPerSecond].
///
/// Returns null when the speed is unknown, implausible, or slow enough that
/// the ordinary minimum already covers it — in other words, whenever there is
/// nothing worth telling the user.
double? minimumRadiusForSpeed(double? speedMetresPerSecond) {
  final speed = speedMetresPerSecond;
  // Negative is the "unknown" convention on some providers, and a stationary
  // phone reports jitter rather than a clean zero. Anything above about
  // 400 km/h is a bad fix, not a journey.
  if (speed == null || speed < 1 || speed > 110) return null;

  if (speed > 25) return 1000;
  if (speed > 14) return 500;
  if (speed > 7) return 300;
  return null;
}

/// The speed itself, in km/h, for telling the user what was measured.
int kilometresPerHour(double metresPerSecond) => (metresPerSecond * 3.6).round();
