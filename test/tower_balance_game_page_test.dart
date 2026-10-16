import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/tower_balance/tower_balance_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Denge Atölyesi $number',
  titleEn: 'Balance Workshop $number',
  subtitleTr: 'Kuleyi dengede tut',
  subtitleEn: 'Keep the tower balanced',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.balance_rounded,
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
      home: const TowerBalanceGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Kule Denge'), findsOneWidget);
    expect(find.text('1. Denge Atölyesi 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('piece preview, balance controls and pause fit on phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: TowerBalancePlayPage(level: _level(4), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('tower_balance_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('tower_balance_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('tower_balance_aim')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('tower_balance_place')));
    await tester.pump();
    final Finder pause = find.byKey(
      const ValueKey<String>('tower_balance_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master course and support pin render on a tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: TowerBalancePlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('tower_balance_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('tower_balance_pin')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
