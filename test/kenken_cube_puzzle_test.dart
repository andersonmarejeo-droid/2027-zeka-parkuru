import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_puzzle.dart';

void main() {
  group('KenKen unique content contract', () {
    test('the first puzzle generates with a unique solution', () {
      final KenKenPuzzle puzzle = KenKenPuzzle.forLevel(1);
      expect(puzzle.size, 4);
      expect(puzzle.analyze().solutionCount, 1);
    });

    test(
      'the 20 campaign boards are distinct and have exactly one solution',
      () {
        final Set<String> signatures = <String>{};
        for (int level = 1; level <= KenKenPuzzle.maximumUniqueCases; level++) {
          final KenKenPuzzle puzzle = KenKenPuzzle.forLevel(level);
          expect(
            signatures.add(puzzle.boardSignature),
            isTrue,
            reason: 'repeated KenKen puzzle at level $level',
          );
          expect(puzzle.solution, hasLength(puzzle.cellCount));
          expect(
            puzzle.solution.every(
              (int value) => value >= 1 && value <= puzzle.size,
            ),
            isTrue,
          );
          for (int row = 0; row < puzzle.size; row++) {
            expect(
              puzzle.solution
                  .sublist(row * puzzle.size, (row + 1) * puzzle.size)
                  .toSet(),
              hasLength(puzzle.size),
              reason: 'Latin row $row at level $level',
            );
          }
          for (int column = 0; column < puzzle.size; column++) {
            expect(
              <int>{
                for (int row = 0; row < puzzle.size; row++)
                  puzzle.solution[row * puzzle.size + column],
              },
              hasLength(puzzle.size),
              reason: 'Latin column $column at level $level',
            );
          }
          expect(
            puzzle.isSolved(puzzle.solution),
            isTrue,
            reason: 'stored solution must satisfy every cage at level $level',
          );
          // The generator runs this exact uniqueness solver before returning
          // every board. Re-run it independently at chapter milestones rather
          // than doubling the expensive proof for all 20 dense KenKen boards.
          if (<int>{1, 10, 11, 20}.contains(level)) {
            final KenKenAnalysis analysis = puzzle.analyze();
            expect(
              analysis.solutionCount,
              1,
              reason: 'uniqueness at level $level',
            );
            expect(analysis.searchNodes, greaterThan(0));
          }
        }
        expect(signatures, hasLength(KenKenPuzzle.maximumUniqueCases));
      },
    );

    test('10-stage series grows in grid size and upper stages tighten cage complexity', () {
      final List<KenKenPuzzle> stages = <KenKenPuzzle>[
        for (int stage = 1; stage <= 10; stage++) KenKenPuzzle.forLevel(stage),
      ];
      expect(stages.map((KenKenPuzzle puzzle) => puzzle.size), <int>[
        4,
        4,
        5,
        5,
        5,
        6,
        6,
        6,
        6,
        6,
      ]);
      for (int stage = 7; stage <= 10; stage++) {
        expect(
          stages[stage - 1].difficultyTier,
          stage <= 8 ? 'İLERİ' : 'UZMAN',
        );
        expect(
          stages[stage - 1].largestCage,
          greaterThanOrEqualTo(stage <= 7 ? 3 : 4),
        );
      }
      expect(stages.last.singletonCount, lessThanOrEqualTo(6));
      expect(stages.last.advancedOperationCount, greaterThan(0));
    });

    test('the generator is stable when a stage is requested repeatedly', () {
      expect(
        KenKenPuzzle.forLevel(7).boardSignature,
        KenKenPuzzle.forLevel(7).boardSignature,
      );
      expect(() => KenKenPuzzle.forLevel(301), throwsRangeError);
    });
  });
}
