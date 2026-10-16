import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kite_runner/kite_runner_engine.dart';
import 'package:zeka_parkuru/games/kite_runner/kite_runner_scenario.dart';

void main() {
  test('a centered gate crossing is registered once', () {
    final KiteRunnerScenario course = KiteRunnerScenario.forLevel(1);
    final KiteRunnerEngine engine = KiteRunnerEngine(scenario: course);
    final KiteGate gate = course.gates.first;
    engine.kite
      ..distance = gate.distance - .001
      ..x = gate.centerX
      ..altitude = gate.altitude;
    final KiteStepResult result = engine.step(.02);
    expect(result.gatePassed, isTrue);
    expect(engine.nextGate, 1);
    expect(engine.misses, 0);
  });

  test('a gate outside the vertical window is recorded as a miss', () {
    final KiteRunnerScenario course = KiteRunnerScenario.forLevel(2);
    final KiteRunnerEngine engine = KiteRunnerEngine(scenario: course);
    final KiteGate gate = course.gates.first;
    engine.kite
      ..distance = gate.distance - .001
      ..x = gate.centerX
      ..altitude = .98;
    final KiteStepResult result = engine.step(.02);
    expect(result.gateMissed, isTrue);
    expect(engine.nextGate, 1);
    expect(engine.misses, 1);
  });

  test('wire strike costs two misses but clearing its corridor is safe', () {
    final KiteRunnerScenario course = KiteRunnerScenario.forLevel(6);
    final KiteRunnerEngine hit = KiteRunnerEngine(scenario: course);
    final KiteWire wire = course.wires.first;
    hit.kite
      ..distance = wire.distance - .001
      ..x = wire.centerX
      ..altitude = wire.altitude;
    final KiteStepResult collision = hit.step(.02);
    expect(collision.wireHit, isTrue);
    expect(hit.misses, 2);

    final KiteRunnerEngine clear = KiteRunnerEngine(scenario: course);
    clear.kite
      ..distance = wire.distance - .001
      ..x = .5
      ..altitude = .9;
    final KiteStepResult pass = clear.step(.02);
    expect(pass.wireHit, isFalse);
    expect(clear.wiresAvoided, 1);
  });

  test(
    'reckless reel-and-steer snaps an expert tether; release cools load',
    () {
      final KiteRunnerEngine engine = KiteRunnerEngine(
        scenario: KiteRunnerScenario.forLevel(10),
      );
      engine.setControl(steer: 1, reel: 1);
      KiteStepResult result = const KiteStepResult();
      for (int frame = 0; frame < 200 && !engine.failed; frame++) {
        result = engine.step(.02);
      }
      expect(result.lineSnapped, isTrue);
      expect(engine.failed, isTrue);

      engine.reset();
      engine.setControl(steer: 0, reel: -1);
      for (int frame = 0; frame < 100; frame++) {
        engine.step(.02);
      }
      expect(engine.kite.lineLength, greaterThan(.56));
      expect(engine.failed, isFalse);
    },
  );

  test('a completed gate course can finish cleanly and reset', () {
    final KiteRunnerEngine engine = KiteRunnerEngine(
      scenario: KiteRunnerScenario.forLevel(3),
    );
    engine
      ..nextGate = engine.scenario.gates.length
      ..kite.distance = .999;
    final KiteStepResult result = engine.step(.02);
    expect(result.finished, isTrue);
    expect(engine.finished, isTrue);
    engine.reset();
    expect(engine.kite.distance, 0);
    expect(engine.nextGate, 0);
    expect(engine.finished, isFalse);
  });

  test('a paced steering-and-trim policy can fly all ten seeded routes', () {
    for (int level = 1; level <= KiteRunnerScenario.campaignLevels; level++) {
      final KiteRunnerEngine engine = KiteRunnerEngine(
        scenario: KiteRunnerScenario.forLevel(level),
      );
      final List<String> trace = <String>[];
      for (
        int frame = 0;
        frame < 1200 && !engine.finished && !engine.failed;
        frame++
      ) {
        final KiteGate? gate = engine.nextGate < engine.scenario.gates.length
            ? engine.scenario.gates[engine.nextGate]
            : null;
        if (gate == null) {
          final double crosswind = engine.scenario
              .windAt(engine.kite.distance, engine.elapsed)
              .cross;
          engine.setControl(
            steer: (-crosswind * .27 - engine.kite.lateralSpeed * 2.1)
                .clamp(-.8, .8)
                .toDouble(),
            reel:
                ((engine.kite.altitude - .56) * 3 + engine.kite.climbRate * 2.8)
                    .clamp(-.65, .65)
                    .toDouble(),
          );
        } else {
          final double steer =
              ((gate.centerAt(engine.elapsed) - engine.kite.x) * 4 -
                      engine.scenario
                              .windAt(engine.kite.distance, engine.elapsed)
                              .cross *
                          .27 -
                      engine.kite.lateralSpeed * 2.1)
                  .clamp(-.9, .9)
                  .toDouble();
          final double reel =
              ((engine.kite.altitude - gate.altitude) * 3.2 +
                      engine.kite.climbRate * 2.6)
                  .clamp(-.65, .65)
                  .toDouble();
          engine.setControl(steer: steer, reel: reel);
        }
        final KiteStepResult result = engine.step(.02);
        if (result.gatePassed || result.gateMissed || result.wireHit) {
          final String target = gate == null
              ? 'finish'
              : 'to=${gate.centerAt(engine.elapsed).toStringAsFixed(2)},'
                    'h=${gate.altitude.toStringAsFixed(2)}';
          trace.add(
            'g${engine.nextGate}:${result.gatePassed ? 'pass' : 'miss'} '
            '$target '
            'x=${engine.kite.x.toStringAsFixed(2)} '
            'h=${engine.kite.altitude.toStringAsFixed(2)} '
            't=${engine.kite.lineTension.toStringAsFixed(2)}',
          );
        }
      }
      expect(
        engine.finished,
        isTrue,
        reason:
            'level $level must be flyable; failed=${engine.failed}, '
            'gate=${engine.nextGate}/${engine.scenario.gates.length}, '
            'miss=${engine.misses}, x=${engine.kite.x}, '
            'alt=${engine.kite.altitude}, tension=${engine.kite.lineTension}, '
            'distance=${engine.kite.distance}, trace=$trace',
      );
    }
  });
}
