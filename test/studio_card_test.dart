import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';
import 'package:zeka_parkuru/widgets/studio_card.dart';

void main() {
  testWidgets('shared cards keep a generous tap target and full-card action', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;

    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: StudioCard(
              key: const ValueKey<String>('shared-studio-card'),
              semanticLabel: 'Açılabilir kart',
              onTap: () => taps++,
              child: const Text('Kart içeriği'),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('shared-studio-card')))
          .height,
      StudioVisuals.cardMinTapHeight,
    );
    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey<String>('shared-studio-card')),
      ),
    );
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page frame caps tablet width but stays fluid on phones', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudioPageFrame(
            child: SizedBox(
              key: ValueKey<String>('framed-content'),
              width: double.infinity,
              height: 20,
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('framed-content')))
          .width,
      StudioVisuals.contentMaxWidth,
    );

    tester.view.physicalSize = const Size(360, 800);
    await tester.pump();
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('framed-content')))
          .width,
      360,
    );
    expect(tester.takeException(), isNull);
  });
}
