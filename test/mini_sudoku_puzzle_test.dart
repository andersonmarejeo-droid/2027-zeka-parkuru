import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_puzzle.dart';

void main() {
  group('Mini Sudoku 6×6 content gate', () {
    test('300 deterministic boards are unique and have one valid solution', () {
      final Set<String> signatures = <String>{};
      for (
        int level = 1;
        level <= MiniSudokuPuzzle.maximumUniqueCases;
        level++
      ) {
        final MiniSudokuPuzzle puzzle = MiniSudokuPuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.boardSignature),
          isTrue,
          reason: 'repeated 6×6 board at level $level',
        );
        expect(puzzle.givens, hasLength(MiniSudokuPuzzle.cellCount));
        expect(puzzle.solution, hasLength(MiniSudokuPuzzle.cellCount));
        expect(
          puzzle.analyze().solutionCount,
          1,
          reason: 'level $level must have exactly one solution',
        );
        expect(
          puzzle.isSolved(puzzle.solution),
          isTrue,
          reason: 'level $level answer must be a valid 6×6 Sudoku',
        );
        expect(
          _hasValidUnits(puzzle.solution),
          isTrue,
          reason: 'level $level: ${puzzle.solution.join(',')}',
        );
        expect(
          MiniSudokuPuzzle.forLevel(level).boardSignature,
          puzzle.boardSignature,
        );
      }
    });

    test('difficulty rises every stage and 7–10 are expert-endgame boards', () {
      final List<int> clues = <int>[];
      for (int stage = 1; stage <= 10; stage++) {
        final MiniSudokuPuzzle puzzle = MiniSudokuPuzzle.forLevel(stage);
        expect(puzzle.localStage, stage);
        expect(
          puzzle.givenCount,
          MiniSudokuPuzzle.targetGivenCountForStage(stage),
        );
        clues.add(puzzle.givenCount);
      }
      for (int index = 1; index < clues.length; index++) {
        expect(clues[index], lessThan(clues[index - 1]));
      }
      expect(MiniSudokuPuzzle.forLevel(7).difficultyTier, 'İLERİ');
      expect(MiniSudokuPuzzle.forLevel(8).difficultyTier, 'İLERİ');
      expect(MiniSudokuPuzzle.forLevel(9).difficultyTier, 'UZMAN');
      expect(MiniSudokuPuzzle.forLevel(10).difficultyTier, 'UZMAN');
      expect(MiniSudokuPuzzle.forLevel(7).blankCount, 19);
      expect(MiniSudokuPuzzle.forLevel(10).blankCount, 22);
    });

    test(
      'candidate and conflict rules honor rows, columns and 2×3 regions',
      () {
        final MiniSudokuPuzzle puzzle = MiniSudokuPuzzle.forLevel(1);
        final int blankIndex = puzzle.givens.indexWhere(
          (int value) => value == 0,
        );
        final Set<int> candidates = puzzle.candidatesFor(
          puzzle.givens,
          blankIndex,
        );
        expect(candidates, contains(puzzle.solution[blankIndex]));
        for (final int candidate in candidates) {
          expect(
            puzzle.hasConflict(puzzle.givens, blankIndex, candidate),
            isFalse,
          );
        }
        expect(puzzle.hasConflict(puzzle.givens, -1, 1), isTrue);
        expect(puzzle.hasConflict(puzzle.givens, blankIndex, 0), isTrue);
      },
    );
  });
}

bool _hasValidUnits(List<int> board) {
  for (int row = 0; row < MiniSudokuPuzzle.size; row++) {
    if (!_containsEveryDigit(<int>[
      for (int column = 0; column < MiniSudokuPuzzle.size; column++)
        board[row * MiniSudokuPuzzle.size + column],
    ])) {
      return false;
    }
  }
  for (int column = 0; column < MiniSudokuPuzzle.size; column++) {
    if (!_containsEveryDigit(<int>[
      for (int row = 0; row < MiniSudokuPuzzle.size; row++)
        board[row * MiniSudokuPuzzle.size + column],
    ])) {
      return false;
    }
  }
  for (
    int row = 0;
    row < MiniSudokuPuzzle.size;
    row += MiniSudokuPuzzle.boxHeight
  ) {
    for (
      int column = 0;
      column < MiniSudokuPuzzle.size;
      column += MiniSudokuPuzzle.boxWidth
    ) {
      final List<int> region = <int>[
        for (int dy = 0; dy < MiniSudokuPuzzle.boxHeight; dy++)
          for (int dx = 0; dx < MiniSudokuPuzzle.boxWidth; dx++)
            board[(row + dy) * MiniSudokuPuzzle.size + column + dx],
      ];
      if (!_containsEveryDigit(region)) return false;
    }
  }
  return true;
}

bool _containsEveryDigit(List<int> values) {
  const Set<int> expected = <int>{1, 2, 3, 4, 5, 6};
  final Set<int> actual = values.toSet();
  return actual.length == MiniSudokuPuzzle.size && actual.containsAll(expected);
}
