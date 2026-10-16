import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/near_meaning/near_meaning_scenario.dart';

void main() {
  group('Near Meaning content contract', () {
    test('20 campaign boards are distinct and resolve to deeper tiers', () {
      const List<int> topTiers = <int>[
        1,
        1,
        1,
        3,
        3,
        3,
        5,
        5,
        5,
        7,
        7,
        7,
        9,
        9,
        9,
        10,
        10,
        10,
        10,
        10,
      ];
      final Set<String> signatures = <String>{};
      for (
        int level = 1;
        level <= NearMeaningScenario.campaignLevels;
        level++
      ) {
        final NearMeaningScenario board = NearMeaningScenario.forCampaignLevel(
          level,
        );
        expect(board.cards, hasLength(4));
        expect(board.stage, level);
        expect(signatures.add(board.boardSignature), isTrue);
        expect(
          board.cards
              .map((NearMeaningBoardCard item) => item.card.minimumStage)
              .reduce((int a, int b) => a > b ? a : b),
          topTiers[level - 1],
        );
        for (final NearMeaningBoardCard item in board.cards) {
          expect(item.optionOrder.toSet(), <int>{0, 1, 2, 3});
          expect(item.correctOptionIndex, inInclusiveRange(0, 3));
          expect(item.card.optionsTr, hasLength(4));
          expect(item.card.optionsTr.toSet(), hasLength(4));
          expect(item.card.optionsEn, hasLength(4));
          expect(item.card.optionsEn.toSet(), hasLength(4));
          expect(item.card.explanationTr, isNotEmpty);
          expect(item.card.explanationEn, isNotEmpty);
        }
        expect(
          NearMeaningScenario.forCampaignLevel(level).cards.first.optionOrder,
          board.cards.first.optionOrder,
        );
      }
      expect(
        NearMeaningScenario.forCampaignLevel(20).cards
            .where((NearMeaningBoardCard item) => item.card.minimumStage == 10),
        hasLength(4),
      );
    });

    test('first 300 practice boards are unique and separate from campaign', () {
      final Set<String> campaign = <String>{
        for (
          int level = 1;
          level <= NearMeaningScenario.campaignLevels;
          level++
        )
          NearMeaningScenario.forCampaignLevel(level).boardSignature,
      };
      final Set<String> practice = <String>{};
      for (
        int round = 1;
        round <= NearMeaningScenario.uniquePracticeRounds;
        round++
      ) {
        final NearMeaningScenario board = NearMeaningScenario.forPracticeRound(
          round,
        );
        expect(board.cards, hasLength(4));
        expect(campaign.contains(board.boardSignature), isFalse);
        expect(
          practice.add(board.boardSignature),
          isTrue,
          reason: 'round $round',
        );
      }
    });

    test('factories reject invalid campaign and practice indices', () {
      expect(() => NearMeaningScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => NearMeaningScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => NearMeaningScenario.forPracticeRound(0), throwsRangeError);
      expect(() => NearMeaningScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
