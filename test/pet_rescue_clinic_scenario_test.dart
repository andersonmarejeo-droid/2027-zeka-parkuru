import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/pet_rescue_clinic/pet_case_scenario.dart';

void main() {
  test('20 authored care visits expand from short sequence to seven steps', () {
    final List<PetCaseScenario> cases = List<PetCaseScenario>.generate(
      PetCaseScenario.campaignLevels,
      (int i) => PetCaseScenario.forLevel(i + 1),
    );
    expect(cases, hasLength(20));
    expect(cases.first.steps.length, 3);
    expect(cases[5].steps.length, 4);
    expect(cases[9].steps.length, 5);
    expect(cases[14].steps.length, 6);
    expect(cases.last.steps.length, 7);
    expect(
      cases.map((PetCaseScenario s) => s.planSignature).toSet(),
      hasLength(20),
    );
  });

  test('300 reproducible practice visit plans are structurally unique', () {
    final List<PetCaseScenario> first = List<PetCaseScenario>.generate(
      PetCaseScenario.practiceCases,
      (int i) => PetCaseScenario.forPractice(i + 1),
    );
    final List<PetCaseScenario> second = List<PetCaseScenario>.generate(
      PetCaseScenario.practiceCases,
      (int i) => PetCaseScenario.forPractice(i + 1),
    );
    expect(
      first.map((PetCaseScenario s) => s.planSignature).toSet(),
      hasLength(300),
    );
    expect(
      first.map((PetCaseScenario s) => s.signature),
      second.map((PetCaseScenario s) => s.signature),
    );
  });
}
