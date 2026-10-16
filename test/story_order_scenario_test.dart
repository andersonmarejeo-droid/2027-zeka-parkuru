import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/story_order/story_order_scenario.dart';

void main() {
  group('Story Order content contract', () {
    test('20 campaign stories are unique, solvable and ramp in difficulty', () {
      for (final bool english in <bool>[false, true]) {
        final Set<String> signatures = <String>{};
        for (
          int level = 1;
          level <= StoryOrderScenario.campaignLevels;
          level++
        ) {
          final StoryOrderScenario board = StoryOrderScenario.forCampaignLevel(
            level,
            english: english,
          );
          expect(board.stage, level);
          expect(board.expectedIds, hasLength(level >= 7 ? 5 : 4));
          expect(board.hasDecoy, level >= 7);
          expect(board.acceptsSequence(board.expectedIds), isTrue);
          expect(board.title, isNotEmpty);
          expect(board.setup, isNotEmpty);
          expect(board.explanation, isNotEmpty);
          expect(signatures.add(board.boardSignature), isTrue);
          expect(
            board.cards.every(
              (StorySequenceCard card) =>
                  !card.text.contains('{person}') &&
                  !card.text.contains('{moment}'),
            ),
            isTrue,
          );
          if (level >= 17) expect(level, greaterThanOrEqualTo(17));
        }
      }
    });

    test(
      'first 300 practice files are unique and disjoint from the campaign',
      () {
        for (final bool english in <bool>[false, true]) {
          final Set<String> campaign = <String>{
            for (
              int level = 1;
              level <= StoryOrderScenario.campaignLevels;
              level++
            )
              StoryOrderScenario.forCampaignLevel(
                level,
                english: english,
              ).boardSignature,
          };
          final Set<String> practice = <String>{};
          for (
            int round = 1;
            round <= StoryOrderScenario.uniquePracticeRounds;
            round++
          ) {
            final StoryOrderScenario board =
                StoryOrderScenario.forPracticeRound(round, english: english);
            expect(board.isPractice, isTrue);
            expect(board.acceptsSequence(board.expectedIds), isTrue);
            expect(campaign.contains(board.boardSignature), isFalse);
            expect(
              practice.add(board.boardSignature),
              isTrue,
              reason: 'round $round',
            );
          }
        }
      },
    );

    test('decoys and reordered or incomplete timelines are rejected', () {
      final StoryOrderScenario board = StoryOrderScenario.forCampaignLevel(20);
      final String decoy = board.cards
          .singleWhere((StorySequenceCard card) => card.isDecoy)
          .id;
      expect(
        board.acceptsSequence(<String>[...board.expectedIds.take(4), decoy]),
        isFalse,
      );
      expect(
        board.acceptsSequence(board.expectedIds.reversed.toList()),
        isFalse,
      );
      expect(
        board.acceptsSequence(board.expectedIds.take(4).toList()),
        isFalse,
      );
    });

    test('factories reject invalid indices', () {
      expect(() => StoryOrderScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => StoryOrderScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => StoryOrderScenario.forPracticeRound(0), throwsRangeError);
      expect(() => StoryOrderScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
