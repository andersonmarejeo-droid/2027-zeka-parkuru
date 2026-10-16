import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/peg_solitaire/peg_solitaire_puzzle.dart';

void main() {
  group('Peg Solitaire reverse certificate', () {
    test('each campaign puzzle has a legal path to the marked center', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= PegSolitairePuzzle.maximumLevels; level++) {
        final PegSolitairePuzzle puzzle = PegSolitairePuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(
          puzzle.start.pegCount,
          PegSolitairePuzzle.targetPegsForLevel(level),
        );
        expect(puzzle.solution, hasLength(puzzle.start.pegCount - 1));
        expect(puzzle.isCertified, isTrue, reason: 'level $level');
        final List<PegSolitairePosition> states = puzzle.certifiedStates;
        for (int step = 1; step < states.length; step++) {
          expect(states[step].pegCount, states[step - 1].pegCount - 1);
        }
        expect(states.last.isWon(puzzle.goal), isTrue);
      }
      expect(signatures, hasLength(20));
    });

    test(
      'first 300 practice boards are distinct from campaign and each other',
      () {
        final Set<String> signatures = <String>{
          for (
            int level = 1;
            level <= PegSolitairePuzzle.maximumLevels;
            level++
          )
            PegSolitairePuzzle.forLevel(level).signature,
        };
        for (
          int index = 1;
          index <= PegSolitairePuzzle.maximumVerifiedBoards;
          index++
        ) {
          final PegSolitairePuzzle puzzle = PegSolitairePuzzle.forPracticeBoard(
            index,
          );
          expect(
            signatures.add(puzzle.signature),
            isTrue,
            reason: 'practice $index',
          );
          expect(puzzle.isCertified, isTrue, reason: 'practice $index');
        }
        expect(signatures, hasLength(320));
        expect(
          () => PegSolitairePuzzle.forPracticeBoard(301),
          throwsRangeError,
        );
      },
    );

    test('only classic English-board holes accept pegs and moves', () {
      expect(PegSolitairePosition.holes, hasLength(33));
      expect(PegSolitairePosition.isBoardHole(PegSquare.index(0, 0)), isFalse);
      expect(PegSolitairePosition.isBoardHole(PegSquare.index(0, 3)), isTrue);
      final List<bool> pegs = List<bool>.filled(49, false);
      pegs[PegSolitairePosition.center] = true;
      final PegSolitairePosition position = PegSolitairePosition(pegs: pegs);
      expect(position.legalMoves(), isEmpty);
      expect(
        () => PegSolitairePosition(pegs: <bool>[...pegs]..[0] = true),
        throwsArgumentError,
      );
    });
  });
}
