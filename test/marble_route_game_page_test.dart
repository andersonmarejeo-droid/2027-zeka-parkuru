import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/marble_route/marble_route_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Mermer Parkur ${number.toString().padLeft(2, '0')}',
  titleEn: 'Marble Course ${number.toString().padLeft(2, '0')}',
  subtitleTr: 'Tahtayı kontrollü eğ',
  subtitleEn: 'Tilt the board with control',
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

  testWidgets('ten-level hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const MarbleRouteGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Mermer Rota'), findsOneWidget);
    expect(find.text('1. Mermer Parkur 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marble board and tilt controls fit and pause on phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: MarbleRoutePlayPage(level: _level(8), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    final Finder board = find.byKey(
      const ValueKey<String>('marble_route_board'),
    );
    final Finder pad = find.byKey(const ValueKey<String>('marble_route_tilt'));
    expect(board, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('marble_route_hud')),
      findsOneWidget,
    );
    expect(pad, findsOneWidget);
    await tester.drag(pad, const Offset(26, -18));
    await tester.pump(const Duration(milliseconds: 80));
    final Finder pause = find.byKey(
      const ValueKey<String>('marble_route_pause'),
    );
    await tester.tap(pause);
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(pause);
    await tester.pump();
    await tester.drag(board, const Offset(18, -70));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('English master course fits an 800-pixel tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: MarbleRoutePlayPage(level: _level(10), previousBestScore: 0),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(
      find.byKey(const ValueKey<String>('marble_route_board')),
      findsOneWidget,
    );
    expect(find.text('MARBLE ROUTE'), findsOneWidget);
    expect(find.text('FELT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
