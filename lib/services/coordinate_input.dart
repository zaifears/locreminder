import 'package:latlong2/latlong.dart';

/// Reads a latitude/longitude pair out of whatever the user typed into the
/// search box.
///
/// The search box otherwise goes to Nominatim, which is a server, which means
/// searching by name is the one part of setting an alarm that a connection is
/// genuinely required for. Coordinates need no server at all — they *are* the
/// answer a search would return — so a person with no data can still place an
/// alarm exactly, from a figure somebody sent them, on a map that may be
/// showing nothing at all.
///
/// Deliberately strict. This runs on every keystroke and decides whether to
/// search the internet or not, so it has to be certain: the entire string must
/// be two numbers and nothing else. "Sector 10, Road 5" contains two numbers
/// and a comma and is unmistakably a place name — anything with letters in it
/// beyond a hemisphere mark falls through to the ordinary search.
///
/// Understood, in any combination:
///
///     23.8103, 90.4125        23.8103 90.4125        23.8103,90.4125
///     -23.8103, -90.4125      23.8103° N, 90.4125° E
///     N 23.8103, E 90.4125    90.4125 E, 23.8103 N     (order from the marks)
///     geo:23.8103,90.4125     (what Android's "share location" produces)
LatLng? parseCoordinates(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;

    // Android shares a place as a geo: URI, sometimes with parameters after a
    // semicolon. The coordinates are the part before it.
    if (text.toLowerCase().startsWith('geo:')) {
      text = text.substring(4).split(';').first;
    }

    // Comma first, because "23.81, 90.41" contains both separators and the
    // comma is the one that means something.
    final int split;
    if (text.contains(',')) {
      split = text.indexOf(',');
    } else {
      final space = RegExp(r'\s').firstMatch(text);
      if (space == null) return null;
      split = space.start;
    }

    final first = _parseComponent(text.substring(0, split));
    final second = _parseComponent(text.substring(split + 1));
    if (first == null || second == null) return null;

    // Hemisphere marks say which number is which, so a pair written the other
    // way round still lands where it should. Without them, the convention is
    // latitude first, as every map on earth writes it.
    final double latitude;
    final double longitude;
    if (first.axis == _Axis.longitude || second.axis == _Axis.latitude) {
      // Only trust the swap when nothing contradicts it.
      if (first.axis == _Axis.latitude || second.axis == _Axis.longitude) {
        return null;
      }
      latitude = second.value;
      longitude = first.value;
    } else {
      latitude = first.value;
      longitude = second.value;
    }

    if (latitude.abs() > 90 || longitude.abs() > 180) return null;
    return LatLng(latitude, longitude);
}

/// Formats a point the way this parser reads it back, for showing the user
/// where a pin actually is when there is no address to show instead.
///
/// Five decimal places is about a metre — past the precision of the fix, the
/// map data, and anything a person would type.
String formatCoordinates(double latitude, double longitude) =>
    '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

enum _Axis { latitude, longitude }

class _Component {
  const _Component(this.value, this.axis);
  final double value;
  final _Axis? axis;
}

/// One half of a coordinate: a number, optionally carrying a degree symbol and
/// a hemisphere letter on either side of it.
_Component? _parseComponent(String raw) {
  var text = raw.trim().toUpperCase().replaceAll('°', '').trim();
  if (text.isEmpty) return null;

  _Axis? axis;
  bool negative = false;

  void takeMark(String mark) {
    axis = (mark == 'N' || mark == 'S') ? _Axis.latitude : _Axis.longitude;
    negative = mark == 'S' || mark == 'W';
  }

  const marks = {'N', 'S', 'E', 'W'};
  if (marks.contains(text[0])) {
    takeMark(text[0]);
    text = text.substring(1).trim();
  } else if (marks.contains(text[text.length - 1])) {
    takeMark(text[text.length - 1]);
    text = text.substring(0, text.length - 1).trim();
  }

  // A sign and a hemisphere mark together say the same thing twice, and when
  // they disagree there is no reading that is obviously right. Refuse rather
  // than guess: it falls through to an ordinary search, which is recoverable.
  final signed = text.startsWith('-') || text.startsWith('+');
  if (axis != null && signed) return null;

  final value = double.tryParse(text);
  if (value == null || !value.isFinite) return null;

  return _Component(negative ? -value : value, axis);
}
