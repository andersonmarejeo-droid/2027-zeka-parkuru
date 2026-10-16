import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/arrow_route/arrow_game_page.dart';
import 'package:zeka_parkuru/games/arrow_route/arrow_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Ok Rotası $number',
  titleEn: 'Arrow Route $number',
  subtitleTr: 'Şeritleri tara',
  subtitleEn: 'Scan the lanes',
  difficulty: 'USTALAŞMA',
  icon: Icons.near_me_outlined,
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
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('level hub opens cleanly on a compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const ArrowRouteGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Ok Rotası'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320×600 board can clear its certified first route', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: ArrowRoutePlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(
      find.byKey(const ValueKey<String>('arrow_route_board')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final ArrowPuzzle puzzle = ArrowPuzzle.forLevel(1);
    for (final int id in puzzle.solutionIds) {
      final Finder arrow = find.byKey(ValueKey<String>('arrow-tile-$id'));
      await tester.ensureVisible(arrow);
      await tester.tap(arrow);
      await tester.pump(const Duration(milliseconds: 230));
    }
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('ROTA TEMİZLENDİ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English expert map and board remain stable on a tablet', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const ArrowRouteGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Arrow Route'), findsOneWidget);
    expect(ArrowRouteGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
