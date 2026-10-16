import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/letter_maze/letter_maze_scenario.dart';

void main() {
  group('Letter Maze content contract', () {
    test('20 campaign routes are valid and the hard bands step up', () {
      for (final bool english in <bool>[false, true]) {
        final Set<String> signatures = <String>{};
        for (
          int level = 1;
          level <= LetterMazeScenario.campaignLevels;
          level++
        ) {
          final LetterMazeScenario board = LetterMazeScenario.forCampaignLevel(
            level,
            english: english,
          );
          expect(board.stage, level);
          expect(board.tiles, hasLength(25));
          expect(board.solutionPath, hasLength(board.answer.runes.length));
          expect(board.acceptsRoute(board.solutionPath), isTrue);
          expect(signatures.add(board.boardSignature), isTrue);
          expect(board.clue, isNotEmpty);
          expect(board.explanation, isNotEmpty);
          if (level >= 7 && level <= 10) {
            expect(board.answer.runes.length, greaterThanOrEqualTo(8));
          }
          if (level >= 17) {
            expect(board.answer.runes.length, greaterThanOrEqualTo(10));
          }
        }
      }
    });

    test('first 300 practice mazes are unique and campaign-disjoint', () {
      for (final bool english in <bool>[false, true]) {
        final Set<String> campaign = <String>{
          for (
            int level = 1;
            level <= LetterMazeScenario.campaignLevels;
            level++
          )
            LetterMazeScenario.forCampaignLevel(
              level,
              english: english,
            ).boardSignature,
        };
        final Set<String> practice = <String>{};
        for (
          int round = 1;
          round <= LetterMazeScenario.uniquePracticeRounds;
          round++
        ) {
          final LetterMazeScenario board = LetterMazeScenario.forPracticeRound(
            round,
            english: english,
          );
          expect(board.isPractice, isTrue);
          expect(board.acceptsRoute(board.solutionPath), isTrue);
          expect(campaign.contains(board.boardSignature), isFalse);
          expect(
            practice.add(board.boardSignature),
            isTrue,
            reason: 'round $round (${english ? 'en' : 'tr'})',
          );
        }
      }
    });

    test(
      'all curated words have a valid two-part gate and bad routes fail',
      () {
        for (int round = 1; round <= 24; round++) {
          for (final bool english in <bool>[false, true]) {
            final LetterMazeScenario board =
                LetterMazeScenario.forPracticeRound(round, english: english);
            final List<String> parts = english
                ? board.lexeme.partsEn
                : board.lexeme.partsTr;
            expect(parts, hasLength(2));
            expect(parts.join(), board.answer);
            expect(board.solutionPath, contains(board.checkpointIndex));
            expect(
              board.acceptsRoute(board.solutionPath.reversed.toList()),
              isFalse,
            );
            expect(board.acceptsRoute(<int>[-1, 2, 7]), isFalse);
          }
        }
      },
    );

    test('factories reject invalid indices', () {
      expect(() => LetterMazeScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => LetterMazeScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => LetterMazeScenario.forPracticeRound(0), throwsRangeError);
      expect(() => LetterMazeScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
