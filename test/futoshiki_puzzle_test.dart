import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/futoshiki/futoshiki_puzzle.dart';

void main() {
  group('Futoshiki content certificate', () {
    test('20 campaign boards are unique, legal and solver-certified', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= FutoshikiPuzzle.maximumLevels; level++) {
        final FutoshikiPuzzle puzzle = FutoshikiPuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(puzzle.solutionRespectsRules, isTrue, reason: 'level $level');
        expect(puzzle.isCertified, isTrue, reason: 'level $level');
        expect(
          puzzle.givenCount,
          FutoshikiPuzzle.minimumGivenCountForLevel(level),
        );
        expect(
          puzzle.horizontalAndVerticalRelations,
          FutoshikiPuzzle.targetRelationCountForLevel(level),
        );
      }
      expect(signatures, hasLength(20));
    });

    test('first 300 practice boards never repeat campaign or each other', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= FutoshikiPuzzle.maximumLevels; level++)
          FutoshikiPuzzle.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= FutoshikiPuzzle.maximumVerifiedBoards;
        index++
      ) {
        final FutoshikiPuzzle puzzle = FutoshikiPuzzle.forPracticeBoard(index);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'practice $index',
        );
        expect(puzzle.solutionRespectsRules, isTrue, reason: 'practice $index');
        expect(puzzle.certificationNodes, greaterThan(0));
      }
      expect(signatures, hasLength(320));
      expect(() => FutoshikiPuzzle.forPracticeBoard(301), throwsRangeError);
    });

    test('7–10 rise in board size, clue pressure and inequality density', () {
      final FutoshikiPuzzle six = FutoshikiPuzzle.forLevel(6);
      final FutoshikiPuzzle seven = FutoshikiPuzzle.forLevel(7);
      final FutoshikiPuzzle eight = FutoshikiPuzzle.forLevel(8);
      final FutoshikiPuzzle nine = FutoshikiPuzzle.forLevel(9);
      final FutoshikiPuzzle ten = FutoshikiPuzzle.forLevel(10);

      expect(seven.size, 5);
      expect(eight.size, 5);
      expect(nine.size, 6);
      expect(ten.size, 6);
      expect(seven.givenCount, lessThan(six.givenCount));
      expect(eight.givenCount, lessThan(seven.givenCount));
      expect(nine.givenCount, greaterThan(eight.givenCount));
      expect(ten.givenCount, lessThan(nine.givenCount));
      expect(
        eight.horizontalAndVerticalRelations,
        greaterThan(seven.horizontalAndVerticalRelations),
      );
      expect(
        ten.horizontalAndVerticalRelations,
        greaterThan(nine.horizontalAndVerticalRelations),
      );
      expect(seven.difficultyTier, 'ADVANCED');
      expect(eight.difficultyTier, 'ADVANCED');
      expect(nine.difficultyTier, 'EXPERT');
      expect(ten.difficultyTier, 'EXPERT');
    });

    test('solver rejects duplicate row givens and reversed inequalities', () {
      final FutoshikiSolveResult duplicate = FutoshikiPuzzle.countSolutions(
        size: 4,
        givens: <int?>[1, 1, null, null, ...List<int?>.filled(12, null)],
        relations: const <FutoshikiRelation>[],
      );
      expect(duplicate.solutionCount, 0);

      final FutoshikiSolveResult contradiction = FutoshikiPuzzle.countSolutions(
        size: 4,
        givens: <int?>[4, 1, null, null, ...List<int?>.filled(12, null)],
        relations: const <FutoshikiRelation>[
          FutoshikiRelation(lessCell: 0, greaterCell: 1),
        ],
      );
      expect(contradiction.solutionCount, 0);
    });
  });
}
