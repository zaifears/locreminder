import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locreminder/services/offline_maps.dart';
import 'package:locreminder/widgets/offline_notice.dart';

/// Layout checks for the one piece of UI this app adds to a screen that is
/// already full.
///
/// A Flutter overflow is not a crash and not a test failure by default — it
/// paints a yellow-and-black bar and carries on — so the interesting cases
/// have to be pumped and the exception looked for deliberately. The sizes
/// below are the ones that actually break things: the narrowest phone still
/// in use, and the largest font size Android's accessibility settings offer.
void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(child: Column(children: [child])),
              ),
            ],
          ),
        ),
      );

  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    required double textScale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: host(const OfflineNotice()),
      ),
    );
  }

  setUp(() => OfflineMaps.offline.value = false);
  tearDown(() => OfflineMaps.offline.value = false);

  testWidgets('takes up no room at all while the network is fine', (tester) async {
    await pumpAt(tester, size: const Size(360, 640), textScale: 1);

    expect(find.byType(Icon), findsNothing);
    expect(tester.getSize(find.byType(OfflineNotice)).height, 0);
  });

  testWidgets('appears when a tile reports the network is unreachable',
      (tester) async {
    await pumpAt(tester, size: const Size(360, 640), textScale: 1);

    OfflineMaps.offline.value = true;
    await tester.pump();

    expect(find.textContaining('No connection'), findsOneWidget);
    expect(find.textContaining('GPS alone'), findsOneWidget);
  });

  for (final (label, size, scale) in <(String, Size, double)>[
    ('a narrow phone', Size(320, 480), 1.0),
    ('the largest accessibility font', Size(320, 480), 2.0),
    ('a small screen at a huge font', Size(280, 420), 2.5),
    ('a tablet', Size(1024, 768), 1.0),
  ]) {
    testWidgets('lays out without overflowing on $label', (tester) async {
      await pumpAt(tester, size: size, textScale: scale);
      OfflineMaps.offline.value = true;
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Still readable, not collapsed to nothing by the squeeze.
      expect(find.textContaining('No connection'), findsOneWidget);
    });
  }
}
