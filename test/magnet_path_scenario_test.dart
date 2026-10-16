import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/magnet_path/magnet_path_scenario.dart';

void main() {
  group('Magnet Path content certificate', () {
    test('10 courses gain gates, shielding and precision', () {
      final Set<String> signatures = <String>{};
      MagnetPathScenario? previous;
      for (int level = 1; level <= MagnetPathScenario.maximumLevels; level++) {
        final MagnetPathScenario scenario = MagnetPathScenario.forLevel(level);
        expect(signatures.add(scenario.signature), isTrue, reason: 'level $level');
        expect(scenario.gates, hasLength(2 + level ~/ 2));
        expect(scenario.gateRadius, greaterThanOrEqualTo(.05));
        expect(scenario.baffles.length, lessThanOrEqualTo(level - 2 < 0 ? 0 : level - 2));
        expect(scenario.gates.every((MagnetPoint gate) => gate.x >= .22 && gate.x <= .84 && gate.y >= .12 && gate.y <= .84), isTrue);
        if (previous != null) {
          expect(scenario.gateRadius, lessThan(previous.gateRadius));
          expect(scenario.speedLimit, greaterThan(previous.speedLimit));
          expect(scenario.gates.length, greaterThanOrEqualTo(previous.gates.length));
        }
        if (level >= 9) expect(scenario.collisionLimit, 3);
        previous = scenario;
      }
    });

    test('first 300 practice routes never repeat campaign or each other', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= MagnetPathScenario.maximumLevels; level++)
          MagnetPathScenario.forLevel(level).signature,
      };
      for (int index = 1; index <= MagnetPathScenario.maximumPracticeRounds; index++) {
        expect(
          signatures.add(MagnetPathScenario.forPracticeRound(index).signature),
          isTrue,
          reason: 'magnetic course $index',
        );
      }
    });

    test('invalid level and practice index are rejected', () {
      expect(() => MagnetPathScenario.forLevel(11), throwsRangeError);
      expect(() => MagnetPathScenario.forPracticeRound(301), throwsRangeError);
    });
  });
}
