import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/skyscrapers/skyscrapers_puzzle.dart';

void main() {
  group('Skyscrapers content certification', () {
    test('canonical large skyline remains solver-friendly', () {
      const int size = 7;
      final List<int> solution = <int>[
        for (int row = 0; row < size; row++)
          for (int column = 0; column < size; column++)
            (row + column) % size + 1,
      ];
      int visible(Iterable<int> line) {
        int maximum = 0;
        int count = 0;
        for (final int value in line) {
          if (value <= maximum) continue;
          maximum = value;
          count++;
        }
        return count;
      }

      final List<int> top = <int>[
        for (int column = 0; column < size; column++)
          visible(<int>[
            for (int row = 0; row < size; row++) solution[row * size + column],
          ]),
      ];
      final List<int> bottom = <int>[
        for (int column = 0; column < size; column++)
          visible(<int>[
            for (int row = size - 1; row >= 0; row--)
              solution[row * size + column],
          ]),
      ];
      final List<int> left = <int>[
        for (int row = 0; row < size; row++)
          visible(solution.skip(row * size).take(size)),
      ];
      final List<int> right = <int>[
        for (int row = 0; row < size; row++)
          visible(solution.skip(row * size).take(size).toList().reversed),
      ];
      final SkyscrapersSolveResult result = SkyscrapersPuzzle.countSolutions(
        size: size,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
      );
      expect(result.solutionCount, 1);
      expect(result.exceededNodeLimit, isFalse);
      expect(result.visitedNodes, lessThan(50000));
    });

    test('the solver proves one Latin skyline and checks edge visibility', () {
      final SkyscrapersPuzzle puzzle = SkyscrapersPuzzle.forLevel(1);
      final SkyscrapersSolveResult result = SkyscrapersPuzzle.countSolutions(
        size: puzzle.size,
        top: puzzle.top,
        bottom: puzzle.bottom,
        left: puzzle.left,
        right: puzzle.right,
      );

      expect(result.solutionCount, 1);
      expect(result.exceededNodeLimit, isFalse);
      expect(result.firstSolution, puzzle.solution);
      expect(puzzle.isSolved(puzzle.solution), isTrue);
      final List<int> broken = List<int>.of(puzzle.solution)
        ..[0] = puzzle.solution[1];
      expect(puzzle.isSolved(broken), isFalse);
    });

    final Set<String> signatures = <String>{};
    int previousSize = 0;
    for (int level = 1; level <= SkyscrapersPuzzle.maximumLevels; level++) {
      test('campaign level $level is unique and certified', () {
        final SkyscrapersPuzzle puzzle = SkyscrapersPuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(
          puzzle.hasUniqueCertifiedSolution,
          isTrue,
          reason: 'level $level',
        );
        expect(
          puzzle.clueCount,
          greaterThanOrEqualTo(
            SkyscrapersPuzzle.minimumClueCountForLevel(level),
          ),
        );
        expect(puzzle.size, greaterThanOrEqualTo(previousSize));
        expect(puzzle.size, SkyscrapersPuzzle.sizeForLevel(level));
        previousSize = puzzle.size;
      });
    }
    test('campaign tiers identify advanced, expert and master play', () {
      expect(signatures, hasLength(20));
      expect(SkyscrapersPuzzle.forLevel(7).difficultyTier, 'ADVANCED');
      expect(SkyscrapersPuzzle.forLevel(9).difficultyTier, 'EXPERT');
      expect(SkyscrapersPuzzle.forLevel(20).difficultyTier, 'MASTER SKYLINE');
    });

    final Set<String> practiceSignatures = <String>{};
    for (int start = 1; start <= 300; start += 25) {
      final int end = math.min(start + 24, 300);
      test('practice skylines $start–$end are unique and certified', () {
        if (start == 1) practiceSignatures.addAll(signatures);
        for (int index = start; index <= end; index++) {
          final SkyscrapersPuzzle puzzle = SkyscrapersPuzzle.forPracticeBoard(
            index,
          );
          expect(
            practiceSignatures.add(puzzle.signature),
            isTrue,
            reason: 'practice $index',
          );
          expect(
            puzzle.hasUniqueCertifiedSolution,
            isTrue,
            reason: 'practice $index',
          );
        }
      });
    }
    test('practice bank reaches exactly 300 boards and rejects overflow', () {
      expect(practiceSignatures, hasLength(320));
      expect(() => SkyscrapersPuzzle.forPracticeBoard(301), throwsRangeError);
    });

    test('the solver detects ambiguity and rejects malformed clue vectors', () {
      expect(
        SkyscrapersPuzzle.countSolutions(
          size: 4,
          top: const <int>[0, 0, 0, 0],
          bottom: const <int>[0, 0, 0, 0],
          left: const <int>[0, 0, 0, 0],
          right: const <int>[0, 0, 0, 0],
        ).solutionCount,
        2,
      );
      expect(
        () => SkyscrapersPuzzle.countSolutions(
          size: 4,
          top: const <int>[1, 2],
          bottom: const <int>[0, 0, 0, 0],
          left: const <int>[0, 0, 0, 0],
          right: const <int>[0, 0, 0, 0],
        ),
        throwsArgumentError,
      );
    });

    test(
      'revealed clues agree with the certified solution from every side',
      () {
        for (int level = 1; level <= SkyscrapersPuzzle.maximumLevels; level++) {
          final SkyscrapersPuzzle puzzle = SkyscrapersPuzzle.forLevel(level);
          expect(
            puzzle.isSolved(puzzle.solution),
            isTrue,
            reason: 'level $level',
          );
          expect(
            puzzle.solution.every(
              (int height) => height >= 1 && height <= puzzle.size,
            ),
            isTrue,
            reason: 'level $level',
          );
        }
      },
    );
  });
}
