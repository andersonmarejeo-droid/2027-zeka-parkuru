import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/balloon_catcher/balloon_scenario.dart';

void main() {
  group('Balloon Catcher content certificate', () {
    test('10 campaign levels are unique, feasible and get harder', () {
      final Set<String> signatures = <String>{};
      BalloonScenario? previous;
      for (int level = 1; level <= BalloonScenario.maximumLevels; level++) {
        final BalloonScenario scenario = BalloonScenario.forLevel(level);
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(scenario.spawns.first.lane, 3);
        expect(
          scenario.spawns
              .where(
                (BalloonSpawnSpec spawn) =>
                    spawn.kind == BalloonObjectKind.target,
              )
              .length,
          greaterThanOrEqualTo(scenario.requiredCatches + 3),
        );
        expect(
          scenario.requiredCatches,
          greaterThanOrEqualTo(previous?.requiredCatches ?? 0),
        );
        if (previous != null) {
          expect(scenario.basketWidth, lessThanOrEqualTo(previous.basketWidth));
          expect(
            scenario.spawnInterval,
            lessThanOrEqualTo(previous.spawnInterval),
          );
        }
        if (level == 1) expect(scenario.targetColors, <int>[0]);
        if (level == 7) expect(scenario.targetColors.length, 3);
        if (level == 8) expect(scenario.targetColors.length, 4);
        previous = scenario;
      }
    });

    test('first 300 practice rounds never repeat campaign or each other', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= BalloonScenario.maximumLevels; level++)
          BalloonScenario.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= BalloonScenario.maximumPracticeRounds;
        index++
      ) {
        final BalloonScenario scenario = BalloonScenario.forPracticeRound(
          index,
        );
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'round $index',
        );
      }
    });

    test('out-of-range campaign and practice ids are rejected', () {
      expect(() => BalloonScenario.forLevel(0), throwsRangeError);
      expect(
        () => BalloonScenario.forPracticeRound(
          BalloonScenario.maximumPracticeRounds + 1,
        ),
        throwsRangeError,
      );
    });
  });
}
