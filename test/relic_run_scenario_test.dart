import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/relic_run/relic_run_scenario.dart';

void main() {
  test('20 expeditions ramp enemy kits, hazards and guardian pressure', () {
    final List<RelicRunScenario> scenarios = List<RelicRunScenario>.generate(
      RelicRunScenario.campaignLevels,
      (int index) => RelicRunScenario.forLevel(index + 1),
    );
    expect(
      scenarios,
      everyElement(
        predicate<RelicRunScenario>(
          (RelicRunScenario s) => s.rooms.length == 3,
        ),
      ),
    );
    expect(scenarios.first.rooms.first.foes, hasLength(2));
    expect(scenarios.last.rooms.last.isGuardianRoom, isTrue);
    expect(scenarios.last.rooms.last.foes.last.kind, RelicRunFoeKind.guardian);
    expect(
      scenarios.last.rooms.last.foes.last.health,
      greaterThan(scenarios.first.rooms.first.foes.first.health),
    );
    expect(
      scenarios.last.rooms.last.traps.length,
      greaterThan(scenarios.first.rooms.first.traps.length),
    );
    expect(
      scenarios.last.rooms.last.walls.length,
      greaterThan(scenarios.first.rooms.first.walls.length),
    );
  });

  test(
    '300 practice expeditions are reproducible and distinct from campaign',
    () {
      final Set<String> signatures = <String>{};
      for (int index = 1; index <= RelicRunScenario.practiceRuns; index++) {
        final RelicRunScenario scenario = RelicRunScenario.forPracticeRun(
          index,
        );
        expect(
          scenario.signature,
          RelicRunScenario.forPracticeRun(index).signature,
        );
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'practice run $index repeated',
        );
        expect(
          scenario.signature,
          isNot(RelicRunScenario.forLevel(scenario.level).signature),
        );
        expect(scenario.rooms, hasLength(3));
        for (final RelicRunRoom room in scenario.rooms) {
          expect(room.walls, isNot(contains((x: 1, y: 4))));
        }
      }
      expect(signatures, hasLength(300));
    },
  );

  test('scenario factories enforce the published 20 and 300 limits', () {
    expect(() => RelicRunScenario.forLevel(0), throwsRangeError);
    expect(() => RelicRunScenario.forLevel(21), throwsRangeError);
    expect(() => RelicRunScenario.forPracticeRun(0), throwsRangeError);
    expect(() => RelicRunScenario.forPracticeRun(301), throwsRangeError);
  });
}
