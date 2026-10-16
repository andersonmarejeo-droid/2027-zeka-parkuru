import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/neon_pinball/neon_pinball_engine.dart';
import 'package:zeka_parkuru/games/neon_pinball/neon_pinball_scenario.dart';

void main() {
  test('launcher only accepts a fresh ball and flippers impart momentum', () {
    final NeonPinballEngine engine = NeonPinballEngine(
      scenario: NeonPinballScenario.forLevel(3),
    );
    expect(engine.launch(aim: -.2), isTrue);
    expect(engine.orbs, hasLength(1));
    expect(engine.launch(), isFalse);

    final PinballOrb ball = engine.orbs.single
      ..x = .42
      ..y = .82
      ..vx = 0
      ..vy = .4;
    engine.setFlippers(left: true, right: false);
    final PinballStepResult result = engine.step(.018);
    expect(result.flipperHit, isTrue);
    expect(ball.vy, lessThan(0));
  });

  test('bumper returns a real ball with a scored rebound', () {
    final NeonPinballScenario table = NeonPinballScenario.forLevel(4);
    final NeonPinballEngine engine = NeonPinballEngine(scenario: table);
    engine.launch();
    final PinballBumper bumper = table.bumpers.first;
    final PinballOrb ball = engine.orbs.single
      ..x = bumper.x - bumper.radius - .016
      ..y = bumper.y
      ..vx = .4
      ..vy = 0;
    final PinballStepResult result = engine.step(.018);
    expect(result.bumperHit, isTrue);
    expect(engine.score, greaterThan(0));
    expect(ball.vx, isNot(.4));
  });

  test('numbered target strike scores once and advances the lit sequence', () {
    final NeonPinballScenario table = NeonPinballScenario.forLevel(2);
    final NeonPinballEngine engine = NeonPinballEngine(scenario: table);
    engine.launch();
    final PinballTarget target = table.targets.first;
    final ({double x, double y}) center = target.at(0);
    engine.orbs.single
      ..x = center.x
      ..y = center.y + .012
      ..vx = 0
      ..vy = 0;
    final PinballStepResult result = engine.step(.018);
    expect(result.targetHit, 0);
    expect(engine.nextTarget, 1);
    expect(engine.litTargets, contains(0));
    expect(engine.score, greaterThanOrEqualTo(100));
  });

  test('unlit target rebounds but cannot skip the active sequence marker', () {
    final NeonPinballScenario table = NeonPinballScenario.forLevel(4);
    final NeonPinballEngine engine = NeonPinballEngine(scenario: table);
    engine.launch();
    final PinballTarget target = table.targets[1];
    final ({double x, double y}) center = target.at(0);
    engine.orbs.single
      ..x = center.x
      ..y = center.y + .012
      ..vx = 0
      ..vy = 0;
    final PinballStepResult result = engine.step(.018);
    expect(result.wrongTargetHit, isTrue);
    expect(result.targetHit, isNull);
    expect(engine.nextTarget, 0);
    expect(engine.wrongTargets, 1);
  });

  test('a clean sequence of actual target collisions wins the table', () {
    final NeonPinballScenario table = NeonPinballScenario.forLevel(1);
    final NeonPinballEngine engine = NeonPinballEngine(scenario: table);
    expect(engine.launch(), isTrue);
    PinballStepResult last = const PinballStepResult();
    for (int index = 0; index < table.targets.length; index++) {
      final PinballTarget target = table.targets[index];
      final ({double x, double y}) center = target.at(engine.elapsed);
      engine.orbs.single
        ..x = center.x
        ..y = center.y + .012
        ..vx = 0
        ..vy = 0;
      last = engine.step(.018);
    }
    expect(last.completed, isTrue);
    expect(engine.completed, isTrue);
    expect(engine.nextTarget, table.targets.length);
  });

  test('master lock opens real multiball and both master serves can drain', () {
    final NeonPinballScenario table = NeonPinballScenario.forLevel(9);
    final NeonPinballEngine engine = NeonPinballEngine(scenario: table);
    expect(engine.launch(), isTrue);
    PinballStepResult lock = const PinballStepResult();
    for (int index = 0; index <= table.lockTargetIndex; index++) {
      final PinballTarget target = table.targets[index];
      final ({double x, double y}) center = target.at(engine.elapsed);
      engine.orbs.first
        ..x = center.x
        ..y = center.y + .012
        ..vx = 0
        ..vy = 0;
      lock = engine.step(.018);
    }
    expect(lock.multiballStarted, isTrue);
    expect(engine.multiballActive, isTrue);
    expect(engine.nextTarget, table.lockTargetIndex + 1);

    for (int serve = 1; serve <= table.totalBalls; serve++) {
      for (final PinballOrb ball in engine.orbs.toList()) {
        ball
          ..x = .5
          ..y = 1.02
          ..vx = 0
          ..vy = .2;
      }
      final PinballStepResult drained = engine.step(.018);
      expect(drained.drained, isTrue);
      if (serve < table.totalBalls) {
        expect(engine.waitingToLaunch, isTrue);
        expect(engine.launch(), isTrue);
      }
    }
    expect(engine.failed, isTrue);
  });
}
