import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _userAgentPackageName = 'com.zaifears.locreminder';
const _styleKey = 'map_style';

/// A raster tile source.
///
/// Every option here renders OpenStreetMap data and is served by a project
/// that publishes its own stack, so the app stays free software end to end.
/// Satellite imagery is deliberately absent: every provider of it (Google,
/// Esri, Bing, Mapbox) is a proprietary service, and depending on one would
/// undo that for a feature this app does not need.
enum MapStyle {
  standard(
    id: 'standard',
    label: 'Standard',
    description: 'The usual OpenStreetMap look',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap',
    invertsForDarkTheme: true,
  ),
  humanitarian(
    id: 'humanitarian',
    label: 'Humanitarian',
    description: 'Higher contrast, clearer labels',
    urlTemplate: 'https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap · HOT',
    invertsForDarkTheme: true,
  ),
  topographic(
    id: 'topographic',
    label: 'Topographic',
    description: 'Contours and terrain',
    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap · OpenTopoMap (CC-BY-SA)',
    // Inverting shaded relief turns hills inside out, so leave it alone.
    invertsForDarkTheme: false,
  ),
  cycle(
    id: 'cyclosm',
    label: 'Cycle',
    description: 'Paths, lanes and cycle routes',
    urlTemplate: 'https://a.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap · CyclOSM',
    invertsForDarkTheme: false,
  );

  const MapStyle({
    required this.id,
    required this.label,
    required this.description,
    required this.urlTemplate,
    required this.attribution,
    required this.invertsForDarkTheme,
  });

  final String id;
  final String label;
  final String description;
  final String urlTemplate;
  final String attribution;
  final bool invertsForDarkTheme;

  static MapStyle fromId(String? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => standard);
}

/// Remembers the chosen style. Kept device-local like everything else here.
class MapStyleStore {
  static Future<MapStyle> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MapStyle.fromId(prefs.getString(_styleKey));
  }

  static Future<void> save(MapStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_styleKey, style.id);
  }
}

/// Inverts tile luminance while preserving hue, so light raster tiles read as
/// a dark map instead of a glaring white rectangle in a dark themed app.
const _darkTileFilter = ColorFilter.matrix(<double>[
  -0.2126, -0.7152, -0.0722, 0, 255, //
  -0.2126, -0.7152, -0.0722, 0, 255, //
  -0.2126, -0.7152, -0.0722, 0, 255, //
  0, 0, 0, 1, 0, //
]);

/// One retrying client shared by every tile layer.
///
/// A tile that fails once used to stay blank until the app was restarted,
/// which is what made the map look broken after switching between wifi and
/// mobile data: the handover kills in-flight requests, and nothing tried
/// again. Retries cover that, with a widening delay so a genuinely
/// unreachable server is not hammered.
///
/// 5xx and transport failures are retried; 429 deliberately is not.
/// OpenStreetMap's tile policy treats that as "back off", and retrying
/// through it would be the sort of behaviour that gets an app blocked.
final http.Client _tileClient = RetryClient(
  http.Client(),
  retries: 3,
  when: (response) => response.statusCode >= 500,
  whenError: (error, _) =>
      error is SocketException ||
      error is HttpException ||
      error is TimeoutException ||
      error is http.ClientException,
  delay: (retry) => Duration(milliseconds: 400 * (1 << retry)),
);

/// Shared tile layer, so both map screens stay consistent and neither forgets
/// the attribution, the User-Agent or the retry behaviour.
TileLayer buildTileLayer(BuildContext context, {MapStyle style = MapStyle.standard}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final invert = isDark && style.invertsForDarkTheme;

  return TileLayer(
    urlTemplate: style.urlTemplate,
    userAgentPackageName: _userAgentPackageName,
    tileProvider: NetworkTileProvider(httpClient: _tileClient),
    // Without this a tile that failed stays failed for the lifetime of the
    // map, even once the network is back. Evicting it means panning away and
    // back is enough to trigger a fresh attempt.
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
    tileBuilder: invert
        ? (context, tileWidget, tile) =>
            ColorFiltered(colorFilter: _darkTileFilter, child: tileWidget)
        : null,
  );
}

/// OpenStreetMap's licence requires visible attribution wherever tiles show,
/// and the alternative styles each want their own credit alongside it.
///
/// Deliberately a plain overlay rather than flutter_map's own attribution
/// layer: both map screens have a panel pinned to the bottom of the stack,
/// which would sit on top of the built-in bottom-right attribution and hide
/// it entirely. The caller positions this where it stays visible.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, this.style = MapStyle.standard});

  final MapStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          style.attribution,
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Lets the user pick a style, and explains why satellite is not on offer:
/// people do ask, and "we left it out on purpose" reads better than silence.
Future<MapStyle?> showMapStyleSheet(BuildContext context, MapStyle current) {
  return showModalBottomSheet<MapStyle>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text('Map style', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            // A plain tile with a tick rather than RadioListTile, whose
            // groupValue/onChanged pair is deprecated in favour of a
            // RadioGroup ancestor. A sheet that closes on tap does not need
            // the extra widget to express one choice out of four.
            for (final style in MapStyle.values)
              ListTile(
                selected: style == current,
                title: Text(style.label),
                subtitle: Text(style.description),
                trailing: style == current
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(style),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'No satellite view: every provider of satellite imagery is a '
                'closed service, and LocReminder keeps to open data so it '
                'works without any account or tracking.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
