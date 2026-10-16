import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/deckforge_duel/deckforge_scenario.dart';

void main() {
  test('campaign has twenty distinct arenas and steadily tougher rivals', () {
    final List<DeckforgeScenario> scenarios = List<DeckforgeScenario>.generate(
      DeckforgeScenario.campaignLevels,
      (int index) => DeckforgeScenario.forLevel(index + 1),
    );
    expect(
      scenarios.map((DeckforgeScenario item) => item.arenaId).toSet(),
      hasLength(20),
    );
    expect(
      scenarios.map((DeckforgeScenario item) => item.signature()).toSet(),
      hasLength(20),
    );
    expect(scenarios.first.opponentHealth, 35);
    expect(scenarios.last.opponentHealth, 54);
    expect(
      scenarios
          .take(2)
          .every((DeckforgeScenario item) => item.opponentEnergyCap == 1),
      isTrue,
    );
    expect(
      scenarios
          .skip(2)
          .take(4)
          .every((DeckforgeScenario item) => item.opponentEnergyCap == 2),
      isTrue,
    );
    expect(
      scenarios
          .skip(6)
          .every((DeckforgeScenario item) => item.opponentEnergyCap == 3),
      isTrue,
    );
    expect(
      scenarios.every((DeckforgeScenario item) => item.playerDeck.length == 18),
      isTrue,
    );
    expect(
      scenarios.every(
        (DeckforgeScenario item) => item.opponentDeck.length == 18,
      ),
      isTrue,
    );
  });

  test('all 300 deterministic practice battles are structurally unique', () {
    final List<DeckforgeScenario> firstPass = List<DeckforgeScenario>.generate(
      DeckforgeScenario.practiceBattles,
      (int index) => DeckforgeScenario.forPractice(index + 1),
    );
    final List<DeckforgeScenario> secondPass = List<DeckforgeScenario>.generate(
      DeckforgeScenario.practiceBattles,
      (int index) => DeckforgeScenario.forPractice(index + 1),
    );
    expect(
      firstPass.map((DeckforgeScenario item) => item.signature()).toSet(),
      hasLength(300),
    );
    expect(
      firstPass.map((DeckforgeScenario item) => item.signature()).toList(),
      secondPass.map((DeckforgeScenario item) => item.signature()).toList(),
    );
  });

  test('scenario indices reject values outside their authored ranges', () {
    expect(() => DeckforgeScenario.forLevel(0), throwsRangeError);
    expect(() => DeckforgeScenario.forLevel(21), throwsRangeError);
    expect(() => DeckforgeScenario.forPractice(0), throwsRangeError);
    expect(() => DeckforgeScenario.forPractice(301), throwsRangeError);
  });
}
