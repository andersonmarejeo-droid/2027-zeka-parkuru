import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/ball_merge/ball_merge_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Füzyon Odası $number',
  titleEn: 'Fusion Chamber $number',
  subtitleTr: 'Küreleri birleştir',
  subtitleEn: 'Fuse the orbs',
  difficulty: 'USTALAŞMA',
  icon: Icons.blur_circular_rounded,
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

  testWidgets('10-level hub keeps the compact Turkish phone layout intact', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const BallMergeGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Top Birleştir'), findsOneWidget);
    expect(find.text('1. Füzyon Odası 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drop preview, aiming slider and pause are available on phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BallMergePlayPage(level: _level(4), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.byKey(const ValueKey<String>('ball_merge_scene')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ball_merge_hud')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('ball_merge_aim')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('ball_merge_drop')));
    await tester.pump(const Duration(milliseconds: 50));
    final Finder pause = find.byKey(const ValueKey<String>('ball_merge_pause'));
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master fusion chamber fits a tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: BallMergePlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.byKey(const ValueKey<String>('ball_merge_scene')), findsOneWidget);
    expect(find.text('FUSIONS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
