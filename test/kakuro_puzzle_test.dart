import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kakuro/kakuro_puzzle.dart';

void main() {
  group('Kakuro campaign quality gate', () {
    test('all 20 boards are stable, distinct, valid and uniquely solvable', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= KakuroPuzzle.maximumLevels; level++) {
        final KakuroPuzzle puzzle = KakuroPuzzle.forLevel(level);
        expect(
          signatures.add(puzzle.boardSignature),
          isTrue,
          reason: 'repeated Kakuro board at level $level',
        );
        expect(puzzle.solution, hasLength(puzzle.size * puzzle.size));
        expect(
          puzzle.solveUnique(),
          puzzle.solution,
          reason: 'unique verified solution at level $level',
        );

        for (final KakuroRun run in <KakuroRun>[
          ...puzzle.acrossRuns,
          ...puzzle.downRuns,
        ]) {
          final List<int> digits = run.cells
              .map((int index) => puzzle.solution[index])
              .toList(growable: false);
          expect(
            digits.toSet(),
            hasLength(digits.length),
            reason: 'no repeated digit in $run at level $level',
          );
          expect(
            digits.reduce((int a, int b) => a + b),
            run.targetSum,
            reason: 'clue sum matches answer at level $level',
          );
          expect(run.cells.length, inInclusiveRange(2, 9));
        }
      }
      expect(signatures, hasLength(KakuroPuzzle.maximumLevels));
    });

    test(
      'the second chapter grows the grid and expert stages add long runs',
      () {
        final List<KakuroPuzzle> firstChapter = <KakuroPuzzle>[
          for (int level = 1; level <= 10; level++)
            KakuroPuzzle.forLevel(level),
        ];
        final List<KakuroPuzzle> secondChapter = <KakuroPuzzle>[
          for (int level = 11; level <= 20; level++)
            KakuroPuzzle.forLevel(level),
        ];
        expect(firstChapter.first.size, 5);
        expect(firstChapter.last.size, 8);
        expect(secondChapter.first.size, greaterThan(firstChapter.first.size));
        for (int stage = 7; stage <= 10; stage++) {
          final String expectedTier = stage <= 8 ? 'EXPERT' : 'EXPERT+';
          expect(firstChapter[stage - 1].difficultyTier, expectedTier);
          expect(secondChapter[stage - 1].difficultyTier, expectedTier);
        }
        expect(
          <KakuroRun>[
            ...secondChapter[8].acrossRuns,
            ...secondChapter[8].downRuns,
          ].any((KakuroRun run) => run.cells.length >= 5),
          isTrue,
        );
        expect(
          <KakuroRun>[
            ...secondChapter[9].acrossRuns,
            ...secondChapter[9].downRuns,
          ].any((KakuroRun run) => run.cells.length >= 5),
          isTrue,
        );
      },
    );

    test('invalid campaign levels are rejected', () {
      expect(() => KakuroPuzzle.forLevel(0), throwsRangeError);
      expect(() => KakuroPuzzle.forLevel(21), throwsRangeError);
    });
  });
}
