import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/letter_maze/letter_maze_game_page.dart';
import 'package:zeka_parkuru/games/letter_maze/letter_maze_scenario.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish route is playable without overflow', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    const ParkurLevelSpec firstLevel = ParkurLevelSpec(
      number: 1,
      titleTr: 'Rota 01',
      titleEn: 'Route 01',
      subtitleTr: 'Girişten başla',
      subtitleEn: 'Start at the entrance',
      difficulty: 'USTALAŞMA',
      icon: Icons.route_rounded,
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LetterMazePlayPage(level: firstLevel, previousBestScore: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Harf Labirenti'), findsOneWidget);
    expect(find.textContaining('KÖK KAPISI'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final LetterMazeScenario board = LetterMazeScenario.forCampaignLevel(1);
    for (final int index in board.solutionPath) {
      final Finder tile = find.byKey(
        ValueKey<String>('letter_maze_tile_$index'),
      );
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump();
    }

    final Finder submit = find.byKey(
      const ValueKey<String>('letter_maze_submit'),
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('letter_maze_result')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub exposes the expert finale', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LetterMazeGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Letter Maze'), findsOneWidget);
    final Finder finalLevel = find.textContaining('Route 20');
    await tester.scrollUntilVisible(
      finalLevel,
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(finalLevel, findsOneWidget);
    expect(LetterMazeGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
