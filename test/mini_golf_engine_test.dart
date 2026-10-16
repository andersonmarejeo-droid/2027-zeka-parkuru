import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mini_golf_route/mini_golf_engine.dart';
import 'package:zeka_parkuru/games/mini_golf_route/mini_golf_scenario.dart';

void main() {
  group('Mini Golf shot and cup physics', () {
    test('par-three center line can be completed through the calm gate', () {
      final MiniGolfScenario scenario = MiniGolfScenario.forLevel(1);
      final MiniGolfEngine engine = MiniGolfEngine(scenario: scenario);
      const double worldHeight = 1.2;
      final double dx = scenario.hole.x - scenario.start.x;
      final double dy = (scenario.hole.y - scenario.start.y) * worldHeight;
      final double distance = math.sqrt(dx * dx + dy * dy);
      expect(
        engine.strike(
          directionX: dx,
          directionY: dy,
          power: distance * scenario.grassDrag * 1.025,
          spin: 0,
        ),
        isTrue,
      );
      bool holed = false;
      for (int frame = 0; frame < 1400 && !engine.isSettled; frame++) {
        final GolfStepResult step = engine.step(
          deltaSeconds: 1 / 60,
          worldHeight: worldHeight,
          elapsedSeconds: frame / 60,
        );
        if (step.enteredHole) {
          holed = true;
          break;
        }
      }
      expect(holed, isTrue);
    });

    test('spin adds controlled side drift and wind changes the flight', () {
      final MiniGolfScenario scenario = MiniGolfScenario.forLevel(8);
      final MiniGolfEngine engine = MiniGolfEngine(scenario: scenario);
      expect(
        engine.strike(directionX: 0, directionY: -1, power: .5, spin: 1),
        isTrue,
      );
      expect(engine.ball.vx, closeTo(.1, .001));
      engine.step(deltaSeconds: .02, worldHeight: 1.2, elapsedSeconds: .1);
      expect(engine.ball.x, greaterThan(.5));
      expect(engine.ball.x.isFinite && engine.ball.y.isFinite, isTrue);
    });

    test(
      'surface patches apply sand drag and bumpers keep the ball finite',
      () {
        final MiniGolfScenario scenario = MiniGolfScenario.forLevel(10);
        final MiniGolfEngine engine = MiniGolfEngine(scenario: scenario);
        final GolfPatch patch = scenario.sand.first;
        engine.ball
          ..x = patch.x
          ..y = patch.y * 1.2
          ..vx = .34
          ..vy = 0;
        final double speedBefore = engine.ball.vx.abs();
        final GolfStepResult result = engine.step(
          deltaSeconds: .02,
          worldHeight: 1.2,
          elapsedSeconds: .2,
        );
        expect(result.inSand, isTrue);
        expect(engine.ball.vx.abs(), lessThan(speedBefore));
        expect(engine.ball.x.isFinite && engine.ball.y.isFinite, isTrue);
      },
    );
  });
}
