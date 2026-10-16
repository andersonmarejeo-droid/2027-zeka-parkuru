import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/paper_flight/paper_flight_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Süzülüş Rotası ${number.toString().padLeft(2, '0')}',
  titleEn: 'Glide Route ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Kapılardan geç ve piste in',
  subtitleEn: 'Pass the hoops and land',
  difficulty: number >= 9 ? 'UZMAN' : 'USTALAŞMA',
  icon: Icons.airplanemode_active_rounded,
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

  testWidgets('ten-level hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const PaperFlightGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Kâğıt Uçak Şampiyonası'), findsOneWidget);
    expect(find.text('1. Süzülüş Rotası 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flight scene, pitch/bank controls and pause fit on phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: PaperFlightPlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('paper_flight_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('paper_flight_hud')),
      findsOneWidget,
    );
    final Finder controls = find.byKey(
      const ValueKey<String>('paper_flight_controls'),
    );
    expect(controls, findsOneWidget);
    await tester.drag(controls, const Offset(18, -14));
    await tester.pump(const Duration(milliseconds: 70));
    final Finder pause = find.byKey(
      const ValueKey<String>('paper_flight_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master flight fits an 800-pixel tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: PaperFlightPlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('paper_flight_scene')),
      findsOneWidget,
    );
    expect(find.text('PAPER FLIGHT'), findsOneWidget);
    expect(find.text('ALTITUDE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
