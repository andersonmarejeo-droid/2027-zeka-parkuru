import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/chess_mate/chess_mate_game_page.dart';
import 'package:zeka_parkuru/games/chess_mate/chess_mate_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Satranç Matı $number',
  titleEn: 'Chess Mate $number',
  subtitleTr: 'Tek hamlede mat',
  subtitleEn: 'Mate in one',
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
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('level hub opens without overflow on a compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const ChessMateGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Satranç Matı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'legal non-mate attempt gives feedback, then certified move wins',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _mount(
        tester,
        home: ChessMatePlayPage(level: _level(1), previousBestScore: 0),
        size: const Size(320, 600),
        locale: const Locale('tr'),
      );
      expect(
        find.byKey(const ValueKey<String>('chess_mate_board')),
        findsOneWidget,
      );

      final ChessMatePuzzle puzzle = ChessMatePuzzle.forLevel(1);
      final int whitePieceSquare = puzzle.position.board.indexWhere(
        (ChessPiece? piece) => piece?.side == ChessSide.white,
      );
      final Finder whitePiece = find.byKey(
        ValueKey<String>('piece-${ChessSquare.name(whitePieceSquare)}'),
      );
      expect(whitePiece, findsOneWidget);
      expect(tester.widget<CustomPaint>(whitePiece).painter, isNotNull);
      final List<ChessMove> wrongMoves = puzzle.position
          .legalMoves()
          .where((ChessMove move) => move != puzzle.solution)
          .toList(growable: false);
      if (wrongMoves.isNotEmpty) {
        final ChessMove wrongMove = wrongMoves.first;
        await tester.tap(
          find.byKey(
            ValueKey<String>(
              'chess-square-${ChessSquare.name(wrongMove.from)}',
            ),
          ),
        );
        await tester.tap(
          find.byKey(
            ValueKey<String>('chess-square-${ChessSquare.name(wrongMove.to)}'),
          ),
        );
        await tester.pump();
        expect(
          find.textContaining('Hamle yasal ama mat değil.'),
          findsOneWidget,
        );
      }

      await tester.tap(
        find.byKey(
          ValueKey<String>(
            'chess-square-${ChessSquare.name(puzzle.solution.from)}',
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          ValueKey<String>(
            'chess-square-${ChessSquare.name(puzzle.solution.to)}',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('ŞAH MAT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English chess hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const ChessMateGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Chess Mate'), findsOneWidget);
    expect(ChessMateGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
