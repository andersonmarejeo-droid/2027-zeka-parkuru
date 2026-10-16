import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/loop_master/loop_puzzle.dart';

void main() {
  group('Döngü Ustası kural modeli', () {
    test('tek kapalı halka tüm kenar sayılarını karşılar', () {
      final LoopPuzzle puzzle = LoopPuzzle.forLevel(1);
      expect(puzzle.validateSingleLoop(puzzle.solutionEdges), isTrue);
      expect(puzzle.isSolved(puzzle.solutionEdges), isTrue);
      expect(puzzle.solve().solutionCount, 1);

      for (int index = 0; index < puzzle.solutionVertices.length; index++) {
        final int first = puzzle.solutionVertices[index];
        final int second = puzzle
            .solutionVertices[(index + 1) % puzzle.solutionVertices.length];
        expect(
          puzzle.solutionEdges.any((int edge) {
            final (int a, int b) = puzzle.edgeEndpoints(edge);
            return (a == first && b == second) || (a == second && b == first);
          }),
          isTrue,
        );
      }
    });

    test('açık çizgi, dallanma ve ayrı küçük halka kabul edilmez', () {
      final LoopPuzzle puzzle = LoopPuzzle.forLevel(1);
      final Set<int> openPath = puzzle.solutionEdges
          .take(puzzle.solutionEdges.length - 1)
          .toSet();
      expect(puzzle.validateSingleLoop(openPath), isFalse);
      expect(
        puzzle.canAddEdge(puzzle.solutionEdges, puzzle.solutionEdges.first),
        isFalse,
      );
    });
  });

  group('Döngü Ustası içerik sertifikası', () {
    test(
      '20 kampanya tahtası tek çözümlü ve artan çıkarım derinlikli olur',
      () {
        final List<LoopPuzzle> puzzles = <LoopPuzzle>[
          for (int level = 1; level <= LoopPuzzle.maximumLevels; level++)
            LoopPuzzle.forLevel(level),
        ];
        expect(
          puzzles.map((LoopPuzzle puzzle) => puzzle.signature).toSet(),
          hasLength(LoopPuzzle.maximumLevels),
        );
        for (final LoopPuzzle puzzle in puzzles) {
          expect(puzzle.solve().solutionCount, 1, reason: puzzle.signature);
          expect(puzzle.isSolved(puzzle.solve().firstSolution!), isTrue);
        }
        expect(LoopPuzzle.forLevel(7).difficultyTier, 'ADVANCED');
        expect(LoopPuzzle.forLevel(9).difficultyTier, 'EXPERT');
        expect(LoopPuzzle.forLevel(17).difficultyTier, 'MASTER');
      },
    );

    test(
      'ilk 300 tekrar haritası kampanya ile ve kendi içinde tekrarsızdır',
      () {
        final Set<String> signatures = <String>{
          for (int level = 1; level <= LoopPuzzle.maximumLevels; level++)
            LoopPuzzle.forLevel(level).signature,
        };
        for (
          int index = 1;
          index <= LoopPuzzle.maximumVerifiedBoards;
          index++
        ) {
          final LoopPuzzle puzzle = LoopPuzzle.forPracticeBoard(index);
          expect(
            signatures.add(puzzle.signature),
            isTrue,
            reason: 'Board $index',
          );
          expect(puzzle.solve().solutionCount, 1, reason: 'Board $index');
          expect(puzzle.isSolved(puzzle.solve().firstSolution!), isTrue);
        }
        expect(signatures, hasLength(320));
        expect(() => LoopPuzzle.forPracticeBoard(301), throwsRangeError);
      },
    );
  });
}
