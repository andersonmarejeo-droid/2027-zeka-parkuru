import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/tideglass_aquarium/aquarium_scenario.dart';

void main() {
  test('20 aquarium briefs progressively layer habitat constraints', () {
    final List<AquariumScenario> levels = List<AquariumScenario>.generate(
      AquariumScenario.campaignLevels,
      (int index) => AquariumScenario.forLevel(index + 1),
    );
    expect(levels, hasLength(20));
    expect(levels[0].requiredPopulations.length, 2);
    expect(levels[10].difficulty, 11);
    expect(levels[16].aeratorRequired, isTrue);
    expect(levels[19].minimumFilterTier, 3);
    expect(
      levels.map((AquariumScenario s) => s.signature).toSet(),
      hasLength(20),
    );
  });

  test('300 practice tanks vary in actual habitat constraints', () {
    final List<AquariumScenario> first = List<AquariumScenario>.generate(
      AquariumScenario.practiceTankChallenges,
      (int index) => AquariumScenario.forPractice(index + 1),
    );
    final List<AquariumScenario> second = List<AquariumScenario>.generate(
      AquariumScenario.practiceTankChallenges,
      (int index) => AquariumScenario.forPractice(index + 1),
    );
    expect(
      first.map((AquariumScenario s) => s.layoutSignature).toSet(),
      hasLength(300),
    );
    expect(
      first.map((AquariumScenario s) => s.signature),
      second.map((AquariumScenario s) => s.signature),
    );
  });
}
