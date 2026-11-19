import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/target_24/target_24_puzzle.dart';

void main() {
  group('Target 24 / Bir Islem content quality', () {
    test(
      '300 deals are deterministic, unique and have guaranteed whole-number solutions',
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
            puzzle.solve().isNotEmpty,
            isTrue,
            reason: 'level $level must have at least one solution',
          );
          expect(
            puzzle.isSolved(puzzle.solution),
            isTrue,
            reason: 'level $level expression must use every card once',
          );
          expect(puzzle.solutionSteps, hasLength(3));
          for (final Target24Step step in puzzle.solutionSteps) {
            expect(step.result.isInteger, isTrue);
          }
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
      'integer arithmetic rejects division by zero, non-exact division, and negative results',
      () {
        expect(
          Target24Rational(12).apply(
            Target24Operator.divide,
            Target24Rational(3),
          ),
          Target24Rational(4),
        );
        expect(
          Target24Rational(6).apply(
            Target24Operator.multiply,
            Target24Rational(4),
          ),
          Target24Rational(24),
        );
        expect(
          Target24Rational(15).apply(
            Target24Operator.subtract,
            Target24Rational(8),
          ),
          Target24Rational(7),
        );
        // Non-exact division must throw
        expect(
          () => Target24Rational(10).apply(
            Target24Operator.divide,
            Target24Rational(3),
          ),
          throwsArgumentError,
        );
        // Division by zero must throw
        expect(
          () => Target24Rational(2).apply(
            Target24Operator.divide,
            Target24Rational.zero,
          ),
          throwsArgumentError,
        );
        // Subtraction smaller - larger must throw
        expect(
          () => Target24Rational(4).apply(
            Target24Operator.subtract,
            Target24Rational(7),
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
