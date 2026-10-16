import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/rhythm_drums/rhythm_drums_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Ritim Etabı ${number.toString().padLeft(2, '0')}',
  titleEn: 'Rhythm Set ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Dört davul pediyle ritmi yakala',
  subtitleEn: 'Catch the beat across four percussion pads',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.graphic_eq_rounded,
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

  testWidgets('ten-level rhythm hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const RhythmDrumsGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Ritim Atölyesi'), findsOneWidget);
    expect(find.text('1. Ritim Etabı 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four-lane scene, pads and pause fit a 320x600 phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: RhythmDrumsPlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('rhythm_drums_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('rhythm_drums_hud')),
      findsOneWidget,
    );
    for (final (String lane, String label) in <(String, String)>[
      ('kick', 'BAS'),
      ('snare', 'TRAMPET'),
      ('hiHat', 'ZİL'),
      ('tom', 'TOM'),
    ]) {
      final Semantics pad = tester.widget<Semantics>(
        find.byKey(ValueKey<String>('rhythm_drums_pad_$lane')),
      );
      expect(pad.properties.label, label);
      expect(pad.properties.button, isTrue);
    }
    await tester.tap(find.byKey(const ValueKey<String>('rhythm_drums_pause')));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('rhythm_drums_pause')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert chart fits an 800x1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: RhythmDrumsPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('rhythm_drums_scene')),
      findsOneWidget,
    );
    expect(find.text('RHYTHM WORKSHOP'), findsOneWidget);
    expect(find.text('KICK'), findsOneWidget);
    expect(find.text('BAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
