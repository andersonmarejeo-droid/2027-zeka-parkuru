import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/hitori/hitori_puzzle.dart';

void main() {
  group('Hitori content certification', () {
    test('all twenty campaign boards are distinct, unique and progressive', () {
      final Set<String> signatures = <String>{};
      var previousSize = 0;
      for (int level = 1; level <= HitoriPuzzle.maximumLevels; level++) {
        final HitoriPuzzle puzzle = HitoriPuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(puzzle.size, greaterThanOrEqualTo(previousSize));
        expect(puzzle.size, HitoriPuzzle.sizeForLevel(level));
        expect(
          puzzle.blackCount,
          greaterThanOrEqualTo(HitoriPuzzle.minimumBlackCellsForLevel(level)),
        );
        expect(
          puzzle.hasUniqueCertifiedSolution,
          isTrue,
          reason: 'level $level',
        );
        expect(
          puzzle.isSolved(puzzle.solution),
          isTrue,
          reason: 'level $level',
        );
        previousSize = puzzle.size;
      }
    });

    for (int batch = 0; batch < 12; batch++) {
      final int start = batch * 25 + 1;
      final int end = start + 24;
      test('practice boards $start–$end are unique and certified', () {
        final Set<String> signatures = <String>{
          for (int level = 1; level <= HitoriPuzzle.maximumLevels; level++)
            HitoriPuzzle.forLevel(level).signature,
          for (int index = 1; index < start; index++)
            HitoriPuzzle.forPracticeBoard(index).signature,
        };
        for (int index = start; index <= end; index++) {
          final HitoriPuzzle puzzle = HitoriPuzzle.forPracticeBoard(index);
          expect(
            signatures.add(puzzle.signature),
            isTrue,
            reason: 'board $index',
          );
          expect(
            puzzle.hasUniqueCertifiedSolution,
            isTrue,
            reason: 'board $index',
          );
          expect(
            puzzle.isSolved(puzzle.solution),
            isTrue,
            reason: 'board $index',
          );
        }
      });
    }

    test('solver honors line duplicates, orthogonal spacing and white connectivity', () {
      final List<int> values = List<int>.generate(16, (int index) => index + 1);
      final HitoriSolveResult solved = HitoriPuzzle.countSolutions(
        size: 4,
        values: values,
      );
      expect(solved.solutionCount, 1);
      expect(solved.firstSolution, List<bool>.filled(16, false));

      final List<int> onePair = List<int>.generate(16, (int index) => index + 1)
        ..[1] = 1;
      expect(
        HitoriPuzzle.countSolutions(size: 4, values: onePair).solutionCount,
        2,
      );

      expect(
        () => HitoriPuzzle.countSolutions(size: 4, values: <int>[1, 2]),
        throwsArgumentError,
      );
    });

    test('overlapping row and column repeats certify a single solution', () {
      const List<int> values = <int>[
        4,
        2,
        3,
        2,
        5,
        2,
        2,
        1,
        4,
        3,
        3,
        3,
        4,
        1,
        4,
        1,
        4,
        4,
        3,
        2,
        5,
        1,
        2,
        5,
        3,
      ];
      final HitoriSolveResult result = HitoriPuzzle.countSolutions(
        size: 5,
        values: values,
      );
      expect(result.solutionCount, 1);
      expect(result.firstSolution, <bool>[
        for (int cell = 0; cell < 25; cell++)
          <int>{3, 6, 10, 14, 17, 20, 24}.contains(cell),
      ]);
    });
  });
}
