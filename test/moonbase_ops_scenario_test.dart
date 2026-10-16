import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/moonbase_ops/moonbase_engine.dart';
import 'package:zeka_parkuru/games/moonbase_ops/moonbase_scenario.dart';

void main() {
  test('20 missions increase crew and include survivable hazard systems', () {
    final List<MoonbaseScenario> missions = List<MoonbaseScenario>.generate(
      MoonbaseScenario.campaignLevels,
      (int index) => MoonbaseScenario.forLevel(index + 1),
    );
    expect(missions, hasLength(20));
    expect(missions.first.crew, lessThan(missions.last.crew));
    expect(missions[6].requiredModules, contains(MoonModule.commRelay));
    expect(missions[8].hazard, MoonHazard.meteorShower);
    expect(missions[8].requiredModules, contains(MoonModule.shield));
    expect(missions[9].hazard, MoonHazard.solarEclipse);
    expect(missions[9].requiredModules, contains(MoonModule.battery));
    expect(missions.last.size, 8);
    for (final MoonbaseScenario scenario in missions) {
      final MoonbaseEvaluation result = _solve(scenario).evaluate();
      expect(
        result.canLaunch,
        isTrue,
        reason: 'mission ${scenario.level}: $result',
      );
      expect(result.requiredPlaced, scenario.requiredModules.length);
      expect(result.connectedCount, result.moduleCount);
      expect(result.powerAvailable, greaterThanOrEqualTo(result.powerDemand));
      expect(result.oxygenAvailable, greaterThanOrEqualTo(result.oxygenDemand));
      expect(
        result.heatLoad,
        lessThanOrEqualTo(scenario.heatLimit + result.cooling),
      );
      expect(result.budgetUsed, lessThanOrEqualTo(scenario.budget));
    }
  });

  test(
    '300 practice outposts are unique and each has a valid build strategy',
    () {
      final List<MoonbaseScenario> missions = List<MoonbaseScenario>.generate(
        MoonbaseScenario.practiceMissions,
        (int index) => MoonbaseScenario.forPractice(index + 1),
      );
      expect(
        missions.map((MoonbaseScenario m) => m.signature).toSet(),
        hasLength(300),
      );
      expect(
        missions.map((MoonbaseScenario m) => m.layoutSignature).toSet(),
        hasLength(300),
      );
      for (final MoonbaseScenario scenario in missions) {
        expect(
          _solve(scenario).evaluate().canLaunch,
          isTrue,
          reason: '${scenario.seed}',
        );
      }
    },
  );
}

MoonbaseEngine _solve(MoonbaseScenario scenario) {
  final MoonbaseEngine engine = MoonbaseEngine(scenario: scenario);
  final List<MoonCell> candidates =
      <MoonCell>[
        for (int y = 0; y < scenario.size; y++)
          for (int x = 0; x < scenario.size; x++) MoonCell(x, y),
      ]..sort((MoonCell a, MoonCell b) {
        final int da =
            (a.x - scenario.core.x).abs() + (a.y - scenario.core.y).abs();
        final int db =
            (b.x - scenario.core.x).abs() + (b.y - scenario.core.y).abs();
        return da.compareTo(db);
      });
  int placed = 0;
  for (final MoonCell cell in candidates) {
    if (placed >= scenario.requiredModules.length) break;
    if (cell == scenario.core || scenario.rocks.contains(cell)) continue;
    final MoonbaseActionResult result = engine.place(
      scenario.requiredModules[placed],
      cell,
    );
    expect(
      result.accepted,
      isTrue,
      reason: 'module $placed at ${cell.signature}',
    );
    placed++;
  }
  expect(placed, scenario.requiredModules.length);
  return engine;
}
