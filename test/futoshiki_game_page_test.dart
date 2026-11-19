import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/futoshiki/futoshiki_game_page.dart';
import 'package:zeka_parkuru/games/futoshiki/futoshiki_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Futoshiki $number',
  titleEn: 'Futoshiki $number',
  subtitleTr: 'Sayıları ve işaretleri çöz',
  subtitleEn: 'Solve the values and signs',
  difficulty: 'USTALAŞMA',
  icon: Icons.grid_4x4_rounded,
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

  testWidgets('20-level hub fits a compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const FutoshikiGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Futoshiki'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('certified grid accepts values, supports undo and completes', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final FutoshikiPuzzle puzzle = FutoshikiPuzzle.forLevel(1);
    await _mount(
      tester,
      home: FutoshikiPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    final List<int> blankCells = <int>[
      for (int cell = 0; cell < puzzle.givens.length; cell++)
        if (puzzle.givens[cell] == null) cell,
    ];
    final int first = blankCells.firstWhere((int cell) {
      final int rowStart = cell ~/ puzzle.size * puzzle.size;
      return puzzle.givens
          .skip(rowStart)
          .take(puzzle.size)
          .whereType<int>()
          .isNotEmpty;
    });
    final int row = first ~/ puzzle.size;
    final int duplicate = puzzle.givens
        .skip(row * puzzle.size)
        .take(puzzle.size)
        .whereType<int>()
        .first;

    Future<void> enter(int cell, int value) async {
      final Finder targetCell = find.byKey(
        ValueKey<String>('futoshiki_cell_$cell'),
      );
      await tester.ensureVisible(targetCell);
      await tester.tap(targetCell);
      await tester.pump();
      final Finder digit = find.byKey(
        ValueKey<String>('futoshiki_digit_$value'),
      );
      await tester.ensureVisible(digit);
      await tester.tap(digit);
      await tester.pump();
    }

    for (final int cell in blankCells.where((int cell) => cell != first)) {
      await enter(cell, puzzle.solution[cell]);
    }
    await enter(first, duplicate);
    final Finder check = find.byKey(const ValueKey<String>('futoshiki_check'));
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump();
    expect(
      find.text('Vurgulanan satır, sütun veya eşitsizlik çakışmasını düzelt.'),
      findsOneWidget,
    );

    final Finder undo = find.byKey(const ValueKey<String>('futoshiki_undo'));
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pump();
    await enter(first, puzzle.solution[first]);
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pump(const Duration(milliseconds: 240));
    await tester.pumpAndSettle();
    expect(find.text('EŞİTSİZLİKLER ÇÖZÜLDÜ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'board size remains stable and does not shrink on cell selection or entry',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _mount(
        tester,
        home: FutoshikiPlayPage(level: _level(1), previousBestScore: 0),
        size: const Size(360, 780),
        locale: const Locale('tr'),
      );

      final Finder boardFinder = find.byKey(
        const ValueKey<String>('futoshiki_board_frame'),
      );
      expect(boardFinder, findsOneWidget);
      final Size initialSize = tester.getSize(boardFinder);

      // Hücre seçimi yapıldığında tahta boyutu küçülmemeli
      final Finder cellFinder = find.byKey(
        const ValueKey<String>('futoshiki_cell_0'),
      );
      await tester.tap(cellFinder);
      await tester.pump();

      final Size selectedSize = tester.getSize(boardFinder);
      expect(selectedSize.height, equals(initialSize.height));
      expect(selectedSize.width, equals(initialSize.width));

      // Sayı yerleştirildiğinde tahta boyutu yine sabit ve büyük kalmalı
      final Finder digitFinder = find.byKey(
        const ValueKey<String>('futoshiki_digit_1'),
      );
      await tester.tap(digitFinder);
      await tester.pump();

      final Size placedSize = tester.getSize(boardFinder);
      expect(placedSize.height, equals(initialSize.height));
      expect(placedSize.width, equals(initialSize.width));
    },
  );

  testWidgets('English hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const FutoshikiGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Futoshiki'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
