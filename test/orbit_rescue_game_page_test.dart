import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/orbit_rescue/orbit_rescue_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Kurtarma Yörüngesi ${number.toString().padLeft(2, '0')}',
  titleEn: 'Rescue Orbit ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Kütleçekimini kullan ve rotayı çiz',
  subtitleEn: 'Use gravity and plot the route',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.public_rounded,
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

  testWidgets('ten-level orbit hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const OrbitRescueGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Yörünge Kurtarma'), findsOneWidget);
    expect(find.text('1. Kurtarma Yörüngesi 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gravity scene, steering pad, impulse and pause fit phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: OrbitRescuePlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('orbit_rescue_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('orbit_rescue_controls')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('orbit_rescue_impulse')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('orbit_rescue_pause')));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('orbit_rescue_pause')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('expert rescue separates route planning from execution', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: OrbitRescuePlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('ORBIT RESCUE'), findsOneWidget);
    expect(
      find.text('PLOT THE SLINGSHOT LINE BEFORE IGNITION'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('orbit_rescue_launch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('orbit_rescue_controls')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey<String>('orbit_rescue_launch')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('orbit_rescue_controls')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('orbit_rescue_impulse')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
