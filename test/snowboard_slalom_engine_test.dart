import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/snowboard_slalom/snowboard_slalom_engine.dart';
import 'package:zeka_parkuru/games/snowboard_slalom/snowboard_slalom_scenario.dart';

void main() {
  test('a feedback carve and surface-aware brake clear every campaign route', () {
    for (
      int level = 1;
      level <= SnowboardSlalomScenario.campaignLevels;
      level++
    ) {
      final SnowboardSlalomScenario scenario = SnowboardSlalomScenario.forLevel(
        level,
      );
      final SnowboardSlalomEngine engine = SnowboardSlalomEngine(
        scenario: scenario,
      );
      while (!engine.completed && !engine.failed && engine.elapsed < 160) {
        final SnowGate? gate = engine.currentGate;
        if (gate != null) {
          final double error = gate.centerX - engine.x;
          engine.setCarve(
            (error * 4.4 - engine.lateralVelocity * 1.65)
                .clamp(-1, 1)
                .toDouble(),
          );
          engine.setBrake(
            gate.surface == SnowSurface.moguls &&
                engine.speed > gate.safeSpeed - .03,
          );
        } else {
          engine.setCarve(0);
          engine.setBrake(false);
        }
        engine.step(.02);
      }
      expect(
        engine.failed,
        isFalse,
        reason:
            'level $level failed at gate ${engine.nextGate}, x ${engine.x}, speed ${engine.speed}, edge ${engine.edgeLoad}, misses ${engine.misses}',
      );
      expect(engine.completed, isTrue, reason: 'level $level did not finish');
      expect(engine.gatesCleared, scenario.gates.length);
      expect(engine.misses, 0);
      expect(engine.bestCombo, scenario.gates.length);
    }
  });

  test('powder grips a carve more than ice and brake scrubs speed/load', () {
    SnowboardSlalomScenario build(SnowSurface surface) =>
        SnowboardSlalomScenario(
          level: 5,
          seed: surface.index,
          gates: <SnowGate>[
            SnowGate(
              distance: 10,
              centerX: .5,
              width: .3,
              surface: surface,
              crosswind: 0,
              safeSpeed: 1,
            ),
          ],
          missLimit: 3,
          initialSpeed: .6,
          finishDistance: 12,
        );
    final SnowboardSlalomEngine powder = SnowboardSlalomEngine(
      scenario: build(SnowSurface.powder),
    );
    final SnowboardSlalomEngine ice = SnowboardSlalomEngine(
      scenario: build(SnowSurface.ice),
    );
    powder.setCarve(1);
    ice.setCarve(1);
    for (int frame = 0; frame < 25; frame++) {
      powder.step(.02);
      ice.step(.02);
    }
    expect(powder.x, greaterThan(ice.x));

    final double before = powder.speed;
    powder.setBrake(true);
    for (int frame = 0; frame < 20; frame++) {
      powder.step(.02);
    }
    expect(powder.speed, lessThan(before));
    expect(powder.edgeLoad, lessThan(ice.edgeLoad + .4));
  });

  test('a missed gate breaks the combo and consumes one mistake', () {
    final SnowboardSlalomScenario scenario = SnowboardSlalomScenario(
      level: 1,
      seed: 1,
      gates: <SnowGate>[
        const SnowGate(
          distance: .5,
          centerX: .75,
          width: .2,
          surface: SnowSurface.packed,
          crosswind: 0,
          safeSpeed: 1,
        ),
        const SnowGate(
          distance: 1,
          centerX: .5,
          width: .2,
          surface: SnowSurface.packed,
          crosswind: 0,
          safeSpeed: 1,
        ),
      ],
      missLimit: 1,
      initialSpeed: .6,
      finishDistance: 2,
    );
    final SnowboardSlalomEngine engine = SnowboardSlalomEngine(
      scenario: scenario,
    );
    for (int frame = 0; frame < 25; frame++) {
      engine.step(.04);
    }
    expect(engine.states.first, SnowGateState.missed);
    expect(engine.misses, 1);
    expect(engine.combo, 0);
    expect(engine.failed, isFalse);
  });
}
