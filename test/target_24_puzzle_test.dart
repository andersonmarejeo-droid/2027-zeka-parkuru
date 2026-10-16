import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/target_24/target_24_puzzle.dart';

void main() {
  group('Target 24 content quality', () {
    test(
      '300 deals are deterministic, unique and have one exact expression',
      () {
        final Set<String> signatures = <String>{};
        for (
          int level = 1;
          level <= Target24Puzzle.maximumUniqueCases;
          level++
        ) {
          final Target24Puzzle puzzle = Target24Puzzle.forLevel(level);
          expect(
            signatures.add(puzzle.boardSignature),
            isTrue,
            reason: 'repeated deal at level $level',
          );
          expect(
            puzzle.cards.map((Target24Card card) => card.value).toSet(),
            hasLength(4),
          );
          expect(
            puzzle.solve(),
            hasLength(1),
            reason: 'level $level must have one expression',
          );
          expect(
            puzzle.isSolved(puzzle.solution),
            isTrue,
            reason: 'level $level expression must use every card once',
          );
          expect(puzzle.solutionSteps, hasLength(3));
          expect(
            Target24Puzzle.forLevel(level).boardSignature,
            puzzle.boardSignature,
          );
        }
      },
    );

    test(
      '10-stage packs grow the card range into advanced and expert play',
      () {
        for (int stage = 1; stage <= 10; stage++) {
          expect(Target24Puzzle.stageForLevel(stage), stage);
          expect(
            Target24Puzzle.forLevel(stage).maximumCardValue,
            Target24Puzzle.maximumForStage(stage),
          );
        }
        expect(Target24Puzzle.forLevel(7).difficultyTier, 'ADVANCED');
        expect(Target24Puzzle.forLevel(8).difficultyTier, 'ADVANCED');
        expect(Target24Puzzle.forLevel(9).difficultyTier, 'EXPERT');
        expect(Target24Puzzle.forLevel(10).difficultyTier, 'EXPERT');
      },
    );

    test(
      'rational arithmetic reduces fractions and rejects division by zero',
      () {
        expect(Target24Rational(12, 8), Target24Rational(3, 2));
        expect(
          Target24Rational(
            3,
            2,
          ).apply(Target24Operator.multiply, Target24Rational(4)),
          Target24Rational(6),
        );
        expect(
          () =>
              Target24Rational(2)
                  .apply(Target24Operator.divide, Target24Rational.zero),
          throwsArgumentError,
        );
      },
    );
  });
}
