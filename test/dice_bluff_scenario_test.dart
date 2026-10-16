import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/dice_bluff_arena/dice_bluff_scenario.dart';

void main() {
  test('20 hands increase from three to seven dice and add wild face late', () {
    final List<DiceBluffScenario> campaign = <DiceBluffScenario>[
      for (int level = 1; level <= 20; level++)
        DiceBluffScenario.forLevel(level),
    ];
    expect(campaign.first.diceCount, 3);
    expect(campaign.last.diceCount, 7);
    expect(campaign[7].wildFace, isNull);
    expect(campaign[8].wildFace, campaign[8].faceCount);
    expect(campaign.map((scenario) => scenario.arenaId).toSet(), hasLength(20));
    for (final DiceBluffScenario scenario in campaign) {
      expect(scenario.humanDice, hasLength(scenario.diceCount));
      expect(scenario.opponentDice, hasLength(scenario.diceCount));
      expect(
        scenario.humanDice.every(
          (face) => face >= 1 && face <= scenario.faceCount,
        ),
        isTrue,
      );
      expect(
        scenario.opponentDice.every(
          (face) => face >= 1 && face <= scenario.faceCount,
        ),
        isTrue,
      );
    }
  });

  test('300 practice hands are repeatable and structurally distinct', () {
    final List<DiceBluffScenario> hands = <DiceBluffScenario>[
      for (int index = 1; index <= 300; index++)
        DiceBluffScenario.forPractice(index),
    ];
    expect(
      hands.map((scenario) => scenario.signature()).toSet(),
      hasLength(300),
    );
    for (int index = 1; index <= 300; index++) {
      expect(
        DiceBluffScenario.forPractice(index).signature(),
        hands[index - 1].signature(),
      );
    }
  });

  test('custom hands preserve dice rules and reject malformed faces', () {
    final DiceBluffScenario scenario = DiceBluffScenario.forLevel(2);
    final DiceBluffScenario changed = scenario.withDiceHands(
      humanDice: List<int>.filled(scenario.diceCount, 1),
      opponentDice: List<int>.filled(scenario.diceCount, scenario.faceCount),
    );
    expect(changed.arenaId, scenario.arenaId);
    expect(changed.humanDice, everyElement(1));
    expect(changed.opponentDice, everyElement(scenario.faceCount));
    expect(
      () => scenario.withDiceHands(
        humanDice: <int>[1],
        opponentDice: scenario.opponentDice,
      ),
      throwsArgumentError,
    );
    expect(
      () => scenario.withDiceHands(
        humanDice: List<int>.filled(scenario.diceCount, 99),
        opponentDice: scenario.opponentDice,
      ),
      throwsRangeError,
    );
  });
}
