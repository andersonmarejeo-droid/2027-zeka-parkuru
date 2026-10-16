import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/ring_toss/ring_toss_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Panayır Parkuru $number',
  titleEn: 'Fairground Course $number',
  subtitleTr: 'Direği yakala',
  subtitleEn: 'Catch the peg',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.sports_handball_rounded,
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

  testWidgets('10-level fairground hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const RingTossGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Halka At'), findsOneWidget);
    expect(find.text('1. Panayır Parkuru 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spin, release control and pause fit on an Android phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: RingTossPlayPage(level: _level(4), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('ring_toss_scene')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('ring_toss_hud')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('ring_toss_spin_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('ring_toss_throw')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('ring_toss_spin_1')));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(const ValueKey<String>('ring_toss_throw')));
    await tester.pump(const Duration(milliseconds: 80));
    final Finder pause = find.byKey(const ValueKey<String>('ring_toss_pause'));
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master fairground fits an 800-pixel tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: RingTossPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('ring_toss_scene')),
      findsOneWidget,
    );
    expect(find.text('RING TOSS'), findsOneWidget);
    expect(find.text('SPIN'), findsOneWidget);
    expect(find.text('TOSS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
