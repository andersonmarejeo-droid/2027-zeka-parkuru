import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_scenario.dart';

void main() {
  group('Card Pairs content contract', () {
    test('20 campaign decks progress from visual twins to semantic links', () {
      final Set<String> signatures = <String>{};
      for (int level = 1; level <= CardPairsScenario.campaignLevels; level++) {
        final CardPairsScenario board = CardPairsScenario.forCampaignLevel(
          level,
        );
        expect(board.stage, level);
        expect(
          board.pairCount,
          level < 4
              ? 3
              : level < 7
              ? 4
              : level < 11
              ? 6
              : level < 17
              ? 8
              : 10,
        );
        expect(
          board.cards.where((CardPairCard card) => !card.isDecoy).length,
          board.pairCount * 2,
        );
        expect(
          board.cards.where((CardPairCard card) => card.isDecoy).length,
          level < 7
              ? 0
              : level < 11
              ? 2
              : level < 17
              ? 4
              : 6,
        );
        for (int pair = 0; pair < board.pairCount; pair++) {
          expect(
            board.cardsForPair(
              'pair_${pair}_content_${(level * 3 + pair * 5) % 16}',
            ),
            hasLength(2),
          );
        }
        expect(signatures.add(board.boardSignature), isTrue);
      }
    });

    test('identical-image pairs are visually identical on both cards', () {
      final CardPairsScenario board = CardPairsScenario.forCampaignLevel(1);
      for (final String pairId in <String>{
        for (final CardPairCard card in board.cards) card.pairId!,
      }) {
        final List<CardPairCard> pair = board.cardsForPair(pairId);
        expect(pair, hasLength(2));
        expect(pair[0].label, pair[1].label);
        expect(pair[0].iconKey, pair[1].iconKey);
        expect(pair[0].colorIndex, pair[1].colorIndex);
        expect(pair[0].patternIndex, pair[1].patternIndex);
      }
    });

    test('first 300 practice decks are unique and campaign-disjoint', () {
      final Set<String> campaign = <String>{
        for (int level = 1; level <= CardPairsScenario.campaignLevels; level++)
          CardPairsScenario.forCampaignLevel(level).boardSignature,
      };
      final Set<String> practice = <String>{};
      for (
        int round = 1;
        round <= CardPairsScenario.uniquePracticeRounds;
        round++
      ) {
        final CardPairsScenario board = CardPairsScenario.forPracticeRound(
          round,
        );
        expect(board.isPractice, isTrue);
        expect(campaign.contains(board.boardSignature), isFalse);
        expect(
          practice.add(board.boardSignature),
          isTrue,
          reason: 'round $round',
        );
      }
    });

    test('factories reject invalid content indices', () {
      expect(() => CardPairsScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => CardPairsScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => CardPairsScenario.forPracticeRound(0), throwsRangeError);
      expect(() => CardPairsScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
