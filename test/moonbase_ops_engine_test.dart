import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/moonbase_ops/moonbase_engine.dart';
import 'package:zeka_parkuru/games/moonbase_ops/moonbase_scenario.dart';

void main() {
  test('core, rock, collision and budget prevent invalid installations', () {
    final MoonbaseScenario scenario = MoonbaseScenario.forLevel(1);
    final MoonbaseEngine engine = MoonbaseEngine(scenario: scenario);
    expect(
      engine.place(MoonModule.habitat, scenario.core).reason,
      'core_reserved',
    );
    expect(
      engine.place(MoonModule.habitat, scenario.rocks.first).reason,
      'rock',
    );
    const MoonCell free = MoonCell(2, 2);
    expect(engine.place(MoonModule.habitat, free).accepted, isTrue);
    expect(engine.place(MoonModule.solarArray, free).reason, 'occupied');

    final MoonbaseScenario tiny = MoonbaseScenario(
      level: 1,
      seed: 1,
      size: 7,
      crew: 1,
      powerDemand: 1,
      oxygenDemand: 1,
      heatLimit: 8,
      hazard: MoonHazard.calm,
      requiredModules: const <MoonModule>[],
      rocks: const <MoonCell>[],
      budget: 1,
    );
    expect(
      MoonbaseEngine(scenario: tiny)
          .place(MoonModule.solarArray, const MoonCell(1, 1))
          .reason,
      'over_budget',
    );
  });

  test(
    'a disconnected outpost cannot launch until every module joins the core',
    () {
      final MoonbaseScenario scenario = MoonbaseScenario(
        level: 1,
        seed: 2,
        size: 7,
        crew: 1,
        powerDemand: 1,
        oxygenDemand: 1,
        heatLimit: 99,
        hazard: MoonHazard.calm,
        requiredModules: const <MoonModule>[],
        rocks: const <MoonCell>[],
        budget: 200,
      );
      final MoonbaseEngine engine = MoonbaseEngine(scenario: scenario);
      expect(
        engine.place(MoonModule.solarArray, const MoonCell(0, 0)).accepted,
        isTrue,
      );
      expect(
        engine.place(MoonModule.greenhouse, const MoonCell(3, 2)).accepted,
        isTrue,
      );
      expect(engine.evaluate().canLaunch, isFalse);
      expect(engine.removeAt(const MoonCell(0, 0)).accepted, isTrue);
      expect(
        engine.place(MoonModule.solarArray, const MoonCell(2, 3)).accepted,
        isTrue,
      );
      expect(engine.evaluate().canLaunch, isTrue);
    },
  );

  test('undo and redo restore independent module layout', () {
    final MoonbaseScenario scenario = MoonbaseScenario.forLevel(1);
    final MoonbaseEngine engine = MoonbaseEngine(scenario: scenario);
    final MoonCell cell = MoonCell(scenario.core.x + 1, scenario.core.y);
    expect(engine.place(MoonModule.solarArray, cell).accepted, isTrue);
    expect(engine.undo(), isTrue);
    expect(engine.placements, isEmpty);
    expect(engine.redo(), isTrue);
    expect(engine.placements.single.cell, cell);
  });
}
