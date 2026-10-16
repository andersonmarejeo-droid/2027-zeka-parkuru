import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/focus_filter/focus_filter_scenario.dart';

void main() {
  group('Focus Filter content contract', () {
    test(
      '20 campaign rules advance from single features to sequence memory',
      () {
        final Set<String> signatures = <String>{};
        for (
          int level = 1;
          level <= FocusFilterScenario.campaignLevels;
          level++
        ) {
          final FocusFilterScenario scenario =
              FocusFilterScenario.forCampaignLevel(level);
          expect(scenario.stage, level);
          expect(scenario.stimuli.length, greaterThanOrEqualTo(12));
          expect(scenario.targetCount, greaterThan(0), reason: 'level $level');
          expect(
            scenario.targetCount,
            lessThan(scenario.stimuli.length),
            reason: 'level $level must include no-go signals',
          );
          expect(signatures.add(scenario.boardSignature), isTrue);

          for (int index = 0; index < scenario.stimuli.length; index++) {
            final FocusStimulus stimulus = scenario.stimuli[index];
            expect(
              stimulus.shapeIndex,
              inInclusiveRange(0, FocusFilterScenario.shapeCount - 1),
              reason: 'level $level shape index $index',
            );
            switch (scenario.rule) {
              case FocusFilterRule.holdShape:
                expect(
                  stimulus.isTarget,
                  stimulus.shapeIndex == scenario.targetShape,
                );
              case FocusFilterRule.holdColor:
                expect(
                  stimulus.isTarget,
                  stimulus.colorIndex == scenario.targetColor,
                );
              case FocusFilterRule.shapeAndColor:
                expect(
                  stimulus.isTarget,
                  stimulus.shapeIndex == scenario.targetShape &&
                      stimulus.colorIndex == scenario.targetColor,
                );
              case FocusFilterRule.shiftingShape:
                final int target = index < scenario.stimuli.length ~/ 2
                    ? scenario.targetShape
                    : scenario.secondTargetShape;
                expect(stimulus.isTarget, stimulus.shapeIndex == target);
              case FocusFilterRule.rareSignal:
                expect(
                  stimulus.isTarget,
                  stimulus.hasRing &&
                      stimulus.colorIndex == scenario.targetColor,
                );
              case FocusFilterRule.repeatShape:
                final bool repeated =
                    index > 0 &&
                    stimulus.shapeIndex ==
                        scenario.stimuli[index - 1].shapeIndex;
                expect(stimulus.isTarget, repeated);
            }
          }
        }

        expect(
          FocusFilterScenario.forCampaignLevel(1).stimuli.length,
          lessThan(FocusFilterScenario.forCampaignLevel(20).stimuli.length),
        );
        expect(
          FocusFilterScenario.forCampaignLevel(20).rule,
          FocusFilterRule.repeatShape,
        );
      },
    );

    test(
      'first 300 practice streams are distinct from each other and campaign',
      () {
        final Set<String> campaign = <String>{
          for (
            int level = 1;
            level <= FocusFilterScenario.campaignLevels;
            level++
          )
            FocusFilterScenario.forCampaignLevel(level).boardSignature,
        };
        final Set<String> practice = <String>{};
        for (
          int round = 1;
          round <= FocusFilterScenario.uniquePracticeRounds;
          round++
        ) {
          final FocusFilterScenario scenario =
              FocusFilterScenario.forPracticeRound(round);
          expect(scenario.isPractice, isTrue);
          expect(campaign.contains(scenario.boardSignature), isFalse);
          expect(
            practice.add(scenario.boardSignature),
            isTrue,
            reason: 'round $round',
          );
        }
      },
    );

    test('factories reject indices outside the content promise', () {
      expect(() => FocusFilterScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => FocusFilterScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => FocusFilterScenario.forPracticeRound(0), throwsRangeError);
      expect(() => FocusFilterScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
