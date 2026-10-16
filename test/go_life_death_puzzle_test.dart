import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/go_life_death/go_life_death_puzzle.dart';
import 'package:zeka_parkuru/games/go_life_death/go_position.dart';

void main() {
  group('Go hamle motoru', () {
    test('tek özgürlükteki grup taşınca yakalanır', () {
      final GoPosition position = GoPosition(
        size: 3,
        stones: <GoStone>[
          GoStone.empty,
          GoStone.black,
          GoStone.empty,
          GoStone.black,
          GoStone.white,
          GoStone.black,
          GoStone.empty,
          GoStone.empty,
          GoStone.empty,
        ],
        toMove: GoStone.black,
      );
      expect(position.groupAt(4)!.liberties, <int>{7});
      final GoPlayResult? result = position.play(7);
      expect(result, isNotNull);
      expect(result!.captured, <int>{4});
      expect(result.position.at(4), GoStone.empty);
      expect(result.position.toMove, GoStone.white);
    });

    test('intihar hamlesini reddeder, iki pas oyunu bitirir', () {
      final GoPosition surrounded = GoPosition(
        size: 3,
        stones: <GoStone>[
          GoStone.empty,
          GoStone.white,
          GoStone.empty,
          GoStone.white,
          GoStone.empty,
          GoStone.white,
          GoStone.empty,
          GoStone.white,
          GoStone.empty,
        ],
        toMove: GoStone.black,
      );
      expect(surrounded.play(4), isNull);
      final GoPosition ended = surrounded.pass().pass();
      expect(ended.isGameOver, isTrue);
      expect(ended.play(4), isNull);
    });
  });

  group('Go Yaşam-Ölüm içerik sertifikası', () {
    test('20 kampanya tsumegosu kademeli hedef ve tek doğru hamle taşır', () {
      final List<GoLifeDeathPuzzle> puzzles = <GoLifeDeathPuzzle>[
        for (int level = 1; level <= GoLifeDeathPuzzle.maximumLevels; level++)
          GoLifeDeathPuzzle.forLevel(level),
      ];
      expect(
        puzzles.map((GoLifeDeathPuzzle puzzle) => puzzle.signature).toSet(),
        hasLength(20),
      );
      for (final GoLifeDeathPuzzle puzzle in puzzles) {
        expect(puzzle.position.hasOnlyGroupsWithLiberties(), isTrue);
        expect(puzzle.targetLiberties, 1);
        expect(puzzle.isSolution(puzzle.solutionPoint), isTrue);
        expect(puzzle.certifiedWinningMoves, <int>[puzzle.solutionPoint]);
      }
      expect(GoLifeDeathPuzzle.forLevel(7).position.size, 7);
      expect(GoLifeDeathPuzzle.forLevel(9).difficultyTier, 'EXPERT');
      expect(GoLifeDeathPuzzle.forLevel(19).position.size, 9);
    });

    test('ilk 300 pratik konumu kampanya ve kendi arasında tekrarsızdır', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= GoLifeDeathPuzzle.maximumLevels; level++)
          GoLifeDeathPuzzle.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= GoLifeDeathPuzzle.maximumVerifiedBoards;
        index++
      ) {
        final GoLifeDeathPuzzle puzzle = GoLifeDeathPuzzle.forPracticeBoard(
          index,
        );
        expect(
          signatures.add(puzzle.signature),
          isTrue,
          reason: 'Board $index',
        );
        expect(puzzle.certifiedWinningMoves, <int>[puzzle.solutionPoint]);
      }
      expect(signatures, hasLength(320));
      expect(() => GoLifeDeathPuzzle.forPracticeBoard(301), throwsRangeError);
    });
  });
}
