import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/attention_tunnel/attention_tunnel_scenario.dart';

void main() {
  group('Attention Tunnel content contract', () {
    test('campaign adds cards, shuffles, shutters and speed', () {
      final List<AttentionTunnelScenario> campaign = <AttentionTunnelScenario>[
        for (int level = 1; level <= 20; level++)
          AttentionTunnelScenario.forCampaignLevel(level),
      ];
      expect(
        campaign.map((AttentionTunnelScenario scenario) => scenario.cardCount),
        orderedEquals(<int>[
          3,
          3,
          4,
          4,
          4,
          4,
          5,
          5,
          5,
          5,
          6,
          6,
          6,
          7,
          7,
          7,
          8,
          8,
          8,
          9,
        ]),
      );
      expect(
        campaign.map(
          (AttentionTunnelScenario scenario) => scenario.movementCount,
        ),
        orderedEquals(<int>[
          5,
          5,
          7,
          7,
          7,
          7,
          10,
          10,
          10,
          10,
          12,
          12,
          12,
          15,
          15,
          15,
          17,
          17,
          19,
          22,
        ]),
      );
      expect(campaign.first.cardCount, 3);
      expect(campaign[5].laneCount, 4);
      expect(campaign[9].laneCount, 5);
      expect(campaign[12].laneCount, 6);
      expect(campaign[15].laneCount, 7);
      expect(campaign[18].laneCount, 8);
      expect(campaign.last.cardCount, 9);
      expect(campaign.take(6).every((s) => s.shutterCount == 0), isTrue);
      expect(campaign[6].shutterCount, 1);
      expect(campaign[10].shutterCount, 2);
      expect(campaign[16].shutterCount, 3);
      expect(campaign.last.shutterCount, 4);
      expect(campaign.last.mistakeLimit, 1);
      expect(campaign.last.movementIntervalMs, lessThan(500));
      expect(
        campaign
            .map((AttentionTunnelScenario scenario) => scenario.signature)
            .toSet(),
        hasLength(20),
      );
    });

    test('first 300 practice paths are distinct and campaign-disjoint', () {
      final Set<String> campaign = <String>{
        for (int level = 1; level <= 20; level++)
          AttentionTunnelScenario.forCampaignLevel(level).signature,
      };
      final Set<String> practice = <String>{
        for (int round = 1; round <= 300; round++)
          AttentionTunnelScenario.forPracticeRound(round).signature,
      };
      expect(practice, hasLength(300));
      expect(practice.intersection(campaign), isEmpty);
    });

    test('each swap preserves one target and computes its final lane', () {
      for (int level = 1; level <= 20; level++) {
        final AttentionTunnelScenario scenario =
            AttentionTunnelScenario.forCampaignLevel(level);
        final List<int> occupants = List<int>.generate(
          scenario.laneCount,
          (int lane) => lane,
        );
        expect(scenario.targetLanePath.first, scenario.startTargetLane);
        for (
          int moveIndex = 0;
          moveIndex < scenario.movements.length;
          moveIndex++
        ) {
          final TunnelMovement movement = scenario.movements[moveIndex];
          for (final TunnelSwap swap in movement.swaps) {
            expect(swap.firstLane, inInclusiveRange(0, scenario.laneCount - 1));
            expect(
              swap.secondLane,
              inInclusiveRange(0, scenario.laneCount - 1),
            );
            expect(swap.secondLane, isNot(swap.firstLane));
            final int held = occupants[swap.firstLane];
            occupants[swap.firstLane] = occupants[swap.secondLane];
            occupants[swap.secondLane] = held;
          }
          expect(
            occupants.indexOf(scenario.startTargetLane),
            scenario.targetLanePath[moveIndex + 1],
          );
        }
        expect(scenario.targetLanePath.last, scenario.finalTargetLane);
        expect(scenario.actualTargetLaneMoves, greaterThanOrEqualTo(1));
      }
    });

    test('simultaneous late-game crossings use disjoint pairs', () {
      final AttentionTunnelScenario finale =
          AttentionTunnelScenario.forCampaignLevel(20);
      expect(
        finale.movements.any(
          (TunnelMovement movement) => movement.swaps.length == 2,
        ),
        isTrue,
      );
      for (final TunnelMovement movement in finale.movements) {
        if (movement.swaps.length < 2) continue;
        final Set<int> lanes = <int>{
          for (final TunnelSwap swap in movement.swaps) ...<int>[
            swap.firstLane,
            swap.secondLane,
          ],
        };
        expect(lanes, hasLength(4));
      }
    });

    test('scenario factory rejects values outside the 20 / 300 limits', () {
      expect(
        () => AttentionTunnelScenario.forCampaignLevel(0),
        throwsRangeError,
      );
      expect(
        () => AttentionTunnelScenario.forCampaignLevel(21),
        throwsRangeError,
      );
      expect(
        () => AttentionTunnelScenario.forPracticeRound(0),
        throwsRangeError,
      );
      expect(
        () => AttentionTunnelScenario.forPracticeRound(301),
        throwsRangeError,
      );
    });
  });
}
