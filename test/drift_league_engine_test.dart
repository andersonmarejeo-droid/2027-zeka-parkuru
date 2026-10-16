import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/drift_league/drift_league_engine.dart';
import 'package:zeka_parkuru/games/drift_league/drift_league_scenario.dart';

void main() {
  test('auto-throttle advances, brake slows, and steering changes heading', () {
    final DriftLeagueEngine engine = DriftLeagueEngine(
      scenario: DriftLeagueScenario.forLevel(1),
    );
    final double initialSpeed = engine.speed;
    final double initialHeading = engine.heading;

    for (int frame = 0; frame < 60; frame++) {
      engine.step(
        deltaSeconds: 1 / 60,
        steering: 0,
        handbrake: false,
        braking: false,
      );
    }
    final double acceleratedSpeed = engine.speed;
    expect(acceleratedSpeed, greaterThan(initialSpeed));

    for (int frame = 0; frame < 60; frame++) {
      engine.step(
        deltaSeconds: 1 / 60,
        steering: .65,
        handbrake: false,
        braking: true,
      );
    }
    expect(engine.heading, isNot(initialHeading));
    expect(engine.speed, lessThan(acceleratedSpeed));
  });

  test('handbrake rewards controlled side slip, not straight driving', () {
    final DriftLeagueEngine engine = DriftLeagueEngine(
      scenario: DriftLeagueScenario.forLevel(1),
    );
    final Offset forward = Offset(
      math.cos(engine.heading),
      math.sin(engine.heading),
    );
    final Offset right = Offset(-forward.dy, forward.dx);
    engine.velocity = forward * .22 + right * .17;

    final DriftStepResult result = engine.step(
      deltaSeconds: 1 / 60,
      steering: 0,
      handbrake: true,
      braking: false,
    );
    expect(engine.isDrifting, isTrue);
    expect(result.driftPoints, greaterThanOrEqualTo(0));
    expect(engine.driftScore, greaterThan(0));

    engine.reset();
    for (int frame = 0; frame < 60; frame++) {
      engine.step(
        deltaSeconds: 1 / 60,
        steering: 0,
        handbrake: true,
        braking: false,
      );
    }
    expect(engine.driftScore, 0);
  });

  test('ordered checkpoints finish only after the final gate', () {
    final DriftLeagueScenario scenario = DriftLeagueScenario.forLevel(1);
    final DriftLeagueEngine engine = DriftLeagueEngine(scenario: scenario);

    for (int gate = 0; gate < scenario.checkpointCount; gate++) {
      final double gateProgress = (gate + 1) / scenario.checkpointCount;
      final Offset tangent = scenario.tangentAt(gateProgress);
      engine
        ..position = engine.checkpointAt(gate)
        ..heading = math.atan2(tangent.dy, tangent.dx)
        ..velocity = tangent * .20;
      final DriftStepResult result = engine.step(
        deltaSeconds: 1 / 240,
        steering: 0,
        handbrake: false,
        braking: true,
      );
      expect(result.passedCheckpoint, isTrue, reason: 'gate ${gate + 1}');
      expect(engine.completed, gate == scenario.checkpointCount - 1);
    }
  });

  test('a checkpoint cannot be claimed by crossing it in reverse', () {
    final DriftLeagueScenario scenario = DriftLeagueScenario.forLevel(1);
    final DriftLeagueEngine engine = DriftLeagueEngine(scenario: scenario);
    const double gateProgress = .25;
    final double approachProgress = gateProgress + .001;
    final Offset tangent = scenario.tangentAt(approachProgress);
    engine
      ..position = scenario.pointAt(approachProgress)
      ..heading = math.atan2(tangent.dy, tangent.dx) + math.pi
      ..velocity =
          Offset(
            math.cos(math.atan2(tangent.dy, tangent.dx) + math.pi),
            math.sin(math.atan2(tangent.dy, tangent.dx) + math.pi),
          ) *
          .20;

    for (int frame = 0; frame < 4; frame++) {
      engine.step(
        deltaSeconds: 1 / 60,
        steering: 0,
        handbrake: false,
        braking: false,
      );
    }

    expect(engine.projection.progress, lessThan(gateProgress));
    expect(engine.checkpointsPassed, 0);
  });

  test('a deterministic racing line can finish every campaign circuit', () {
    for (int level = 1; level <= DriftLeagueScenario.campaignLevels; level++) {
      final DriftLeagueScenario scenario = DriftLeagueScenario.forLevel(level);
      final DriftLeagueEngine engine = DriftLeagueEngine(scenario: scenario);
      for (int frame = 0; frame < 12000 && !engine.completed; frame++) {
        final double progress = engine.projection.progress;
        final double gateProgress =
            (engine.checkpointsPassed + 1) / scenario.checkpointCount;
        final double gateDistance = gateProgress - progress;
        final Offset target = gateDistance >= 0 && gateDistance < .11
            ? scenario.pointAt(gateProgress + .006)
            : scenario.pointAt(progress + .045);
        final double desiredHeading = math.atan2(
          target.dy - engine.position.dy,
          target.dx - engine.position.dx,
        );
        final double headingError = math.atan2(
          math.sin(desiredHeading - engine.heading),
          math.cos(desiredHeading - engine.heading),
        );
        engine.step(
          deltaSeconds: 1 / 60,
          steering: (headingError * 2.6).clamp(-1, 1).toDouble(),
          handbrake: false,
          braking: false,
        );
        expect(
          engine.failed,
          isFalse,
          reason:
              'level $level failed early: checkpoints=${engine.checkpointsPassed}, '
              'recoveries=${engine.recoveries}, progress=${engine.projection.progress}, '
              'distance=${engine.projection.distance}, speed=${engine.speed}',
        );
      }
      expect(
        engine.completed,
        isTrue,
        reason:
            'level $level has no viable line: checkpoints=${engine.checkpointsPassed}, '
            'recoveries=${engine.recoveries}, failed=${engine.failed}, '
            'progress=${engine.projection.progress}, distance=${engine.projection.distance}, '
            'speed=${engine.speed}, elapsed=${engine.elapsedSeconds}',
      );
    }
  });

  test('recovery returns the car to the last confirmed gate', () {
    final DriftLeagueScenario scenario = DriftLeagueScenario.forLevel(1);
    final DriftLeagueEngine engine = DriftLeagueEngine(scenario: scenario)
      ..position = const Offset(.02, .02);
    DriftStepResult lastResult = const DriftStepResult();
    for (int frame = 0; frame < 100; frame++) {
      lastResult = engine.step(
        deltaSeconds: 1 / 60,
        steering: 0,
        handbrake: false,
        braking: false,
      );
      if (lastResult.recovered) break;
    }

    expect(lastResult.recovered, isTrue);
    expect(engine.recoveries, 1);
    expect(engine.projection.distance, lessThan(scenario.checkpointRadius));
  });
}
