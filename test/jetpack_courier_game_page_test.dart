import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/jetpack_courier/jetpack_courier_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Kurye Rotası ${number.toString().padLeft(2, '0')}',
  titleEn: 'Delivery Route ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Gazı ayarla ve paketi koru',
  subtitleEn: 'Modulate thrust and protect cargo',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.rocket_launch_rounded,
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

  testWidgets('ten-level courier hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const JetpackCourierGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Jetpack Kurye'), findsOneWidget);
    expect(find.text('1. Kurye Rotası 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flight scene, dual-axis pad and pause fit the phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: JetpackCourierPlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('jetpack_courier_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('jetpack_courier_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('jetpack_courier_stick')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('jetpack_courier_pause')),
    );
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('jetpack_courier_pause')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert delivery fits an 800x1280 tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: JetpackCourierPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('jetpack_courier_scene')),
      findsOneWidget,
    );
    expect(find.text('JETPACK COURIER'), findsOneWidget);
    expect(find.text('STEER'), findsOneWidget);
    expect(find.text('THRUST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
