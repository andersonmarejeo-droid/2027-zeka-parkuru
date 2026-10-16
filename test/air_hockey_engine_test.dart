import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/air_hockey_arena/air_hockey_engine.dart';
import 'package:zeka_parkuru/games/air_hockey_arena/air_hockey_scenario.dart';

void main() {
  test(
    'player contact returns the puck and consumes a single smash charge',
    () {
      final AirHockeyEngine engine =
          AirHockeyEngine(scenario: AirHockeyScenario.forLevel(1))
            ..puck = const Offset(.5, .685)
            ..velocity = const Offset(0, .5)
            ..playerMallet = const Offset(.5, .79)
            ..queueSmash();

      final AirHockeyStepResult result = engine.step(
        deltaSeconds: .025,
        playerTarget: const Offset(.5, .79),
      );

      expect(result.playerHit, isTrue);
      expect(result.smashUsed, isTrue);
      expect(engine.velocity.dy, lessThan(0));
      expect(engine.smashAvailable, isFalse);
      expect(engine.smashesUsed, 1);
    },
  );

  test('puck rails and bumper geometry remain inside the playable field', () {
    final AirHockeyScenario scenario = AirHockeyScenario.forLevel(20);
    final AirHockeyEngine engine = AirHockeyEngine(scenario: scenario)
      ..puck = const Offset(.02, .5)
      ..velocity = const Offset(-.7, .2);

    engine.step(deltaSeconds: .025, playerTarget: const Offset(.5, .79));

    expect(engine.puck.dx, greaterThanOrEqualTo(.035));
    expect(engine.velocity.dx, greaterThan(0));
    expect(scenario.bumpers.length, 3);
  });

  test('bounded opponent returns the puck or gives the player a point', () {
    final AirHockeyEngine engine =
        AirHockeyEngine(scenario: AirHockeyScenario.forLevel(12))
          ..puck = const Offset(.5, .315)
          ..velocity = const Offset(0, -.5)
          ..opponentMallet = const Offset(.5, .21);
    final Offset startingPaddle = engine.opponentMallet;

    final AirHockeyStepResult result = engine.step(
      deltaSeconds: .025,
      playerTarget: const Offset(.5, .79),
    );

    expect(
      result.opponentHit || result.pointWinner == AirHockeySide.player,
      isTrue,
    );
    expect(
      (engine.opponentMallet - startingPaddle).distance,
      lessThanOrEqualTo(engine.scenario.opponentSpeed * .025 + .000001),
    );
  });

  test('a deterministic mallet strategy can win each campaign match', () {
    for (int level = 1; level <= AirHockeyScenario.campaignLevels; level++) {
      final AirHockeyEngine engine = AirHockeyEngine(
        scenario: AirHockeyScenario.forLevel(level),
      );
      for (int frame = 0; frame < 60000 && !engine.matchOver; frame++) {
        final bool defending = engine.velocity.dy > 0;
        final double offset = engine.opponentMallet.dx > engine.puck.dx
            ? .052
            : -.052;
        final Offset target = defending
            ? Offset(
                (engine.puck.dx + offset).clamp(.09, .91).toDouble(),
                (engine.puck.dy + .085).clamp(.57, .90).toDouble(),
              )
            : const Offset(.5, .79);
        if (defending) engine.queueSmash();
        engine.step(deltaSeconds: 1 / 60, playerTarget: target);
      }
      expect(engine.matchOver, isTrue, reason: 'level $level did not finish');
      expect(engine.playerWon, isTrue, reason: 'level $level was not winnable');
      expect(
        engine.playerGoals,
        greaterThanOrEqualTo(engine.scenario.goalsToWin),
      );
    }
  });
}
