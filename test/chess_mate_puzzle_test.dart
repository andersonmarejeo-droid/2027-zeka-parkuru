import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/chess_mate/chess_mate_puzzle.dart';

void main() {
  group('Satranç motoru', () {
    test('başlangıç konumunda 20 yasal açılış hamlesi üretir', () {
      final ChessPosition start = ChessPosition.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(start.isStructurallyLegal(), isTrue);
      expect(start.legalMoves(), hasLength(20));
      expect(start.placement, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR');
    });

    test('şah tehdidini engelleyen yasal hamleleri filtreler', () {
      final ChessPosition pin = ChessPosition.fromFen(
        '4r1k1/8/8/8/8/8/4R3/4K3 w - - 0 1',
      );
      expect(
        pin.legalMoves().where(
          (ChessMove move) => move.from == ChessSquare.parse('e2'),
        ),
        isNotEmpty,
      );
      expect(
        pin.legalMoves().where(
          (ChessMove move) => move.from == ChessSquare.parse('e1'),
        ),
        isNotEmpty,
      );
    });

    test('rok, geçerken alma ve terfi hamlelerini tanır', () {
      final ChessPosition castling = ChessPosition.fromFen(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      );
      expect(
        castling.legalMoves().map((ChessMove move) => move.uci),
        containsAll(<String>['e1g1', 'e1c1']),
      );

      final ChessPosition enPassant = ChessPosition.fromFen(
        '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
      );
      final ChessMove capture = enPassant.legalMoves().singleWhere(
        (ChessMove move) => move.uci == 'e5d6',
      );
      final ChessPosition afterCapture = enPassant.play(capture);
      expect(afterCapture.board[ChessSquare.parse('d5')!], isNull);

      final ChessPosition promotion = ChessPosition.fromFen(
        '4k3/P7/8/8/8/8/8/4K3 w - - 0 1',
      );
      expect(
        promotion.legalMoves().where(
          (ChessMove move) => move.from == ChessSquare.parse('a7'),
        ),
        hasLength(4),
      );
    });

    test('mate and stalemate are distinct terminal states', () {
      final ChessPosition mate = ChessPosition.fromFen(
        '7k/5KQ1/8/8/8/8/8/8 b - - 0 1',
      );
      expect(mate.inCheck(ChessSide.black), isTrue);
      expect(mate.isCheckmate(ChessSide.black), isTrue);

      final ChessPosition stalemate = ChessPosition.fromFen(
        '7k/5K2/6Q1/8/8/8/8/8 b - - 0 1',
      );
      expect(stalemate.inCheck(ChessSide.black), isFalse);
      expect(stalemate.isCheckmate(ChessSide.black), isFalse);
      expect(stalemate.legalMoves(side: ChessSide.black), isEmpty);
    });
  });

  group('Satranç Matı içerik sertifikası', () {
    test('20 seviye yapısal olarak yasal ve tam tek mat hamleli olur', () {
      final List<ChessMatePuzzle> puzzles = <ChessMatePuzzle>[
        for (int level = 1; level <= ChessMatePuzzle.maximumLevels; level++)
          ChessMatePuzzle.forLevel(level),
      ];
      expect(
        puzzles.map((ChessMatePuzzle puzzle) => puzzle.signature).toSet(),
        hasLength(ChessMatePuzzle.maximumLevels),
      );
      for (final ChessMatePuzzle puzzle in puzzles) {
        expect(
          puzzle.position.isStructurallyLegal(requireQuietStart: true),
          isTrue,
        );
        expect(
          puzzle.candidateMoveCount,
          greaterThanOrEqualTo(puzzle.minimumCandidateMoveCount),
          reason: 'Level ${puzzle.level} should present a genuine candidate search.',
        );
        final List<ChessMove> mates = <ChessMove>[
          for (final ChessMove move in puzzle.position.legalMoves())
            if (puzzle.position.play(move).isCheckmate(ChessSide.black)) move,
        ];
        expect(mates, <ChessMove>[puzzle.solution], reason: puzzle.signature);
      }
      expect(ChessMatePuzzle.forLevel(7).difficultyTier, 'ADVANCED');
      expect(ChessMatePuzzle.forLevel(9).difficultyTier, 'EXPERT');
      expect(ChessMatePuzzle.forLevel(17).difficultyTier, 'MASTER');
      expect(ChessMatePuzzle.forLevel(1).occupiedPieceCount, 3);
      expect(ChessMatePuzzle.forLevel(7).occupiedPieceCount, 4);
      expect(ChessMatePuzzle.forLevel(9).occupiedPieceCount, 5);
      expect(ChessMatePuzzle.forLevel(11).occupiedPieceCount, 6);
      expect(ChessMatePuzzle.forLevel(17).occupiedPieceCount, 7);
    });

    test('ilk 300 tekrar tahtası kampanyadan ve birbirinden farklıdır', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= ChessMatePuzzle.maximumLevels; level++)
          ChessMatePuzzle.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= ChessMatePuzzle.maximumVerifiedBoards;
        index++
      ) {
        final ChessMatePuzzle puzzle = ChessMatePuzzle.forPracticeBoard(index);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'Board $index',
        );
        expect(
          puzzle.position.isStructurallyLegal(requireQuietStart: true),
          isTrue,
        );
        expect(
          puzzle.candidateMoveCount,
          greaterThanOrEqualTo(puzzle.minimumCandidateMoveCount),
          reason: 'Practice board $index should preserve its search depth.',
        );
        expect(
          puzzle.position.play(puzzle.solution).isCheckmate(ChessSide.black),
          isTrue,
        );
      }
      expect(signatures, hasLength(320));
      expect(() => ChessMatePuzzle.forPracticeBoard(301), throwsRangeError);
    });
  });
}
