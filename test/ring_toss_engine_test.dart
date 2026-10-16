import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/ring_toss/ring_toss_engine.dart';
import 'package:zeka_parkuru/games/ring_toss/ring_toss_scenario.dart';

void main() {
  test('a softly arced ring catches a stationary peg at its apex', () {
    final RingTossScenario course = RingTossScenario.forLevel(1);
    final RingTossEngine engine = RingTossEngine(scenario: course);
    final RingTarget target = course.targets.first;
    final double rise = RingTossEngine.startPoint.y - target.y;
    final double flight = math.sqrt(2 * rise / course.gravity);
    final double vx = (target.x - RingTossEngine.startPoint.x) / flight;
    final double vy = -course.gravity * flight;
    final double speed = math.sqrt(vx * vx + vy * vy);
    expect(
      engine.launch(
        directionX: vx / speed,
        directionY: vy / speed,
        power: speed / 1.5,
        spin: 0,
      ),
      isTrue,
    );
    expect(engine.ring!.vx, closeTo(vx, .0001));
    expect(engine.ring!.vy, closeTo(vy, .0001));

    RingTossStepResult result = const RingTossStepResult();
    for (
      int frame = 0;
      frame < 120 && !result.captured && !result.missed;
      frame++
    ) {
      result = engine.step(.016);
    }
    expect(
      result.captured,
      isTrue,
      reason:
          'target=${target.x},${target.y}; ring=${engine.ring?.x},${engine.ring?.y}; misses=${engine.misses}',
    );
    expect(engine.captures, 1);
    expect(engine.misses, 0);
    expect(engine.targetIndex, 1);
    expect(engine.canThrow, isFalse);
  });

  test('power, spin and course bounds reject unsafe inputs', () {
    final RingTossEngine engine = RingTossEngine(
      scenario: RingTossScenario.forLevel(6),
    );
    expect(
      engine.launch(directionX: 0, directionY: 0, power: .5, spin: 0),
      isFalse,
    );
    expect(
      engine.launch(directionX: 0, directionY: -1, power: .5, spin: 2),
      isFalse,
    );
    expect(
      engine.launch(directionX: 0, directionY: -1, power: .5, spin: 0),
      isTrue,
    );
    expect(
      engine.launch(directionX: 0, directionY: -1, power: .5, spin: 0),
      isFalse,
    );
    final double before = engine.elapsedSeconds;
    engine.step(2);
    expect(engine.elapsedSeconds, closeTo(before + .024, .000001));
  });

  test('moving target phases and practice seeds remain deterministic', () {
    final RingTossScenario first = RingTossScenario.forPracticeRound(120);
    final RingTossScenario second = RingTossScenario.forPracticeRound(120);
    expect(first.signature, second.signature);
    expect(first.targetAt(4, 2.5).signature, second.targetAt(4, 2.5).signature);
    expect(
      first.targetAt(4, 2.5).signature,
      isNot(first.targetAt(4, 0).signature),
    );
  });
}
