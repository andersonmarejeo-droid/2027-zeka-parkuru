import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/dice_bluff_arena/dice_bluff_engine.dart';
import 'package:zeka_parkuru/games/dice_bluff_arena/dice_bluff_scenario.dart';

DiceBluffEngine _openForBidding(
  DiceBluffScenario scenario, {
  required DiceBluffMode mode,
  required int firstBidder,
}) {
  final DiceBluffEngine engine = DiceBluffEngine(
    scenario: scenario,
    mode: mode,
    firstBidder: firstBidder,
  );
  engine.openPrivateRoll();
  engine.hideRollAndPass();
  if (mode == DiceBluffMode.localDuel) {
    engine.openPrivateRoll();
    engine.hideRollAndPass();
  }
  return engine;
}

void main() {
  test(
    'private hands are visible only in their reveal and after a challenge',
    () {
      final DiceBluffScenario scenario = DiceBluffScenario.forLevel(9);
      final DiceBluffEngine engine = DiceBluffEngine(
        scenario: scenario,
        mode: DiceBluffMode.localDuel,
        firstBidder: 0,
      );
      expect(engine.visibleDice, isEmpty);
      expect(engine.openPrivateRoll(), isTrue);
      expect(engine.visibleDice, scenario.humanDice);
      expect(engine.hideRollAndPass(), isTrue);
      expect(engine.visibleDice, isEmpty);
      expect(engine.openPrivateRoll(), isTrue);
      expect(engine.visibleDice, scenario.opponentDice);
      expect(engine.hideRollAndPass(), isTrue);
      expect(engine.phase, DiceBluffPhase.bidding);
      expect(engine.revealedHumanDice, isEmpty);
      expect(engine.revealedOpponentDice, isEmpty);
    },
  );

  test('bid order rejects a lower count or face and accepts a true raise', () {
    final DiceBluffScenario scenario = DiceBluffScenario.forLevel(12);
    final DiceBluffEngine engine = _openForBidding(
      scenario,
      mode: DiceBluffMode.localDuel,
      firstBidder: 0,
    );
    expect(
      engine.raiseBid(player: 0, count: 2, face: 3),
      DiceBluffAction.raised,
    );
    expect(
      engine.raiseBid(player: 1, count: 1, face: 6),
      DiceBluffAction.invalid,
    );
    expect(
      engine.raiseBid(player: 1, count: 2, face: 3),
      DiceBluffAction.invalid,
    );
    expect(
      engine.raiseBid(player: 1, count: 2, face: 4),
      DiceBluffAction.raised,
    );
    expect(engine.currentBid!.face, 4);
  });

  test(
    'wild star contributes to other faces; challenge reveals both hands',
    () {
      final DiceBluffScenario base = DiceBluffScenario.forLevel(12);
      final DiceBluffScenario scenario = base.withDiceHands(
        humanDice: <int>[
          base.wildFace!,
          ...List<int>.filled(base.diceCount - 1, 2),
        ],
        opponentDice: List<int>.filled(base.diceCount, 3),
      );
      final DiceBluffEngine engine = _openForBidding(
        scenario,
        mode: DiceBluffMode.localDuel,
        firstBidder: 0,
      );
      expect(
        engine.raiseBid(player: 0, count: 5, face: 2),
        DiceBluffAction.raised,
      );
      expect(engine.challenge(player: 1), DiceBluffAction.challenged);
      expect(engine.result!.actualCount, 5);
      expect(engine.result!.challengeWasCorrect, isFalse);
      expect(engine.result!.losingPlayer, 1);
      expect(engine.revealedHumanDice, scenario.humanDice);
      expect(engine.revealedOpponentDice, scenario.opponentDice);
    },
  );

  test('computer decision does not vary with the hidden human hand', () {
    final DiceBluffScenario base = DiceBluffScenario.forLevel(10);
    final DiceBluffScenario firstHand = base.withDiceHands(
      humanDice: List<int>.filled(base.diceCount, 1),
      opponentDice: base.opponentDice,
    );
    final DiceBluffScenario secondHand = base.withDiceHands(
      humanDice: List<int>.filled(base.diceCount, base.faceCount),
      opponentDice: base.opponentDice,
    );
    final DiceBluffEngine first = _openForBidding(
      firstHand,
      mode: DiceBluffMode.versusComputer,
      firstBidder: 0,
    );
    final DiceBluffEngine second = _openForBidding(
      secondHand,
      mode: DiceBluffMode.versusComputer,
      firstBidder: 0,
    );
    for (final DiceBluffEngine engine in <DiceBluffEngine>[first, second]) {
      expect(
        engine.raiseBid(player: 0, count: 1, face: 1),
        DiceBluffAction.raised,
      );
    }
    expect(first.playComputerTurn(), second.playComputerTurn());
    expect(first.currentBid!.count, second.currentBid!.count);
    expect(first.currentBid!.face, second.currentBid!.face);
    expect(first.result?.actualCount, isNull);
    expect(second.result?.actualCount, isNull);
  });

  test('both truthful and false claims resolve the losing hand', () {
    final DiceBluffScenario base = DiceBluffScenario.forLevel(3);
    int face = 1;
    int actual =
        base.humanDice.where((die) => die == face).length +
        base.opponentDice.where((die) => die == face).length;
    while (actual == 0 || actual == base.totalDice) {
      face++;
      actual =
          base.humanDice.where((die) => die == face).length +
          base.opponentDice.where((die) => die == face).length;
    }
    final DiceBluffEngine falseClaim = _openForBidding(
      base,
      mode: DiceBluffMode.localDuel,
      firstBidder: 0,
    );
    falseClaim.raiseBid(player: 0, count: actual + 1, face: face);
    falseClaim.challenge(player: 1);
    expect(falseClaim.result!.challengeWasCorrect, isTrue);
    expect(falseClaim.result!.losingPlayer, 0);

    final DiceBluffEngine trueClaim = _openForBidding(
      base,
      mode: DiceBluffMode.localDuel,
      firstBidder: 0,
    );
    trueClaim.raiseBid(player: 0, count: actual, face: face);
    trueClaim.challenge(player: 1);
    expect(trueClaim.result!.challengeWasCorrect, isFalse);
    expect(trueClaim.result!.losingPlayer, 1);
  });
}
