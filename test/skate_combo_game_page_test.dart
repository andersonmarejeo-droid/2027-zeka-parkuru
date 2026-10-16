import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/skate_combo/skate_combo_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Parkur ${number.toString().padLeft(2, '0')}',
  titleEn: 'Skate Line ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Hızlan ve temiz iniş yap',
  subtitleEn: 'Build speed and stick the landing',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.skateboarding_rounded,
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

  testWidgets('ten-level skate hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const SkateComboGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Kaykay Akışı'), findsOneWidget);
    expect(find.text('1. Parkur 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('park scene, pump control and pause fit the phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: SkateComboPlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('skate_combo_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('skate_combo_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('skate_combo_pump')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('skate_combo_pause')));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('skate_combo_pause')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master course fits an 800x1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: SkateComboPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('skate_combo_scene')),
      findsOneWidget,
    );
    expect(find.text('SKATE FLOW'), findsOneWidget);
    expect(find.text('PUMP / POP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
