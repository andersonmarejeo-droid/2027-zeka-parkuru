import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/island_sea/island_sea_puzzle.dart';

void main() {
  group('Ada ve Deniz kural modeli', () {
    test('serpentine construction has a unique interpretation', () {
      const int size = 5;
      final List<int> clues = List<int>.filled(size * size, 0);
      for (final int row in <int>[0, 2, 4]) {
        clues[row * size] = 2;
        clues[row * size + 3] = 2;
      }
      final IslandSeaAnalysis analysis = IslandSeaPuzzle.analyzePuzzle(
        size: size,
        clues: clues,
      );
      expect(analysis.complete, isTrue);
      expect(analysis.solutionCount, 1);
    });

    test('solver independently certifies the generated first board', () {
      final IslandSeaPuzzle puzzle = IslandSeaPuzzle.forLevel(1);
      final IslandSeaAnalysis analysis = puzzle.analyze();
      expect(analysis.complete, isTrue);
      expect(analysis.solutionCount, 1);
      expect(analysis.solution, puzzle.solution);
      expect(puzzle.isSolved(puzzle.solution), isTrue);
      expect(puzzle.landCount, greaterThan(0));
      expect(puzzle.seaCount, greaterThan(0));
      expect(puzzle.searchNodes, greaterThan(0));
    });

    test('20 campaign and 300 practice maps are unique and certified', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= IslandSeaPuzzle.maximumLevels; level++) {
        final IslandSeaPuzzle puzzle = IslandSeaPuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(
          puzzle.isSolved(puzzle.solution),
          isTrue,
          reason: 'level $level',
        );
        expect(puzzle.searchNodes, greaterThan(0), reason: 'level $level');
      }
      for (
        int index = 1;
        index <= IslandSeaPuzzle.maximumVerifiedBoards;
        index++
      ) {
        final IslandSeaPuzzle puzzle = IslandSeaPuzzle.forPracticeBoard(index);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'practice $index',
        );
        expect(
          puzzle.isSolved(puzzle.solution),
          isTrue,
          reason: 'practice $index',
        );
        expect(puzzle.searchNodes, greaterThan(0), reason: 'practice $index');
      }
      expect(signatures, hasLength(320));
      expect(() => IslandSeaPuzzle.forPracticeBoard(301), throwsRangeError);
    });

    test(
      'later campaign bands grow the board and difficulty classification',
      () {
        expect(IslandSeaPuzzle.forLevel(7).difficultyTier, 'ADVANCED');
        expect(IslandSeaPuzzle.forLevel(8).difficultyTier, 'ADVANCED');
        expect(IslandSeaPuzzle.forLevel(9).difficultyTier, 'EXPERT');
        expect(IslandSeaPuzzle.forLevel(10).difficultyTier, 'EXPERT');
        expect(
          IslandSeaPuzzle.forLevel(17).size,
          greaterThan(IslandSeaPuzzle.forLevel(1).size),
        );
      },
    );
  });
}
