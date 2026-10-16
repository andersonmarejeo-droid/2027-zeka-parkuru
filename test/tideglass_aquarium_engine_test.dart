import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/tideglass_aquarium/aquarium_engine.dart';
import 'package:zeka_parkuru/games/tideglass_aquarium/aquarium_scenario.dart';

void main() {
  test(
    'habitat control catches an incompatible added species and unsafe heat',
    () {
      final AquariumScenario scenario = AquariumScenario.forLevel(1);
      final AquariumEngine engine = AquariumEngine(scenario: scenario);
      for (final MapEntry<AquariumSpecies, int> entry
          in scenario.requiredPopulations.entries) {
        engine.setPopulation(entry.key, entry.value);
      }
      engine.filterTier = 4;
      engine.plants = 4;
      engine.lightTier = 3;
      engine.temperature = scenario.targetTemperature;
      engine.substrate = scenario.substrate;
      engine.aerator = true;
      expect(engine.evaluate().canSubmit, isTrue);

      engine.setPopulation(AquariumSpecies.betta, 1);
      expect(engine.evaluate().compatible, isFalse);
      expect(engine.evaluate().canSubmit, isFalse);
      engine.setPopulation(AquariumSpecies.betta, 0);
      engine.temperature = 18;
      expect(engine.evaluate().temperatureSafe, isFalse);
    },
  );

  test('every authored aquarium can reach stable water and compatibility', () {
    for (int level = 1; level <= AquariumScenario.campaignLevels; level++) {
      final AquariumScenario scenario = AquariumScenario.forLevel(level);
      final AquariumEngine engine = AquariumEngine(scenario: scenario)
        ..filterTier = 4
        ..plants = scenario.minimumPlants
        ..temperature = scenario.targetTemperature
        ..substrate = scenario.substrate
        ..lightTier = 3
        ..aerator = true;
      for (final MapEntry<AquariumSpecies, int> item
          in scenario.requiredPopulations.entries) {
        engine.setPopulation(item.key, item.value);
      }
      final AquariumEvaluation result = engine.evaluate();
      expect(
        result.compatible,
        isTrue,
        reason: 'level $level species compatibility',
      );
      expect(result.volumeSafe, isTrue, reason: 'level $level tank capacity');
      expect(
        result.filterCapacity >= result.waterLoad,
        isTrue,
        reason: 'level $level filtration',
      );
      expect(result.canSubmit, isTrue, reason: 'level $level habitat');
    }
  });
}
