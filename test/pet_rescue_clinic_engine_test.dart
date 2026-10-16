import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/pet_rescue_clinic/pet_care_engine.dart';
import 'package:zeka_parkuru/games/pet_rescue_clinic/pet_case_scenario.dart';

void main() {
  test('wrong station is recoverable and does not advance the visit', () {
    final PetCareEngine engine = PetCareEngine(
      scenario: PetCaseScenario.forLevel(1),
    );
    final CareStep first = engine.currentStep!;
    final CareStep wrong = CareStep.values.firstWhere(
      (CareStep s) => s != first,
    );
    expect(engine.choose(wrong).accepted, isFalse);
    expect(engine.nextStep, 0);
    expect(engine.mistakes, 1);
    expect(engine.choose(first).accepted, isTrue);
    expect(engine.nextStep, 1);
    expect(engine.stars, 2);
  });

  test('all 20 authored case sequences complete in order', () {
    for (int level = 1; level <= PetCaseScenario.campaignLevels; level++) {
      final PetCareEngine engine = PetCareEngine(
        scenario: PetCaseScenario.forLevel(level),
      );
      for (final CareStep step in engine.scenario.steps) {
        expect(engine.choose(step).accepted, isTrue, reason: 'level $level');
      }
      expect(engine.completed, isTrue, reason: 'level $level');
      expect(engine.stars, 3);
      expect(engine.score, engine.scenario.steps.length * 100);
    }
  });
}
