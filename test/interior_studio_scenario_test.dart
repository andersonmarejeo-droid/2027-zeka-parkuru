import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/interior_studio/interior_scenario.dart';

void main() {
  test('20 authored briefs rise in scope and keep a valid budget', () {
    final List<InteriorScenario> levels = List<InteriorScenario>.generate(
      InteriorScenario.campaignLevels,
      (int index) => InteriorScenario.forLevel(index + 1),
    );

    expect(levels, hasLength(20));
    expect(levels.first.requirements.length, 3);
    expect(levels[5].requirements.length, 4);
    expect(levels[9].requirements.length, 5);
    expect(levels[14].requirements.length, 6);
    expect(levels.last.requirements.length, 7);
    for (final InteriorScenario scenario in levels) {
      final int requiredCost = scenario.requirements.fold<int>(
        0,
        (int sum, InteriorFurniture item) => sum + item.cost,
      );
      expect(scenario.budget, greaterThan(requiredCost));
      expect(scenario.width, greaterThanOrEqualTo(7));
      expect(scenario.height, greaterThanOrEqualTo(7));
    }
  });

  test('300 deterministic practice briefs have distinct signatures', () {
    final List<InteriorScenario> first = List<InteriorScenario>.generate(
      InteriorScenario.practiceScenarios,
      (int index) => InteriorScenario.forPractice(index + 1),
    );
    final List<InteriorScenario> second = List<InteriorScenario>.generate(
      InteriorScenario.practiceScenarios,
      (int index) => InteriorScenario.forPractice(index + 1),
    );

    expect(
      first.map((InteriorScenario s) => s.signature).toSet(),
      hasLength(300),
    );
    expect(
      first.map((InteriorScenario s) => s.layoutSignature).toSet(),
      hasLength(300),
    );
    expect(
      first.map((InteriorScenario s) => s.signature),
      second.map((InteriorScenario s) => s.signature),
    );
    expect(
      first.every(
        (InteriorScenario s) =>
            s.budget >=
            s.requirements.fold<int>(
              20,
              (int sum, InteriorFurniture item) => sum + item.cost,
            ),
      ),
      isTrue,
    );
  });
}
