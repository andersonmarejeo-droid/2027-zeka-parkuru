import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Üretim Hattı $number',
  titleEn: 'Confectionery Line $number',
  subtitleTr: 'Kavşakları yönet',
  subtitleEn: 'Manage the diverters',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.factory_rounded,
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
      home: const SlideSweetsGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Şeker Konveyörü'), findsOneWidget);
    expect(find.text('1. Üretim Hattı 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live gates, order ribbon and pause fit a small screen', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // Seviye 4 tek kapılıdır (gateCount = 1)
    await _mount(
      tester,
      home: SlideSweetsPlayPage(level: _level(4), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('slide_sweets_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('slide_sweets_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('slide_sweets_gate_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('slide_sweets_gate_1')),
      findsNothing,
    );
    for (final int direction in <int>[-1, 0, 1]) {
      expect(
        find.byKey(
          ValueKey<String>(
            'slide_sweets_gate_0_direction_$direction',
          ),
        ),
        findsOneWidget,
      );
    }
    await tester.tap(
      find.byKey(
        const ValueKey<String>('slide_sweets_gate_0_direction_1'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('ALT BANT'), findsOneWidget);
    final Finder pause = find.byKey(
      const ValueKey<String>('slide_sweets_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English dual-gate line fits a tablet without clipping', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // Seviye 12 çift kapılıdır (gateCount = 2)
    await _mount(
      tester,
      home: SlideSweetsPlayPage(level: _level(12), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('slide_sweets_scene')),
      findsOneWidget,
    );
    expect(find.text('SWEET CONVEYOR'), findsOneWidget);
    expect(find.text('GATE 1'), findsOneWidget);
    expect(find.text('GATE 2'), findsOneWidget);
    expect(find.text('MIDDLE BELT'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
