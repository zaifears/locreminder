import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgentPackageName = 'com.zaifears.locreminder';

/// Inverts tile luminance while preserving hue, so the light OSM raster
/// tiles read as a dark map instead of a glaring white rectangle in a dark
/// themed app.
const _darkTileFilter = ColorFilter.matrix(<double>[
  -0.2126, -0.7152, -0.0722, 0, 255, //
  -0.2126, -0.7152, -0.0722, 0, 255, //
  -0.2126, -0.7152, -0.0722, 0, 255, //
  0, 0, 0, 1, 0, //
]);

/// Shared OpenStreetMap tile layer, theme-aware so both map screens stay
/// consistent and neither forgets the required attribution/User-Agent.
TileLayer buildTileLayer(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TileLayer(
    urlTemplate: _osmTileUrl,
    userAgentPackageName: _userAgentPackageName,
    tileBuilder: isDark
        ? (context, tileWidget, tile) =>
            ColorFiltered(colorFilter: _darkTileFilter, child: tileWidget)
        : null,
  );
}

/// OpenStreetMap's licence requires visible attribution wherever tiles show.
///
/// Deliberately a plain overlay rather than flutter_map's own attribution
/// layer: both map screens have a panel pinned to the bottom of the stack,
/// which would sit on top of the built-in bottom-right attribution and hide
/// it entirely. The caller positions this where it stays visible.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

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
          '© OpenStreetMap',
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
