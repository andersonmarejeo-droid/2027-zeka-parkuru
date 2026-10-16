import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/penalty_mindgame/penalty_engine.dart';
import 'package:zeka_parkuru/games/penalty_mindgame/penalty_scenario.dart';

void main() {
  test('a calibrated shot beats the goalkeeper on an open lane', () {
    final PenaltyMindgameEngine engine = PenaltyMindgameEngine(
      scenario: PenaltyScenario.forLevel(1),
    );
    final PenaltyLane openLane = PenaltyLane.values.firstWhere(
      (PenaltyLane lane) => lane != engine.currentKeeperRead,
    );

    final PenaltyActionResult result = engine.shoot(
      lane: openLane,
      power: engine.currentShotPower,
    );

    expect(result.outcome, PenaltyOutcome.goal);
    expect(engine.playerGoals, 1);
    expect(engine.phase, PenaltyPhase.shotFlight);
  });

  test('a keeper saves only with a correct read and an in-window dive', () {
    final PenaltyMindgameEngine engine = PenaltyMindgameEngine(
      scenario: PenaltyScenario.forLevel(20),
    )..shoot(lane: PenaltyLane.left, power: .7);
    while (engine.phase == PenaltyPhase.shotFlight) {
      engine.step(.04);
    }
    expect(engine.phase, PenaltyPhase.opponentRunUp);
    while (engine.runUpProgress < .66) {
      engine.step(.04);
    }

    final PenaltyActionResult result = engine.dive(
      lane: engine.currentKickLane,
    );

    expect(result.outcome, PenaltyOutcome.keeperSave);
    expect(engine.playerSaves, 1);
    expect(engine.opponentGoals, 0);
  });

  test('a perfect dual-role strategy can win every campaign shootout', () {
    for (int level = 1; level <= PenaltyScenario.campaignLevels; level++) {
      final PenaltyMindgameEngine engine = PenaltyMindgameEngine(
        scenario: PenaltyScenario.forLevel(level),
      );
      for (int action = 0; action < 2000 && !engine.matchOver; action++) {
        switch (engine.phase) {
          case PenaltyPhase.playerShot:
            final PenaltyLane openLane = PenaltyLane.values.firstWhere(
              (PenaltyLane lane) => lane != engine.currentKeeperRead,
            );
            engine.shoot(lane: openLane, power: engine.currentShotPower);
          case PenaltyPhase.shotFlight:
            engine.step(.04);
          case PenaltyPhase.opponentRunUp:
            if (engine.runUpProgress < .66) {
              engine.step(.04);
            } else {
              engine.dive(lane: engine.currentKickLane);
            }
          case PenaltyPhase.saveFlight:
            engine.step(.04);
          case PenaltyPhase.complete:
            break;
        }
      }
      expect(engine.matchOver, isTrue, reason: 'level $level did not finish');
      expect(engine.playerWon, isTrue, reason: 'level $level was not winnable');
      expect(engine.playerGoals, greaterThan(engine.opponentGoals));
    }
  });

  test('late keeper input is resolved fairly as a conceded goal', () {
    final PenaltyMindgameEngine engine = PenaltyMindgameEngine(
      scenario: PenaltyScenario.forLevel(1),
    )..shoot(lane: PenaltyLane.left, power: .7);
    while (engine.phase == PenaltyPhase.shotFlight) {
      engine.step(.04);
    }
    PenaltyActionResult? automatic;
    while (automatic?.automatic != true &&
        engine.phase == PenaltyPhase.opponentRunUp) {
      automatic = engine.step(.04);
    }
    expect(automatic?.automatic, isTrue);
    expect(engine.opponentGoals, 1);
  });
}
