import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/balloon_catcher/balloon_catcher_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Gökyüzü Rotası $number',
  titleEn: 'Sky Route $number',
  subtitleTr: 'Balonları yakala',
  subtitleEn: 'Catch balloons',
  difficulty: 'USTALAŞMA',
  icon: Icons.air_rounded,
);

Future<void> _mount(
  WidgetTester tester, {
  required Widget home,
  required Size size,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.light(useMaterial3: true),
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('10-level hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const BalloonCatcherGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Balon Avcısı'), findsOneWidget);
    expect(find.text('1. Gökyüzü Rotası 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact game scene is playable and pause preserves state', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BalloonCatcherPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );

    expect(find.byKey(const ValueKey<String>('balloon_scene')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('balloon_basket_slider')),
      findsOneWidget,
    );
    expect(find.text('0 / 5'), findsOneWidget);

    final Finder slider = find.byKey(
      const ValueKey<String>('balloon_basket_slider'),
    );
    await tester.ensureVisible(slider);
    await tester.drag(slider, const Offset(36, 0));
    await tester.pump();

    final Finder pause = find.byKey(const ValueKey<String>('balloon_pause'));
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English game scene fits a tablet', (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BalloonCatcherPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.byKey(const ValueKey<String>('balloon_hud')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('balloon_scene')), findsOneWidget);
    expect(find.text('0 / 9'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first centered target balloon can be collected', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BalloonCatcherPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(360, 720),
      locale: const Locale('tr'),
    );

    for (int frame = 0; frame < 330; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final String catchProgress = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text text) => text.data ?? '')
        .firstWhere((String text) => text.contains('/ 5'));
    expect(int.parse(catchProgress.split(' ').first), greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });
}
