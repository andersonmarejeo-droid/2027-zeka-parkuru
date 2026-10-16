import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/jetpack_courier/jetpack_courier_engine.dart';
import 'package:zeka_parkuru/games/jetpack_courier/jetpack_courier_scenario.dart';

void main() {
  test('feedback steering and throttle clear all campaign deliveries', () {
    for (
      int level = 1;
      level <= JetpackCourierScenario.campaignLevels;
      level++
    ) {
      final JetpackCourierScenario scenario = JetpackCourierScenario.forLevel(
        level,
      );
      final JetpackCourierEngine engine = JetpackCourierEngine(
        scenario: scenario,
      );
      String missedAt = '';
      while (!engine.completed && !engine.failed && engine.elapsed < 80) {
        final CourierCheckpoint? point = engine.currentCheckpoint;
        if (point == null) {
          engine.setControl(steer: 0, throttle: .58);
        } else {
          final double errorX = point.centerX - engine.x;
          final double errorY = point.centerAltitude - engine.altitude;
          final double desiredVertical = (errorY * 1.8)
              .clamp(-.38, .38)
              .toDouble();
          final double throttle =
              ((desiredVertical -
                          engine.verticalVelocity +
                          .92 -
                          point.updraft) /
                      1.55)
                  .clamp(0, 1)
                  .toDouble();
          engine.setControl(
            steer: (errorX * 3.8 - engine.lateralVelocity * 2.0)
                .clamp(-1, 1)
                .toDouble(),
            throttle: throttle.clamp(0, 1).toDouble(),
          );
        }
        final CourierStepResult result = engine.step(.02);
        if (result.missed > 0) {
          missedAt = 'target=$point, x=${engine.x}, alt=${engine.altitude}, '
              'speed=${engine.velocity}, heat=${engine.heat}, '
              'locked=${engine.thermalLock}';
        }
      }
      expect(
        engine.failed,
        isFalse,
        reason:
            'level $level failed at ring ${engine.nextCheckpoint}, '
            'x ${engine.x}, alt ${engine.altitude}, velocity ${engine.velocity}, '
            'heat ${engine.heat}, fuel ${engine.fuel}, cargo ${engine.packageIntegrity}',
      );
      expect(engine.completed, isTrue, reason: 'level $level did not dock');
      expect(
        engine.checkpointsCleared,
        scenario.checkpoints.length,
        reason: 'level $level missed a delivery: ${engine.states}; '
            'x=${engine.x} alt=${engine.altitude} speed=${engine.velocity} '
            'cargo=${engine.packageIntegrity}; $missedAt',
      );
      expect(engine.misses, 0);
      expect(engine.bestCombo, scenario.checkpoints.length);
    }
  });

  test('holding full thrust eventually locks the pack until it cools', () {
    final JetpackCourierScenario scenario = JetpackCourierScenario(
      level: 1,
      seed: 1,
      checkpoints: const <CourierCheckpoint>[
        CourierCheckpoint(
          progress: 95,
          centerX: .5,
          centerAltitude: .5,
          halfWidth: .4,
          halfHeight: .4,
          crosswind: 0,
          updraft: -.63,
          safeSpeed: 1,
        ),
      ],
      missLimit: 3,
      fuelCapacity: 100,
      packageTolerance: 100,
      forwardSpeed: 1,
      finishProgress: 100,
    );
    final JetpackCourierEngine engine = JetpackCourierEngine(
      scenario: scenario,
    );
    engine.setControl(steer: 0, throttle: 1);
    bool locked = false;
    for (int frame = 0; frame < 1400 && !engine.thermalLock; frame++) {
      locked = engine.step(.04).overheated || locked;
    }
    expect(locked, isTrue);
    expect(engine.thermalLock, isTrue);
    engine.setControl(steer: 0, throttle: 0);
    for (int frame = 0; frame < 1000 && engine.thermalLock; frame++) {
      engine.step(.04);
    }
    expect(engine.thermalLock, isFalse);
  });

  test(
    'hard contact damages cargo and checkpoint miss breaks delivery combo',
    () {
      final JetpackCourierScenario scenario = JetpackCourierScenario.forLevel(
        1,
      );
      final JetpackCourierEngine engine = JetpackCourierEngine(
        scenario: scenario,
      );
      engine.x = .95;
      final double before = engine.packageIntegrity;
      expect(engine.step(.02).impact, isTrue);
      expect(engine.packageIntegrity, lessThan(before));
      expect(engine.misses, 1);
      expect(engine.combo, 0);
    },
  );
}
