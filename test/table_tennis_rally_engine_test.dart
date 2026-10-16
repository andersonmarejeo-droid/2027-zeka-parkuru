import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/table_tennis_rally/table_tennis_engine.dart';
import 'package:zeka_parkuru/games/table_tennis_rally/table_tennis_scenario.dart';

void main() {
  test('a timed topspin return clears the net toward the opponent', () {
    final TableTennisEngine engine =
        TableTennisEngine(scenario: TableTennisScenario.forLevel(1))
          ..ball = const Offset(.52, .815)
          ..velocity = const Offset(-.08, .65)
          ..playerX = .52;

    final RallyStepResult result = engine.step(
      deltaSeconds: .025,
      playerPaddleX: .52,
      shot: TableTennisShot.topspin,
    );

    expect(result.playerHit, isTrue);
    expect(engine.playerHits, 1);
    expect(engine.velocity.dy, lessThan(0));
    expect(engine.lastShot, TableTennisShot.topspin);
  });

  test('an untouched ball awards the point without corrupting match state', () {
    final TableTennisEngine engine =
        TableTennisEngine(scenario: TableTennisScenario.forLevel(1))
          ..ball = const Offset(.5, .979)
          ..velocity = const Offset(0, .65);

    final RallyStepResult result = engine.step(
      deltaSeconds: .025,
      playerPaddleX: .5,
    );

    expect(result.pointWinner, RallyPointWinner.opponent);
    expect(result.playerMiss, isTrue);
    expect(engine.opponentPoints, 1);
    expect(engine.matchOver, isFalse);
    expect(engine.waitingForServe, isTrue);
  });

  test('a deterministic return strategy can win each campaign match', () {
    for (int level = 1; level <= TableTennisScenario.campaignLevels; level++) {
      final TableTennisEngine engine = TableTennisEngine(
        scenario: TableTennisScenario.forLevel(level),
      );
      for (int frame = 0; frame < 30000 && !engine.matchOver; frame++) {
        final bool approaching = engine.velocity.dy > 0 && engine.ball.dy > .65;
        final double aimOffset = engine.opponentX > engine.ball.dx ? .11 : -.11;
        final double paddleX = approaching
            ? (engine.ball.dx + aimOffset).clamp(.075, .925).toDouble()
            : engine.ball.dx;
        engine.step(
          deltaSeconds: 1 / 60,
          playerPaddleX: paddleX,
          shot: approaching ? TableTennisShot.slice : null,
        );
      }
      expect(engine.matchOver, isTrue, reason: 'level $level never finished');
      expect(engine.playerWon, isTrue, reason: 'level $level was not winnable');
      expect(
        engine.playerPoints,
        greaterThanOrEqualTo(engine.scenario.pointsToWin),
        reason: 'level $level did not honor the match target',
      );
    }
  });

  test('opponent movement is bounded rather than teleporting to the ball', () {
    final TableTennisScenario scenario = TableTennisScenario.forLevel(20);
    final TableTennisEngine engine = TableTennisEngine(scenario: scenario)
      ..ball = const Offset(.9, .62)
      ..velocity = const Offset(-.28, -.72);
    final double startingX = engine.opponentX;

    engine.step(deltaSeconds: 1 / 60, playerPaddleX: .5);

    expect(
      (engine.opponentX - startingX).abs(),
      lessThanOrEqualTo(scenario.opponentMoveSpeed / 60 + .000001),
    );
    expect(engine.opponentX, isNot(engine.ball.dx));
  });
}
