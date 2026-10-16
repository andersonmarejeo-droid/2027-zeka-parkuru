import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/go_life_death/go_life_death_game_page.dart';
import 'package:zeka_parkuru/games/go_life_death/go_life_death_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Go Yaşam-Ölüm $number',
  titleEn: 'Go Life & Death $number',
  subtitleTr: 'Grubu kurtar veya yakala',
  subtitleEn: 'Save or capture the group',
  difficulty: 'USTALAŞMA',
  icon: Icons.circle_outlined,
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

  testWidgets('Go hub opens on a compact phone', (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const GoLifeDeathGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Go Yaşam-Ölüm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('certified capture or rescue completes through shared result', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: GoLifeDeathPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(360, 740),
      locale: const Locale('tr'),
    );
    final Finder board = find.byKey(
      const ValueKey<String>('go_life_death_board'),
    );
    expect(board, findsOneWidget);
    final GoLifeDeathPuzzle puzzle = GoLifeDeathPuzzle.forLevel(1);
    final Size boardSize = tester.getSize(board);
    final double spacing = boardSize.width / (puzzle.position.size + 1);
    final int row = puzzle.solutionPoint ~/ puzzle.position.size;
    final int column = puzzle.solutionPoint % puzzle.position.size;
    await tester.tapAt(
      tester.getTopLeft(board) +
          Offset((column + 1) * spacing, (row + 1) * spacing),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.text(
        puzzle.goal == GoPuzzleGoal.capture
            ? 'GRUP YAKALANDI'
            : 'GRUP KURTULDU',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English Go hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const GoLifeDeathGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Go Life & Death'), findsOneWidget);
    expect(GoLifeDeathGamePage.totalCases, 20);
    expect(tester.takeException(), isNull);
  });
}
