import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/light_sequence/light_sequence_scenario.dart';

void main() {
  group('Light Sequence content contract', () {
    test('20 campaign patterns are unique and reach expert reverse recall', () {
      final Set<String> signatures = <String>{};
      for (
        int level = 1;
        level <= LightSequenceScenario.campaignLevels;
        level++
      ) {
        final LightSequenceScenario board =
            LightSequenceScenario.forCampaignLevel(level);
        expect(board.stage, level);
        expect(board.sequence.toSet(), hasLength(board.sequence.length));
        expect(board.accepts(board.answer), isTrue);
        expect(signatures.add(board.boardSignature), isTrue);
        expect(board.gridSize, 5);
        expect(
          board.decoyCount,
          level < 7
              ? 0
              : level < 11
              ? 2
              : level < 17
              ? 3
              : 4,
        );
        expect(board.reverseRecall, level >= 11);
        if (level >= 17) expect(board.sequence.length, greaterThanOrEqualTo(9));
      }
    });

    test('first 300 practice patterns are unique and campaign-disjoint', () {
      final Set<String> campaign = <String>{
        for (
          int level = 1;
          level <= LightSequenceScenario.campaignLevels;
          level++
        )
          LightSequenceScenario.forCampaignLevel(level).boardSignature,
      };
      final Set<String> practice = <String>{};
      for (
        int round = 1;
        round <= LightSequenceScenario.uniquePracticeRounds;
        round++
      ) {
        final LightSequenceScenario board =
            LightSequenceScenario.forPracticeRound(round);
        expect(board.isPractice, isTrue);
        expect(board.accepts(board.answer), isTrue);
        expect(campaign.contains(board.boardSignature), isFalse);
        expect(
          practice.add(board.boardSignature),
          isTrue,
          reason: 'round $round',
        );
      }
    });

    test('false flashes are excluded and incorrect direction is rejected', () {
      for (int level in <int>[7, 12, 20]) {
        final LightSequenceScenario board =
            LightSequenceScenario.forCampaignLevel(level);
        final List<int> withDecoy = <int>[
          ...board.answer,
          board.flashes.firstWhere((LightSequenceFlash f) => f.isDecoy).cell,
        ];
        expect(board.accepts(withDecoy), isFalse);
        expect(board.accepts(board.answer.reversed.toList()), isFalse);
      }
    });

    test('factories reject indices outside the content promise', () {
      expect(() => LightSequenceScenario.forCampaignLevel(0), throwsRangeError);
      expect(
        () => LightSequenceScenario.forCampaignLevel(21),
        throwsRangeError,
      );
      expect(() => LightSequenceScenario.forPracticeRound(0), throwsRangeError);
      expect(
        () => LightSequenceScenario.forPracticeRound(301),
        throwsRangeError,
      );
    });
  });
}
