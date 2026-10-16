import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/magnet_path/magnet_path_engine.dart';
import 'package:zeka_parkuru/games/magnet_path/magnet_path_scenario.dart';

void main() {
  group('Magnetic puck physics', () {
    test('polarity controls attraction and repulsion with inertia retained', () {
      final MagnetPathScenario scenario = MagnetPathScenario.forLevel(2);
      final MagnetPathEngine attracted = MagnetPathEngine(scenario: scenario);
      final MagnetPathEngine repelled = MagnetPathEngine(scenario: scenario);
      attracted.step(
        deltaSeconds: .025,
        worldHeight: 1.12,
        magnetX: .75,
        magnetY: .84,
        attract: true,
      );
      repelled.step(
        deltaSeconds: .025,
        worldHeight: 1.12,
        magnetX: .75,
        magnetY: .84,
        attract: false,
      );
      expect(attracted.puck.vx, greaterThan(0));
      expect(repelled.puck.vx, lessThan(0));
      expect(attracted.puck.x, greaterThan(scenario.start.x));
    });

    test('successive gates advance only in their authored order', () {
      final MagnetPathScenario scenario = MagnetPathScenario.forLevel(3);
      final MagnetPathEngine engine = MagnetPathEngine(scenario: scenario);
      final MagnetPoint first = scenario.gates.first;
      engine.puck
        ..x = first.x
        ..y = first.y * 1.12;
      final MagnetStepResult result = engine.step(
        deltaSeconds: .001,
        worldHeight: 1.12,
        magnetX: first.x,
        magnetY: first.y * 1.12,
        attract: true,
      );
      expect(result.gatesReached, <int>[0]);
      expect(engine.nextGate, 1);
    });

    test('metal baffle collision resolves without NaN state', () {
      final MagnetPathScenario scenario = MagnetPathScenario.forLevel(10);
      final MagnetPathEngine engine = MagnetPathEngine(scenario: scenario);
      final MagnetBaffle baffle = scenario.baffles.first;
      engine.puck
        ..x = baffle.x + baffle.radius * .6
        ..y = baffle.y * 1.12;
      final MagnetStepResult result = engine.step(
        deltaSeconds: .01,
        worldHeight: 1.12,
        magnetX: .85,
        magnetY: .20,
        attract: true,
      );
      expect(result.collided, isTrue);
      expect(engine.puck.x.isFinite && engine.puck.y.isFinite, isTrue);
      expect(engine.puck.x, closeTo(baffle.x + baffle.radius + .026, .002));
    });
  });
}
