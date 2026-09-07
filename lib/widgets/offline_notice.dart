import 'package:flutter/material.dart';

import '../services/offline_maps.dart';

/// Says the map has gone offline — and, the part that actually matters, that
/// the alarm has not.
///
/// People reasonably conclude from a blank map that the app has stopped
/// working, because on most apps a blank map means exactly that. Here it means
/// one server is out of reach. The arrival check is a comparison between two
/// coordinates on the phone, and the fix it compares comes off a receive-only
/// satellite radio, so it carries on in a tunnel, in aeroplane mode, on a
/// phone with no SIM in it.
///
/// Its own widget rather than a method on the map screen so that it can be
/// built in a test at the sizes and text scales that actually break layouts —
/// a narrow phone at the largest accessibility font is where a two-line
/// message in a row with an icon stops fitting, and there is no way to see
/// that from reading the code.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OfflineMaps.offline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            // Top, not centre: at a large font size the message runs to
            // several lines, and an icon floating in the middle of them reads
            // as belonging to whichever line it lands next to.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wifi_off, size: 20, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deliberately not "showing the saved map". That is true
                    // on the journey it was written for and a lie on the
                    // first run, where nothing has been saved yet and the
                    // sentence sits over an empty grid promising a map that
                    // is not there. What is true in both cases is which half
                    // of the app the missing connection actually affects.
                    Text(
                      'No connection',
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Only the map needs one. Your alarm rings on GPS alone.',
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
