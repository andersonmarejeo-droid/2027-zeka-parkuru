import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/hidden_masses/hidden_masses_puzzle.dart';

void main() {
  group('Hidden Masses campaign quality', () {
    test('20 levels are distinct, deterministic, and uniquely solvable', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= HiddenMassPuzzle.maximumLevels; level++) {
        final HiddenMassPuzzle puzzle = HiddenMassPuzzle.forLevel(level);
        final List<int>? solution = puzzle.solveUniqueMasses();

        expect(puzzle.level, level);
        expect(
          signatures.add(puzzle.boardSignature),
          isTrue,
          reason: 'level $level',
        );
        expect(solution, isNotNull, reason: 'level $level must be determined');
        expect(solution![puzzle.targetObjectIndex], puzzle.answerGrams);
        expect(puzzle.answerChoices, hasLength(5));
        expect(puzzle.answerChoices.toSet(), hasLength(5));
        expect(
          puzzle.answerChoices.where(
            (int value) => value == puzzle.answerGrams,
          ),
          hasLength(1),
        );
        expect(
          HiddenMassPuzzle.forLevel(level).boardSignature,
          puzzle.boardSignature,
        );
        expect(puzzle.equations, isNotEmpty);
        for (final MassEquation equation in puzzle.equations) {
          expect(equation.evaluate(solution), equation.grams);
          expect(
            equation.objectIndices.every(
              (int index) => index < puzzle.activeObjectCount,
            ),
            isTrue,
            reason: 'decoy objects must not leak into the equation key',
          );
        }
      }
    });

    test('expert ramp adds unknowns and chapter two adds a decoy', () {
      for (final int level in <int>[7, 8, 9, 10, 17, 18, 19, 20]) {
        expect(
          HiddenMassPuzzle.forLevel(level).difficultyTier,
          contains('EXPERT'),
        );
      }
      expect(
        HiddenMassPuzzle.forLevel(7).activeObjectCount,
        lessThan(HiddenMassPuzzle.forLevel(9).activeObjectCount),
      );
      expect(
        HiddenMassPuzzle.forLevel(17).activeObjectCount,
        HiddenMassPuzzle.forLevel(19).activeObjectCount,
      );
      expect(
        HiddenMassPuzzle.forLevel(19).equations.length,
        greaterThan(HiddenMassPuzzle.forLevel(18).equations.length),
      );
      for (int level = 11; level <= 20; level++) {
        final HiddenMassPuzzle puzzle = HiddenMassPuzzle.forLevel(level);
        expect(puzzle.chapter, 2);
        expect(puzzle.decoyCount, 1);
        expect(puzzle.objects.last.isDecoy, isTrue);
      }
    });

    test('equation rows support repeated weights for calibration clues', () {
      final HiddenMassPuzzle puzzle = HiddenMassPuzzle.forLevel(19);
      final MassEquation calibration = puzzle.equations.firstWhere(
        (MassEquation equation) => equation.objectIndices.length == 3,
      );
      expect(calibration.objectIndices.toSet().length, lessThan(3));
      expect(
        calibration.evaluate(puzzle.solveUniqueMasses()!),
        calibration.grams,
      );
    });
  });
}
