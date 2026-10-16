import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/sentence_builder/sentence_builder_scenario.dart';

void main() {
  group('Sentence Builder content contract', () {
    test('20 campaign boards are unique and progress into the master tier', () {
      const List<int> expectedTopTiers = <int>[
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
        level <= SentenceBuilderScenario.campaignLevels;
        level++
      ) {
        final SentenceBuilderScenario board =
            SentenceBuilderScenario.forCampaignLevel(level);
        expect(board.cards, hasLength(4));
        expect(board.stage, level);
        expect(
          board.cards
              .map((SentenceBoardCard card) => card.sentence.minimumStage)
              .reduce((int left, int right) => left > right ? left : right),
          expectedTopTiers[level - 1],
        );
        expect(signatures.add(board.boardSignature), isTrue);
        expect(
          SentenceBuilderScenario.forCampaignLevel(level).boardSignature,
          board.boardSignature,
        );
        for (final SentenceBoardCard item in board.cards) {
          expect(item.sentence.partsTr.length, greaterThanOrEqualTo(3));
          expect(item.sentence.partsEn.length, greaterThanOrEqualTo(3));
          expect(item.scrambledTr.toSet(), item.sentence.partsTr.toSet());
          expect(item.scrambledEn.toSet(), item.sentence.partsEn.toSet());
          expect(item.sentence.contextTr, isNotEmpty);
          expect(item.sentence.clueEn, isNotEmpty);
        }
      }
      final SentenceBuilderScenario finale =
          SentenceBuilderScenario.forCampaignLevel(20);
      expect(
        finale.cards.where(
          (SentenceBoardCard card) => card.sentence.minimumStage == 10,
        ),
        hasLength(4),
      );
    });

    test(
      'first 300 practice boards are distinct and avoid campaign boards',
      () {
        final Set<String> campaign = <String>{
          for (
            int level = 1;
            level <= SentenceBuilderScenario.campaignLevels;
            level++
          )
            SentenceBuilderScenario.forCampaignLevel(level).boardSignature,
        };
        final Set<String> practice = <String>{};
        for (
          int round = 1;
          round <= SentenceBuilderScenario.uniquePracticeRounds;
          round++
        ) {
          final SentenceBuilderScenario board =
              SentenceBuilderScenario.forPracticeRound(round);
          expect(board.cards, hasLength(4));
          expect(board.isPractice, isTrue);
          expect(campaign.contains(board.boardSignature), isFalse);
          expect(
            practice.add(board.boardSignature),
            isTrue,
            reason: 'round $round',
          );
          expect(
            SentenceBuilderScenario.forPracticeRound(round).boardSignature,
            board.boardSignature,
          );
        }
      },
    );

    test('campaign and practice factories reject out-of-range requests', () {
      expect(
        () => SentenceBuilderScenario.forCampaignLevel(0),
        throwsRangeError,
      );
      expect(
        () => SentenceBuilderScenario.forCampaignLevel(21),
        throwsRangeError,
      );
      expect(
        () => SentenceBuilderScenario.forPracticeRound(0),
        throwsRangeError,
      );
      expect(
        () => SentenceBuilderScenario.forPracticeRound(301),
        throwsRangeError,
      );
    });
  });
}
