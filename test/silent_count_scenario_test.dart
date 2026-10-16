import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/silent_count/silent_count_scenario.dart';

void main() {
  group('Silent Count content contract', () {
    test('20-level campaign expands the hidden inventory and gate rules', () {
      final List<SilentCountScenario> campaign = <SilentCountScenario>[
        for (int level = 1; level <= 20; level++)
          SilentCountScenario.forCampaignLevel(level),
      ];
      expect(
        campaign.map((SilentCountScenario scenario) => scenario.eventCount),
        orderedEquals(<int>[
          7,
          7,
          8,
          8,
          9,
          9,
          11,
          12,
          13,
          14,
          15,
          15,
          15,
          17,
          17,
          17,
          17,
          18,
          19,
          20,
        ]),
      );
      expect(campaign.first.categoryCount, 2);
      expect(campaign[5].categoryCount, 3);
      expect(campaign[10].categoryCount, 4);
      expect(campaign.last.categoryCount, 5);
      expect(campaign.take(6).every((s) => s.ruleChangeCount == 0), isTrue);
      expect(campaign[6].ruleChangeCount, 1);
      expect(campaign[12].ruleChangeCount, 2);
      expect(campaign.last.ruleChangeCount, 3);
      expect(campaign.last.mistakeLimit, 1);
      expect(
        campaign
            .map((SilentCountScenario scenario) => scenario.signature)
            .toSet(),
        hasLength(20),
      );
    });

    test('300 practice inventories are unique and disjoint from campaign', () {
      final Set<String> campaign = <String>{
        for (int level = 1; level <= 20; level++)
          SilentCountScenario.forCampaignLevel(level).signature,
      };
      final Set<String> practice = <String>{
        for (int round = 1; round <= 300; round++)
          SilentCountScenario.forPracticeRound(round).signature,
      };
      expect(practice, hasLength(300));
      expect(practice.intersection(campaign), isEmpty);
    });

    test('all hidden counts follow the current gate and stay in range', () {
      for (int level = 1; level <= 20; level++) {
        final SilentCountScenario scenario =
            SilentCountScenario.forCampaignLevel(level);
        final List<int> counts = List<int>.of(scenario.initialCounts);
        bool reversed = false;
        for (int index = 0; index < scenario.events.length; index++) {
          if (scenario.ruleChangeBeforeEvent.contains(index)) {
            reversed = !reversed;
          }
          final SilentCountEvent event = scenario.events[index];
          expect(
            event.reversed,
            reversed,
            reason: 'Level $level, event $index',
          );
          counts[event.category] += event.adds ? 1 : -1;
          expect(counts[event.category], inInclusiveRange(0, 9));
        }
        expect(counts, scenario.finalCounts, reason: 'Level $level');
        expect(
          scenario.queryOrder.toSet(),
          Set<int>.from(List<int>.generate(scenario.categoryCount, (i) => i)),
        );
      }
    });

    test('scenario factory rejects values outside the 20 / 300 limits', () {
      expect(() => SilentCountScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => SilentCountScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => SilentCountScenario.forPracticeRound(0), throwsRangeError);
      expect(() => SilentCountScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
