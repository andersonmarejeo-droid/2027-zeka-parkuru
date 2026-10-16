import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/shogi_mate/shogi_mate_game_page.dart';
import 'package:zeka_parkuru/games/shogi_mate/shogi_mate_puzzle.dart';
import 'package:zeka_parkuru/games/shogi_mate/shogi_position.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Shogi Mat $number',
  titleEn: 'Shogi Mate $number',
  subtitleTr: 'Tek hamlede mat',
  subtitleEn: 'Mate in one',
  difficulty: 'USTA',
  icon: Icons.grid_on_rounded,
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
      home: const ShogiMateGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Shogi Mat'), findsOneWidget);
    expect(ShogiMateGamePage.totalCases, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hand drop can solve the certified mate on compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final ShogiMatePuzzle puzzle = ShogiMatePuzzle.forLevel(1);
    await _mount(
      tester,
      home: ShogiMatePlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    final Finder hand = find.byKey(const ValueKey<String>('shogi_gold_hand'));
    final Finder board = find.byKey(const ValueKey<String>('shogi_mate_board'));
    expect(hand, findsOneWidget);
    expect(board, findsOneWidget);

    await tester.tap(hand);
    await tester.pump();
    final Size boardSize = tester.getSize(board);
    final Offset boardCenter = tester.getCenter(board);
    final double spacing = boardSize.width / 10;
    final int row = ShogiSquare.row(puzzle.solution.to);
    final int column = ShogiSquare.column(puzzle.solution.to);
    final bool rotated = puzzle.position.toMove == ShogiSide.white;
    final int viewRow = rotated ? 8 - row : row;
    final int viewColumn = rotated ? 8 - column : column;
    await tester.tapAt(
      boardCenter + Offset((viewColumn - 4) * spacing, (viewRow - 4) * spacing),
    );
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('SHOGI MAT'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English hub fits tablet viewport', (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const ShogiMateGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Shogi Mate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
