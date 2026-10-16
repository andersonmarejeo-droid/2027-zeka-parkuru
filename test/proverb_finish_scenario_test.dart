import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/proverb_finish/proverb_finish_scenario.dart';

void main() {
  group('Proverb Finish content contract', () {
    test('20 campaign boards use 80 unique proverbs and ramp in difficulty', () {
      final Set<String> signatures = <String>{};
      final Set<String> usedProverbIds = <String>{};
      final Set<String> usedProverbs = <String>{};
      const List<int> tiers = <int>[
        1,
        3,
        5,
        7,
        9,
        10,
        10,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        20,
        20,
      ];

      for (
        int level = 1;
        level <= ProverbFinishScenario.campaignLevels;
        level++
      ) {
        final ProverbFinishScenario scenario =
            ProverbFinishScenario.forCampaignLevel(level);
        expect(scenario.cards, hasLength(4));
        expect(
          scenario.cards.map((ProverbCard card) => card.id).toSet(),
          hasLength(4),
        );
        expect(scenario.answerOrder, hasLength(4));
        expect(scenario.answerOrder.toSet(), hasLength(4));
        expect(
          scenario.answerOrder.toSet(),
          equals(scenario.cards.map((ProverbCard card) => card.ending).toSet()),
        );
        expect(
          scenario.cards
              .map((ProverbCard card) => card.minimumStage)
              .reduce((int left, int right) => left > right ? left : right),
          tiers[level - 1],
        );
        expect(signatures.add(scenario.boardSignature), isTrue);
        for (final ProverbCard card in scenario.cards) {
          expect(usedProverbIds.add(card.id), isTrue);
          expect(usedProverbs.add(card.fullText), isTrue);
        }
        expect(
          ProverbFinishScenario.forCampaignLevel(level).boardSignature,
          scenario.boardSignature,
        );
        for (final ProverbCard card in scenario.cards) {
          expect(card.opening.trim(), isNotEmpty);
          expect(card.ending.trim(), isNotEmpty);
          expect(card.meaningTr.trim(), isNotEmpty);
          expect(card.meaningEn.trim(), isNotEmpty);
          expect(card.contextTr.trim(), isNotEmpty);
          expect(card.contextEn.trim(), isNotEmpty);
          expect(card.fullText, contains(card.ending));
        }
      }
      expect(usedProverbIds, hasLength(80));
      expect(usedProverbs, hasLength(80));

      final ProverbFinishScenario expert =
          ProverbFinishScenario.forCampaignLevel(20);
      expect(
        expert.cards.where((ProverbCard card) => card.minimumStage == 20),
        hasLength(4),
      );
    });

    test(
      '300 practice boards stay unique and avoid adjacent proverb repeats',
      () {
        final Set<String> campaign = <String>{
          for (
            int level = 1;
            level <= ProverbFinishScenario.campaignLevels;
            level++
          )
            ProverbFinishScenario.forCampaignLevel(level).boardSignature,
        };
        final Set<String> practice = <String>{};

        for (
          int round = 1;
          round <= ProverbFinishScenario.uniquePracticeRounds;
          round++
        ) {
          final ProverbFinishScenario scenario =
              ProverbFinishScenario.forPracticeRound(round);
          expect(scenario.isPractice, isTrue);
          expect(scenario.round, round);
          expect(scenario.cards, hasLength(4));
          expect(campaign.contains(scenario.boardSignature), isFalse);
          expect(practice.add(scenario.boardSignature), isTrue);
          if (round > 1) {
            final Set<String> previousIds =
                ProverbFinishScenario.forPracticeRound(round - 1)
                    .cards
                    .map((ProverbCard card) => card.id)
                    .toSet();
            expect(
              scenario.cards.every(
                (ProverbCard card) => !previousIds.contains(card.id),
              ),
              isTrue,
            );
          }
        }
      },
    );

    test(
      'factories reject campaign and practice numbers outside the contract',
      () {
        expect(
          () => ProverbFinishScenario.forCampaignLevel(0),
          throwsRangeError,
        );
        expect(
          () => ProverbFinishScenario.forCampaignLevel(21),
          throwsRangeError,
        );
        expect(
          () => ProverbFinishScenario.forPracticeRound(0),
          throwsRangeError,
        );
        expect(
          () => ProverbFinishScenario.forPracticeRound(301),
          throwsRangeError,
        );
      },
    );
  });
}
