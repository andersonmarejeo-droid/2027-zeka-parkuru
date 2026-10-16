import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/balance_scale/balance_scale_puzzle.dart';

void main() {
  group('Balance Scale content quality', () {
    test('300 cases are deterministic, unique and solver-verified', () {
      final Set<String> signatures = <String>{};
      for (
        int level = 1;
        level <= BalanceScalePuzzle.maximumUniqueCases;
        level++
      ) {
        final BalanceScalePuzzle puzzle = BalanceScalePuzzle.forLevel(level);
        expect(puzzle.boardSignature, isNotEmpty, reason: 'level $level');
        expect(
          signatures.add(puzzle.boardSignature),
          isTrue,
          reason: 'repeated board at level $level',
        );
        expect(
          puzzle.weights.map((BalanceWeight weight) => weight.mass).toSet(),
          hasLength(puzzle.weights.length),
        );
        expect(
          puzzle.isSolved(puzzle.solution),
          isTrue,
          reason: 'invalid answer at level $level',
        );
        expect(
          puzzle.solve(),
          hasLength(1),
          reason: 'level $level must have exactly one solution',
        );
        expect(
          BalanceScalePuzzle.forLevel(level).boardSignature,
          puzzle.boardSignature,
        );
      }
    });

    test(
      '10-stage chapters increase scale count and reserve expert endgame',
      () {
        for (int stage = 1; stage <= 10; stage++) {
          expect(BalanceScalePuzzle.stageForLevel(stage), stage);
          expect(
            BalanceScalePuzzle.forLevel(stage).stationCount,
            BalanceScalePuzzle.stationCountForStage(stage),
          );
        }
        expect(BalanceScalePuzzle.forLevel(7).difficultyTier, 'ADVANCED');
        expect(BalanceScalePuzzle.forLevel(8).difficultyTier, 'ADVANCED');
        expect(BalanceScalePuzzle.forLevel(9).difficultyTier, 'EXPERT');
        expect(BalanceScalePuzzle.forLevel(10).difficultyTier, 'EXPERT');
        expect(BalanceScalePuzzle.forLevel(10).stationCount, 7);
      },
    );

    test('invalid placements cannot reuse or omit a weight', () {
      final BalanceScalePuzzle puzzle = BalanceScalePuzzle.forLevel(1);
      final List<BalancePlacement> duplicate = List<BalancePlacement>.from(
        puzzle.solution,
      );
      duplicate[0] = BalancePlacement(
        leftWeight: duplicate[1].leftWeight,
        rightWeight: duplicate[0].rightWeight,
      );
      expect(puzzle.isSolved(duplicate), isFalse);
    });
  });
}
