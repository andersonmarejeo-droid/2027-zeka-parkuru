import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mini_golf_route/mini_golf_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Yeşil Parkur $number',
  titleEn: 'Green Course $number',
  subtitleTr: 'Parı yakala',
  subtitleEn: 'Beat par',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.sports_golf_rounded,
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

  testWidgets('10-level course hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const MiniGolfGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Mini Golf Rota'), findsOneWidget);
    expect(find.text('1. Yeşil Parkur 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag aim, spin controls and pause fit on phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: MiniGolfPlayPage(level: _level(4), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('mini_golf_scene')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('mini_golf_hud')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('mini_golf_spin_1')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('mini_golf_spin_1')));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byKey(const ValueKey<String>('mini_golf_strike')));
    await tester.pump(const Duration(milliseconds: 80));
    final Finder pause = find.byKey(const ValueKey<String>('mini_golf_pause'));
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master hole renders on a tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: MiniGolfPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('mini_golf_scene')),
      findsOneWidget,
    );
    expect(find.text('PAR 3'), findsOneWidget);
    expect(find.text('PUTT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
