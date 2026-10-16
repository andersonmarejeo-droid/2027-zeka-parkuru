import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shogi_mate/shogi_mate_puzzle.dart';
import 'package:zeka_parkuru/games/shogi_mate/shogi_position.dart';

void main() {
  group('Shogi yasal hamle motoru', () {
    test('terfi alanına giren piyon zorunlu terfi eder', () {
      final List<ShogiPiece?> board = List<ShogiPiece?>.filled(81, null);
      board[ShogiSquare.index(8, 8)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(0, 8)] = ShogiPiece(
        ShogiSide.white,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(1, 4)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.pawn,
      );
      final ShogiPosition position = ShogiPosition(
        board: board,
        hands: const <ShogiSide, Map<ShogiPieceType, int>>{},
        toMove: ShogiSide.black,
      );
      final List<ShogiMove> promotions = position
          .legalMoves()
          .where((ShogiMove move) => move.from == ShogiSquare.index(1, 4))
          .toList();
      expect(promotions, <ShogiMove>[
        ShogiMove(
          from: ShogiSquare.index(1, 4),
          to: ShogiSquare.index(0, 4),
          promote: true,
        ),
      ]);
      expect(
        position.play(promotions.single)!.at(ShogiSquare.index(0, 4))!.promoted,
        isTrue,
      );
    });

    test('aynı dikey hatta iki terfi etmemiş piyon düşürülemez', () {
      final List<ShogiPiece?> board = List<ShogiPiece?>.filled(81, null);
      board[ShogiSquare.index(8, 8)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(0, 8)] = ShogiPiece(
        ShogiSide.white,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(5, 3)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.pawn,
      );
      final ShogiPosition position = ShogiPosition(
        board: board,
        hands: const <ShogiSide, Map<ShogiPieceType, int>>{
          ShogiSide.black: <ShogiPieceType, int>{ShogiPieceType.pawn: 1},
        },
        toMove: ShogiSide.black,
      );
      expect(
        position.legalMoves(),
        isNot(
          contains(
            ShogiMove(drop: ShogiPieceType.pawn, to: ShogiSquare.index(6, 3)),
          ),
        ),
      );
      expect(
        position.legalMoves(),
        contains(
          ShogiMove(drop: ShogiPieceType.pawn, to: ShogiSquare.index(6, 4)),
        ),
      );
    });

    test('yakalanan terfili taş base türüne döner ve ele alınır', () {
      final List<ShogiPiece?> board = List<ShogiPiece?>.filled(81, null);
      board[ShogiSquare.index(8, 8)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(0, 8)] = ShogiPiece(
        ShogiSide.white,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(3, 3)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.gold,
      );
      board[ShogiSquare.index(2, 3)] = ShogiPiece(
        ShogiSide.white,
        ShogiPieceType.pawn,
        promoted: true,
      );
      final ShogiPosition position = ShogiPosition(
        board: board,
        hands: const <ShogiSide, Map<ShogiPieceType, int>>{},
        toMove: ShogiSide.black,
      );
      final ShogiPosition after = position.play(
        ShogiMove(from: ShogiSquare.index(3, 3), to: ShogiSquare.index(2, 3)),
      )!;
      expect(after.at(ShogiSquare.index(2, 3))?.type, ShogiPieceType.gold);
      expect(after.hands[ShogiSide.black]?[ShogiPieceType.pawn], 1);
      expect(after.hands[ShogiSide.white]?[ShogiPieceType.pawn], isNull);
    });

    test('şahı açıkta bırakan bağlı taş hamlesi yasaklanır', () {
      final List<ShogiPiece?> board = List<ShogiPiece?>.filled(81, null);
      board[ShogiSquare.index(4, 4)] = ShogiPiece(
        ShogiSide.white,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(0, 8)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(4, 0)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.rook,
      );
      board[ShogiSquare.index(4, 2)] = ShogiPiece(
        ShogiSide.white,
        ShogiPieceType.gold,
      );
      final ShogiPosition position = ShogiPosition(
        board: board,
        hands: const <ShogiSide, Map<ShogiPieceType, int>>{},
        toMove: ShogiSide.white,
      );
      expect(position.isKingInCheck(ShogiSide.white), isFalse);
      expect(
        position.legalMoves(),
        isNot(
          contains(
            ShogiMove(
              from: ShogiSquare.index(4, 2),
              to: ShogiSquare.index(3, 2),
            ),
          ),
        ),
      );
    });

    test('piyon düşürerek yasak mat kurmaya izin verilmez', () {
      final List<ShogiPiece?> board = List<ShogiPiece?>.filled(81, null);
      board[ShogiSquare.index(0, 4)] = ShogiPiece(
        ShogiSide.white,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(2, 4)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(2, 3)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.rook,
      );
      board[ShogiSquare.index(2, 5)] = ShogiPiece(
        ShogiSide.black,
        ShogiPieceType.rook,
      );
      final ShogiPosition position = ShogiPosition(
        board: board,
        hands: const <ShogiSide, Map<ShogiPieceType, int>>{
          ShogiSide.black: <ShogiPieceType, int>{ShogiPieceType.pawn: 1},
        },
        toMove: ShogiSide.black,
      );
      expect(position.isKingInCheck(ShogiSide.black), isFalse);
      expect(
        position.legalMoves(),
        isNot(
          contains(
            ShogiMove(drop: ShogiPieceType.pawn, to: ShogiSquare.index(1, 4)),
          ),
        ),
      );
    });
  });

  group('Shogi Mat içerik sertifikası', () {
    test('20 farklı etütte tek yasal anlık mat ve el taşı bulunur', () {
      final List<ShogiMatePuzzle> puzzles = <ShogiMatePuzzle>[
        for (int level = 1; level <= ShogiMatePuzzle.maximumLevels; level++)
          ShogiMatePuzzle.forLevel(level),
      ];
      expect(
        puzzles.map((ShogiMatePuzzle puzzle) => puzzle.signature).toSet(),
        hasLength(20),
      );
      for (final ShogiMatePuzzle puzzle in puzzles) {
        expect(puzzle.position.handCount, 1);
        expect(puzzle.position.play(puzzle.solution)?.isCheckmate(), isTrue);
        final List<ShogiMove> mates = <ShogiMove>[
          for (final ShogiMove move in puzzle.position.legalMoves())
            if (puzzle.position.play(move)?.isCheckmate() ?? false) move,
        ];
        expect(mates, <ShogiMove>[puzzle.solution]);
      }
      expect(ShogiMatePuzzle.forLevel(7).supportPieces, greaterThan(0));
      expect(ShogiMatePuzzle.forLevel(9).difficultyTier, 'EXPERT');
      expect(ShogiMatePuzzle.forLevel(19).supportPieces, greaterThan(14));
    });

    test('ilk 300 tekrar etüdü kampanya ve kendi arasında tekrarsızdır', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= ShogiMatePuzzle.maximumLevels; level++)
          ShogiMatePuzzle.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= ShogiMatePuzzle.maximumVerifiedBoards;
        index++
      ) {
        final ShogiMatePuzzle puzzle = ShogiMatePuzzle.forPracticeBoard(index);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'Study $index',
        );
        expect(puzzle.position.play(puzzle.solution)?.isCheckmate(), isTrue);
        expect(puzzle.supportPieces, greaterThanOrEqualTo(2));
      }
      expect(signatures, hasLength(320));
      expect(() => ShogiMatePuzzle.forPracticeBoard(301), throwsRangeError);
    });
  });
}
