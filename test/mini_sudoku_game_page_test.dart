import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_game_page.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('compact phone can complete a standalone 6×6 Sudoku', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MiniSudokuPlayPage(level: _level(1), previousBestScore: 0),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final MiniSudokuPuzzle puzzle = MiniSudokuPuzzle.forLevel(1);
    for (int index = 0; index < puzzle.givens.length; index++) {
      if (puzzle.givens[index] != 0) continue;
      final Finder cell = find.byKey(
        ValueKey<String>('mini_sudoku_cell_$index'),
      );
      await tester.scrollUntilVisible(
        cell,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pump();

      final Finder digit = find.byKey(
        ValueKey<String>('mini_sudoku_num_${puzzle.solution[index]}'),
      );
      await tester.scrollUntilVisible(
        digit,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(digit);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    final Finder check = find.byKey(
      const ValueKey<String>('mini_sudoku_check'),
    );
    await tester.scrollUntilVisible(
      check,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(find.text('SUDOKU TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes are entered with a separate mode and can be undone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MiniSudokuPlayPage(level: _level(1), previousBestScore: 0),
      ),
    );
    await tester.pump();

    final MiniSudokuPuzzle puzzle = MiniSudokuPuzzle.forLevel(1);
    final int blankIndex = puzzle.givens.indexWhere((int value) => value == 0);
    final int note = puzzle.candidatesFor(puzzle.givens, blankIndex).first;
    final Finder cell = find.byKey(
      ValueKey<String>('mini_sudoku_cell_$blankIndex'),
    );
    await tester.tap(cell);
    await tester.tap(find.byKey(const ValueKey<String>('mini_sudoku_notes')));
    await tester.tap(find.byKey(ValueKey<String>('mini_sudoku_num_$note')));
    await tester.pump();

    expect(
      find.descendant(of: cell, matching: find.text('$note')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('mini_sudoku_undo')));
    await tester.pump();
    expect(
      find.descendant(of: cell, matching: find.text('$note')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet exposes the separate 6×6 game hub', (
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
        home: MiniSudokuGamePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Mini Sudoku 6×6'), findsOneWidget);
    expect(find.textContaining('Sudoku 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Sudoku ${number.toString().padLeft(3, '0')}',
  titleEn: 'Sudoku ${number.toString().padLeft(3, '0')}',
  subtitleTr: '6×6 mantık tablosu',
  subtitleEn: '6×6 logic grid',
  difficulty: 'BAŞLANGIÇ',
  icon: Icons.grid_on_rounded,
);
