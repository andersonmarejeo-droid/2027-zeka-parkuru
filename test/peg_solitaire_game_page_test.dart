import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/peg_solitaire/peg_solitaire_game_page.dart';
import 'package:zeka_parkuru/games/peg_solitaire/peg_solitaire_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Tek Taş $number',
  titleEn: 'Peg Solitaire $number',
  subtitleTr: 'Tek taşa indir',
  subtitleEn: 'Reduce to one peg',
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

  testWidgets('20-level hub fits compact Turkish phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const PegSolitaireGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Tek Taş'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undo and the certified jump chain reach the gold goal', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final PegSolitairePuzzle puzzle = PegSolitairePuzzle.forLevel(1);
    await _mount(
      tester,
      home: PegSolitairePlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    final Finder board = find.byKey(
      const ValueKey<String>('peg_solitaire_board'),
    );
    expect(board, findsOneWidget);
    final double cell = tester.getSize(board).width / 7;

    Future<void> playMove(PegMove move) async {
      final Offset boardTopLeft = tester.getTopLeft(board);
      await tester.tapAt(
        boardTopLeft +
            Offset(
              (PegSquare.column(move.from) + .5) * cell,
              (PegSquare.row(move.from) + .5) * cell,
            ),
      );
      await tester.pump();
      await tester.tapAt(
        boardTopLeft +
            Offset(
              (PegSquare.column(move.to) + .5) * cell,
              (PegSquare.row(move.to) + .5) * cell,
            ),
      );
      await tester.pump();
    }

    await playMove(puzzle.solution.first);
    final Finder undo = find.text('Geri al');
    await tester.ensureVisible(undo);
    await tester.tap(undo);
    await tester.pump();
    for (final PegMove move in puzzle.solution) {
      await playMove(move);
    }
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('TEK TAŞ KALDI'), findsOneWidget);
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
      home: const PegSolitaireGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Peg Solitaire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
