import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/spot_change/spot_change_scenario.dart';

void main() {
  group('Spot the Change content contract', () {
    test(
      '20 scenes increase density and changed positions through the finale',
      () {
        final Set<String> signatures = <String>{};
        for (
          int level = 1;
          level <= SpotChangeScenario.campaignLevels;
          level++
        ) {
          final SpotChangeScenario scene = SpotChangeScenario.forCampaignLevel(
            level,
          );
          expect(scene.stage, level);
          expect(
            scene.changeCount,
            level <= 6
                ? 1
                : level <= 16
                ? 2
                : level <= 19
                ? 3
                : 4,
            reason: 'level $level',
          );
          expect(scene.cellCount, greaterThanOrEqualTo(6));
          expect(scene.changedIndices.length, scene.changeCount);
          expect(scene.before.length, scene.after.length);
          expect(scene.changedIndices.length, lessThan(scene.cellCount));
          expect(scene.includesRelationSwap, level >= 11);
          expect(signatures.add(scene.boardSignature), isTrue);
        }
        expect(
          SpotChangeScenario.forCampaignLevel(1).cellCount,
          lessThan(SpotChangeScenario.forCampaignLevel(20).cellCount),
        );
      },
    );

    test('first 300 practice scenes are unique and campaign-disjoint', () {
      final Set<String> campaign = <String>{
        for (int level = 1; level <= SpotChangeScenario.campaignLevels; level++)
          SpotChangeScenario.forCampaignLevel(level).boardSignature,
      };
      final Set<String> practice = <String>{};
      for (
        int round = 1;
        round <= SpotChangeScenario.uniquePracticeRounds;
        round++
      ) {
        final SpotChangeScenario scene = SpotChangeScenario.forPracticeRound(
          round,
        );
        expect(scene.isPractice, isTrue);
        expect(campaign.contains(scene.boardSignature), isFalse);
        expect(
          practice.add(scene.boardSignature),
          isTrue,
          reason: 'round $round',
        );
      }
    });

    test('factories reject indices outside the content promise', () {
      expect(() => SpotChangeScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => SpotChangeScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => SpotChangeScenario.forPracticeRound(0), throwsRangeError);
      expect(() => SpotChangeScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
