import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/snowboard_slalom/snowboard_slalom_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Kar Parkuru ${number.toString().padLeft(2, '0')}',
  titleEn: 'Snow Run ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Kapılara kavis çiz',
  subtitleEn: 'Carve through each gate',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.downhill_skiing_rounded,
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

  testWidgets('ten-level snow hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const SnowboardSlalomGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Kar Sörfü Slalomu'), findsOneWidget);
    expect(find.text('1. Kar Parkuru 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snow scene, brake and pause fit the phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: SnowboardSlalomPlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('snowboard_slalom_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('snowboard_slalom_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('snowboard_slalom_brake')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('snowboard_slalom_pause')),
    );
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('snowboard_slalom_pause')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English snow master course fits an 800x1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: SnowboardSlalomPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('snowboard_slalom_scene')),
      findsOneWidget,
    );
    expect(find.text('SNOWBOARD SLALOM'), findsOneWidget);
    expect(find.text('BRAKE · HOLD TO SCRUB SPEED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
