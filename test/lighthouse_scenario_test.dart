import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/lighthouse_defense/lighthouse_scenario.dart';

void main() {
  test('20 coastal watches introduce wave, armour and boss pressure', () {
    final List<LighthouseScenario> scenarios =
        List<LighthouseScenario>.generate(
          LighthouseScenario.campaignLevels,
          (int index) => LighthouseScenario.forLevel(index + 1),
        );
    expect(scenarios.first.waves, hasLength(4));
    expect(scenarios.last.waves, hasLength(8));
    expect(
      scenarios.first.startingLives,
      greaterThan(scenarios.last.startingLives),
    );
    expect(
      scenarios[2].waves
          .expand((LighthouseWaveSpec wave) => wave.enemies)
          .any(
            (LighthouseEnemySpec e) => e.kind == LighthouseEnemyKind.armored,
          ),
      isTrue,
    );
    expect(scenarios[7].waves.last.enemies.last.kind, LighthouseEnemyKind.boss);
    expect(
      scenarios.last.waves.last.enemies.last.health,
      greaterThan(scenarios[7].waves.last.enemies.last.health),
    );
  });

  test(
    '300 practice routes and wave manifests have distinct stable signatures',
    () {
      final Set<String> signatures = <String>{};
      for (int index = 1; index <= LighthouseScenario.practiceMaps; index++) {
        final LighthouseScenario map = LighthouseScenario.forPracticeMap(index);
        expect(
          map.signature,
          LighthouseScenario.forPracticeMap(index).signature,
        );
        expect(
          signatures.add(map.signature),
          isTrue,
          reason: 'map $index repeated',
        );
        expect(
          map.signature,
          isNot(LighthouseScenario.forLevel(map.level).signature),
        );
        expect(map.path, hasLength(8));
        expect(map.alternatePath, hasLength(8));
        expect(map.pads, hasLength(6));
      }
      expect(signatures, hasLength(300));
      expect(
        LighthouseScenario.forLevel(20).waves
            .expand((LighthouseWaveSpec wave) => wave.enemies)
            .map((LighthouseEnemySpec enemy) => enemy.routeBranch)
            .toSet(),
        containsAll(<int>{0, 1}),
      );
    },
  );

  test('scenario factories reject indexes outside their published ranges', () {
    expect(() => LighthouseScenario.forLevel(0), throwsRangeError);
    expect(() => LighthouseScenario.forLevel(21), throwsRangeError);
    expect(() => LighthouseScenario.forPracticeMap(0), throwsRangeError);
    expect(() => LighthouseScenario.forPracticeMap(301), throwsRangeError);
  });
}
