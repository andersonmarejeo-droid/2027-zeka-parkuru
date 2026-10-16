import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/island_sea/island_sea_game_page.dart';
import 'package:zeka_parkuru/games/island_sea/island_sea_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Ada ve Deniz $number',
  titleEn: 'Island & Sea $number',
  subtitleTr: 'Adaları tamamla',
  subtitleEn: 'Complete the islands',
  difficulty: 'USTALAŞMA',
  icon: Icons.waves_rounded,
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

  testWidgets('20-level hub fits compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const IslandSeaGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Ada ve Deniz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marked cells undo and the certified map completes on phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final IslandSeaPuzzle puzzle = IslandSeaPuzzle.forLevel(1);
    await _mount(
      tester,
      home: IslandSeaPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    final Finder board = find.byKey(const ValueKey<String>('island_sea_board'));
    expect(board, findsOneWidget);
    final Size boardSize = tester.getSize(board);
    final double cellSize = boardSize.width / puzzle.size;

    final int firstOpenCell = puzzle.clues.indexWhere((int clue) => clue == 0);
    final int firstAnswer = puzzle.solution[firstOpenCell];
    final int incorrectMark = firstAnswer == IslandSeaPuzzle.island
        ? IslandSeaPuzzle.sea
        : IslandSeaPuzzle.island;
    await tester.tap(
      find.byKey(
        ValueKey<String>(
          incorrectMark == IslandSeaPuzzle.island
              ? 'island_sea_tool_island'
              : 'island_sea_tool_sea',
        ),
      ),
    );
    await tester.tapAt(
      tester.getTopLeft(board) +
          Offset(
            (firstOpenCell % puzzle.size + .5) * cellSize,
            (firstOpenCell ~/ puzzle.size + .5) * cellSize,
          ),
    );
    await tester.pump();
    final Finder undo = find.text('Geri al');
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pump();
    expect(find.text('Son hücre işareti geri alındı.'), findsOneWidget);
    await tester.ensureVisible(board);

    int? activeTool;
    for (int index = 0; index < puzzle.cellCount; index++) {
      if (puzzle.clues[index] > 0) continue;
      final int answer = puzzle.solution[index];
      if (activeTool != answer) {
        await tester.tap(
          find.byKey(
            ValueKey<String>(
              answer == IslandSeaPuzzle.island
                  ? 'island_sea_tool_island'
                  : 'island_sea_tool_sea',
            ),
          ),
        );
        await tester.pump();
        activeTool = answer;
      }
      await tester.tapAt(
        tester.getTopLeft(board) +
            Offset(
              (index % puzzle.size + .5) * cellSize,
              (index ~/ puzzle.size + .5) * cellSize,
            ),
      );
      await tester.pump();
    }
    final Finder check = find.byKey(const ValueKey<String>('island_sea_check'));
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('DENİZ AÇILDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const IslandSeaGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Island & Sea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
