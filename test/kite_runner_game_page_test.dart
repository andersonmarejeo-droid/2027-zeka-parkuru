import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kite_runner/kite_runner_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Rüzgâr Etabı ${number.toString().padLeft(2, '0')}',
  titleEn: 'Wind Leg ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'İpi ayarla ve bayraklardan geç',
  subtitleEn: 'Trim the line and clear the flags',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
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

  testWidgets('ten-level kite hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const KiteRunnerGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Uçurtma Pilotu'), findsOneWidget);
    expect(find.text('1. Rüzgâr Etabı 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sky scene, tether pad and pause fit the phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: KiteRunnerPlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('kite_runner_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('kite_runner_hud')),
      findsOneWidget,
    );
    final Finder controls = find.byKey(
      const ValueKey<String>('kite_runner_controls'),
    );
    expect(controls, findsOneWidget);
    await tester.drag(controls, const Offset(14, -10));
    await tester.pump(const Duration(milliseconds: 60));
    final Finder pause = find.byKey(
      const ValueKey<String>('kite_runner_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert course fits an 800-pixel tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: KiteRunnerPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('kite_runner_scene')),
      findsOneWidget,
    );
    expect(find.text('FLAGS'), findsOneWidget);
    expect(find.text('HEIGHT'), findsOneWidget);
    expect(find.text('KITE PILOT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
