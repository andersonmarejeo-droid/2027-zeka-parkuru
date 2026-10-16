import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/dual_task/dual_task_scenario.dart';

void main() {
  group('Dual Task content contract', () {
    test('campaign raises primary load and secondary recall separately', () {
      final List<DualTaskScenario> campaign = <DualTaskScenario>[
        for (int level = 1; level <= 20; level++)
          DualTaskScenario.forCampaignLevel(level),
      ];
      expect(
        campaign.map((DualTaskScenario scenario) => scenario.trialCount),
        orderedEquals(<int>[
          8,
          8,
          10,
          10,
          10,
          10,
          12,
          12,
          12,
          12,
          14,
          14,
          14,
          16,
          16,
          16,
          18,
          18,
          18,
          20,
        ]),
      );
      expect(
        campaign.map((s) => s.memoryLength),
        orderedEquals(<int>[
          2,
          2,
          2,
          3,
          3,
          3,
          3,
          3,
          3,
          3,
          4,
          4,
          4,
          4,
          4,
          4,
          5,
          5,
          5,
          6,
        ]),
      );
      expect(campaign.take(6).every((s) => s.ruleChangeCount == 0), isTrue);
      expect(campaign[6].ruleChangeCount, 1);
      expect(campaign[10].ruleChangeCount, 2);
      expect(campaign[16].ruleChangeCount, 2);
      expect(campaign.last.ruleChangeCount, 3);
      expect(campaign[18].reverseMemoryRecall, isTrue);
      expect(campaign.last.reverseMemoryRecall, isTrue);
      expect(campaign.last.exposureMs, lessThan(500));
      expect(campaign.last.mistakeLimit, 1);
      expect(
        campaign.map((DualTaskScenario scenario) => scenario.signature).toSet(),
        hasLength(20),
      );
    });

    test('300 practice task pairs are unique and campaign-disjoint', () {
      final Set<String> campaign = <String>{
        for (int level = 1; level <= 20; level++)
          DualTaskScenario.forCampaignLevel(level).signature,
      };
      final Set<String> practice = <String>{
        for (int round = 1; round <= 300; round++)
          DualTaskScenario.forPracticeRound(round).signature,
      };
      expect(practice, hasLength(300));
      expect(practice.intersection(campaign), isEmpty);
    });

    test(
      'every primary key follows the visible rule; each cue maps to one digit',
      () {
        for (int level = 1; level <= 20; level++) {
          final DualTaskScenario scenario = DualTaskScenario.forCampaignLevel(
            level,
          );
          expect(scenario.primaryTargetCount, greaterThan(0));
          expect(scenario.primaryTargetCount, lessThan(scenario.trialCount));
          for (int index = 0; index < scenario.trialCount; index++) {
            final DualTaskTrial trial = scenario.trials[index];
            expect(
              trial.isTarget,
              trial.rule.matches(trial.symbol),
              reason: 'Level $level trial $index',
            );
            if (scenario.memoryCueIndices.contains(index)) {
              expect(trial.memoryDigit, isNotNull);
            } else {
              expect(trial.memoryDigit, isNull);
            }
          }
          expect(
            scenario.memoryDigits.toSet(),
            hasLength(scenario.memoryLength),
          );
        }
      },
    );

    test('scenario factory rejects values outside the 20 / 300 limits', () {
      expect(() => DualTaskScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => DualTaskScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => DualTaskScenario.forPracticeRound(0), throwsRangeError);
      expect(() => DualTaskScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
