import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mini_golf_route/mini_golf_scenario.dart';

void main() {
  group('Mini Golf course certificate', () {
    test('10 holes tighten par, gate opening, wind and surface control', () {
      final Set<String> signatures = <String>{};
      MiniGolfScenario? previous;
      for (int level = 1; level <= MiniGolfScenario.maximumLevels; level++) {
        final MiniGolfScenario scenario = MiniGolfScenario.forLevel(level);
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(scenario.strokeLimit, greaterThanOrEqualTo(scenario.par + 2));
        expect(scenario.grassDrag, lessThan(scenario.sandDrag));
        expect(scenario.gateWidth, greaterThanOrEqualTo(.18));
        expect(scenario.hole.x, inInclusiveRange(.38, .62));
        expect(
          scenario.sand.length,
          lessThanOrEqualTo(level - 2 < 0 ? 0 : level - 2),
        );
        if (previous != null) {
          expect(scenario.gateWidth, lessThan(previous.gateWidth));
          expect(
            scenario.windX.abs() + scenario.windY.abs(),
            greaterThanOrEqualTo(previous.windX.abs() + previous.windY.abs()),
          );
        }
        if (level == 10) {
          expect(scenario.par, 3);
          expect(scenario.strokeLimit, 5);
          expect(scenario.gateAmplitude, greaterThan(.1));
          expect(scenario.bumpers, isNotEmpty);
        }
        previous = scenario;
      }
    });

    test('first 300 practice courses differ from campaign and each other', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= MiniGolfScenario.maximumLevels; level++)
          MiniGolfScenario.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= MiniGolfScenario.maximumPracticeRounds;
        index++
      ) {
        expect(
          signatures.add(MiniGolfScenario.forPracticeRound(index).signature),
          isTrue,
          reason: 'golf course $index',
        );
      }
    });

    test('invalid levels and practice indices are rejected', () {
      expect(() => MiniGolfScenario.forLevel(0), throwsRangeError);
      expect(() => MiniGolfScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
