import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/orbit_rescue/orbit_rescue_engine.dart';
import 'package:zeka_parkuru/games/orbit_rescue/orbit_rescue_scenario.dart';

void main() {
  test('feedback flight completes every seeded rescue campaign', () {
    for (int level = 1; level <= OrbitRescueScenario.campaignLevels; level++) {
      final OrbitRescueScenario scenario = OrbitRescueScenario.forLevel(level);
      final OrbitRescueEngine engine = OrbitRescueEngine(scenario: scenario);
      String missedAt = '';
      while (!engine.completed && !engine.failed && engine.elapsed < 45) {
        final OrbitGate? gate = engine.currentGate;
        if (gate != null) {
          final double desiredVy = ((engine.targetY - engine.y) * 1.7)
              .clamp(-.17, .17)
              .toDouble();
          engine.setControl(
            x: ((.158 - engine.velocityX) * 3.0).clamp(-1, 1).toDouble(),
            y: ((desiredVy - engine.velocityY) * 3.0).clamp(-1, 1).toDouble(),
          );
        } else {
          engine.setControl(x: 0, y: 0);
        }
        final OrbitStepResult result = engine.step(.02);
        if (result.missed > 0) {
          missedAt =
              'position=(${engine.x}, ${engine.y}) '
              'velocity=(${engine.velocityX}, ${engine.velocityY}) '
              'target=$gate shield=${engine.shield}';
        }
      }
      expect(engine.failed, isFalse, reason: 'level $level: $missedAt');
      expect(
        engine.completed,
        isTrue,
        reason: 'level $level did not dock: $missedAt',
      );
      expect(
        engine.gatesCleared,
        scenario.gates.length,
        reason:
            'level $level cleared ${engine.gatesCleared}/${scenario.gates.length}; '
            '$missedAt misses=${engine.misses}',
      );
      expect(engine.misses, 0);
      expect(engine.bestCombo, scenario.gates.length);
    }
  });

  test('gravity bends the capsule and limited pulses change momentum', () {
    final OrbitRescueScenario scenario = OrbitRescueScenario.forLevel(5);
    final OrbitRescueEngine engine = OrbitRescueEngine(scenario: scenario);
    final OrbitBody body = scenario.bodies.first;
    engine.x = body.x - .12;
    engine.y = body.y;
    engine.velocityX = 0;
    engine.velocityY = 0;
    engine.step(.04);
    expect(engine.velocityX, greaterThan(0));

    engine.setControl(x: 0, y: 1);
    final double before = engine.velocityY;
    expect(engine.pulse(), isTrue);
    expect(engine.velocityY, greaterThan(before));
    expect(engine.pulsesUsed, 1);
    expect(engine.fuel, lessThan(scenario.fuelCapacity));
    for (int i = 1; i < scenario.pulseLimit; i++) {
      expect(engine.pulse(), isTrue);
    }
    expect(engine.pulse(), isFalse);
  });

  test(
    'rescue dock moves and the guidance target forecasts its crossing lane',
    () {
      final OrbitRescueScenario scenario = OrbitRescueScenario.forLevel(10);
      final OrbitGate dock = scenario.gates.last;
      final List<double> samples = <double>[
        for (int index = 0; index < 40; index++)
          dock.yAt(dock.motionPeriod * index / 40),
      ];
      expect(dock.motionAmplitude, greaterThan(0));
      expect(samples.reduce(math.min), lessThan(dock.y));
      expect(samples.reduce(math.max), greaterThan(dock.y));

      final OrbitRescueEngine engine = OrbitRescueEngine(scenario: scenario)
        ..nextGate = scenario.gates.length - 1
        ..elapsed = 1.25;
      final double secondsToDock =
          ((dock.x - engine.x) / math.max(.08, engine.velocityX))
              .clamp(0, .9)
              .toDouble();
      expect(
        engine.targetY,
        closeTo(dock.yAt(engine.elapsed + secondsToDock), 1e-9),
      );
    },
  );

  test('planet contact depletes the rescue shield and records a miss', () {
    final OrbitRescueScenario scenario = OrbitRescueScenario.forLevel(1);
    final OrbitRescueEngine engine = OrbitRescueEngine(scenario: scenario);
    final OrbitBody body = scenario.bodies.first;
    engine.x = body.x - body.radius - .012;
    engine.y = body.y;
    engine.velocityX = .1;
    engine.velocityY = 0;
    final double shield = engine.shield;
    final OrbitStepResult result = engine.step(.02);
    expect(result.collision, isTrue);
    expect(engine.shield, lessThan(shield));
    expect(engine.misses, greaterThan(0));
    expect(engine.combo, 0);
  });

  test(
    'control vector stays normalized and reset restores mission resources',
    () {
      final OrbitRescueScenario scenario = OrbitRescueScenario.forLevel(3);
      final OrbitRescueEngine engine = OrbitRescueEngine(scenario: scenario);
      engine.setControl(x: 4, y: 4);
      expect(
        math.sqrt(
          engine.thrustX * engine.thrustX + engine.thrustY * engine.thrustY,
        ),
        closeTo(1, .0001),
      );
      engine.pulse();
      engine.reset();
      expect(engine.x, .075);
      expect(engine.y, .5);
      expect(engine.fuel, scenario.fuelCapacity);
      expect(engine.shield, scenario.shieldCapacity);
      expect(engine.pulsesUsed, 0);
      expect(engine.currentGate, scenario.gates.first);
    },
  );
}
