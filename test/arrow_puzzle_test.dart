import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/arrow_route/arrow_puzzle.dart';

void main() {
  group('Ok Rotası içerik sözleşmesi', () {
    test('20 kampanya tahtası benzersiz ve tek çıkış sırasına sahiptir', () {
      final List<ArrowPuzzle> puzzles = <ArrowPuzzle>[
        for (int level = 1; level <= ArrowPuzzle.maximumLevels; level++)
          ArrowPuzzle.forLevel(level),
      ];
      expect(
        puzzles.map((ArrowPuzzle puzzle) => puzzle.signature).toSet(),
        hasLength(ArrowPuzzle.maximumLevels),
      );
      for (final ArrowPuzzle puzzle in puzzles) {
        expect(puzzle.hasCertifiedUniqueOrder(), isTrue);
        expect(puzzle.arrows.length, puzzle.solutionIds.length);
        expect(
          puzzle.clearable(
            puzzle.arrows.map((RouteArrow arrow) => arrow.id).toSet(),
          ),
          hasLength(1),
        );
      }
      expect(ArrowPuzzle.forLevel(7).difficultyTier, 'ADVANCED');
      expect(ArrowPuzzle.forLevel(8).difficultyTier, 'ADVANCED');
      expect(ArrowPuzzle.forLevel(9).difficultyTier, 'EXPERT');
      expect(ArrowPuzzle.forLevel(10).difficultyTier, 'EXPERT');
      expect(ArrowPuzzle.forLevel(17).difficultyTier, 'MASTER');
      expect(ArrowPuzzle.forLevel(20).arrows.length, greaterThan(24));
    });

    test(
      'ilk 300 pratik yerleşim kampanya ile ve kendi arasında tekrarsızdır',
      () {
        final Set<String> signatures = <String>{
          for (int level = 1; level <= ArrowPuzzle.maximumLevels; level++)
            ArrowPuzzle.forLevel(level).signature,
        };
        for (
          int index = 1;
          index <= ArrowPuzzle.maximumVerifiedBoards;
          index++
        ) {
          final ArrowPuzzle puzzle = ArrowPuzzle.forPracticeBoard(index);
          expect(puzzle.hasCertifiedUniqueOrder(), isTrue);
          signatures.add(puzzle.signature);
        }
        expect(
          signatures,
          hasLength(
            ArrowPuzzle.maximumLevels + ArrowPuzzle.maximumVerifiedBoards,
          ),
        );
        expect(() => ArrowPuzzle.forPracticeBoard(301), throwsRangeError);
      },
    );
  });
}
