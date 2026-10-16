import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/neon_pinball/neon_pinball_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Neon Masa ${number.toString().padLeft(2, '0')}',
  titleEn: 'Neon Table ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Hedefleri sırayla vur',
  subtitleEn: 'Strike targets in order',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.sports_esports_rounded,
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

  testWidgets('ten-level pinball hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const NeonPinballGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Neon Pinball'), findsOneWidget);
    expect(find.text('1. Neon Masa 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('neon cabinet, held flippers, launcher and pause fit phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: NeonPinballPlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('neon_pinball_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('neon_pinball_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('neon_pinball_launch')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey<String>('neon_pinball_launch')));
    await tester.pump(const Duration(milliseconds: 32));
    final Finder left = find.byKey(const ValueKey<String>('neon_pinball_left'));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(left),
    );
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 40));
    final Finder pause = find.byKey(
      const ValueKey<String>('neon_pinball_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert pinball cabinet fits an 800-pixel tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: NeonPinballPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('neon_pinball_scene')),
      findsOneWidget,
    );
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('BALLS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
