import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_puzzle.dart';

void main() {
  group('Su Doku aşamaları ve 300 bulmacalık havuz', () {
    test('300 deterministik bulmaca tekrarsız ve tek çözümlüdür', () {
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
          reason: 'Tekrarlanan tahta: havuz $level',
        );
        expect(puzzle.localStage, MiniSudokuPuzzle.stageForLevel(level));
        expect(puzzle.size, MiniSudokuPuzzle.sizeForStage(puzzle.localStage));
        expect(puzzle.givens, hasLength(puzzle.cellCount));
        expect(puzzle.solution, hasLength(puzzle.cellCount));
        expect(
          puzzle.givenCount,
          MiniSudokuPuzzle.targetGivenCountForStage(puzzle.localStage),
        );
        expect(
          puzzle.analyze().solutionCount,
          1,
          reason: 'Havuz $level yalnız bir çözüme sahip olmalı.',
        );
        expect(puzzle.isSolved(puzzle.solution), isTrue);
        expect(
          _hasValidUnits(puzzle, puzzle.solution),
          isTrue,
          reason: 'Havuz $level: ${puzzle.solution.join(',')}',
        );
        expect(
          MiniSudokuPuzzle.forLevel(level).boardSignature,
          puzzle.boardSignature,
        );
      }
      expect(signatures, hasLength(300));
    });

    test('tahta boyutu ve zorluk doğru 30 aşamalı sırayı izler', () {
      for (int level = 1; level <= 300; level++) {
        final MiniSudokuPuzzle puzzle = MiniSudokuPuzzle.forLevel(level);
        final int stage = ((level - 1) % 30) + 1;
        expect(puzzle.localStage, stage);
        expect(puzzle.size, stage <= 6 ? 4 : (stage <= 19 ? 6 : 9));
      }

      final List<int> fourByFourClues = <int>[
        for (int stage = 1; stage <= 6; stage++)
          MiniSudokuPuzzle.forLevel(stage).givenCount,
      ];
      final List<int> sixBySixClues = <int>[
        for (int stage = 7; stage <= 19; stage++)
          MiniSudokuPuzzle.forLevel(stage).givenCount,
      ];
      final List<int> nineByNineClues = <int>[
        for (int stage = 20; stage <= 30; stage++)
          MiniSudokuPuzzle.forLevel(stage).givenCount,
      ];
      expect(fourByFourClues.first, greaterThanOrEqualTo(fourByFourClues.last));
      expect(sixBySixClues.first, greaterThan(sixBySixClues.last));
      expect(nineByNineClues.first, greaterThan(nineByNineClues.last));

      expect(MiniSudokuPuzzle.forLevel(1).size, 4);
      expect(MiniSudokuPuzzle.forLevel(6).size, 4);
      expect(MiniSudokuPuzzle.forLevel(7).size, 6);
      expect(MiniSudokuPuzzle.forLevel(19).size, 6);
      expect(MiniSudokuPuzzle.forLevel(20).size, 9);
      expect(MiniSudokuPuzzle.forLevel(30).size, 9);
      expect(MiniSudokuPuzzle.forLevel(300).localStage, 30);
    });

    test('aday ve çakışma kuralları iki tahta boyutunda da çalışır', () {
      for (final MiniSudokuPuzzle puzzle in <MiniSudokuPuzzle>[
        MiniSudokuPuzzle.forLevel(1),
        MiniSudokuPuzzle.forLevel(300),
      ]) {
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
      }
    });
  });
}

bool _hasValidUnits(MiniSudokuPuzzle puzzle, List<int> board) {
  for (int row = 0; row < puzzle.size; row++) {
    if (!_containsEveryDigit(<int>[
      for (int column = 0; column < puzzle.size; column++)
        board[row * puzzle.size + column],
    ], puzzle.size)) {
      return false;
    }
  }
  for (int column = 0; column < puzzle.size; column++) {
    if (!_containsEveryDigit(<int>[
      for (int row = 0; row < puzzle.size; row++)
        board[row * puzzle.size + column],
    ], puzzle.size)) {
      return false;
    }
  }
  for (int row = 0; row < puzzle.size; row += puzzle.boxHeight) {
    for (int column = 0; column < puzzle.size; column += puzzle.boxWidth) {
      final List<int> region = <int>[
        for (int dy = 0; dy < puzzle.boxHeight; dy++)
          for (int dx = 0; dx < puzzle.boxWidth; dx++)
            board[(row + dy) * puzzle.size + column + dx],
      ];
      if (!_containsEveryDigit(region, puzzle.size)) return false;
    }
  }
  return true;
}

bool _containsEveryDigit(List<int> values, int size) {
  final Set<int> expected = <int>{
    for (int value = 1; value <= size; value++) value,
  };
  final Set<int> actual = values.toSet();
  return actual.length == size && actual.containsAll(expected);
}
