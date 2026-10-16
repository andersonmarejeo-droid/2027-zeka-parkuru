import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'drift_league_scenario.dart';

class DriftStepResult {
  const DriftStepResult({
    this.passedCheckpoint = false,
    this.recovered = false,
    this.completed = false,
    this.failed = false,
    this.driftPoints = 0,
  });

  final bool passedCheckpoint;
  final bool recovered;
  final bool completed;
  final bool failed;
  final int driftPoints;
}

/// Lightweight, fixed-step top-down car dynamics for the Drift League.
class DriftLeagueEngine {
  DriftLeagueEngine({required this.scenario}) {
    reset();
  }

  final DriftLeagueScenario scenario;

  late Offset position;
  late Offset velocity;
  late double heading;
  double elapsedSeconds = 0;
  double driftScore = 0;
  double driftChainSeconds = 0;
  double offTrackSeconds = 0;
  int checkpointsPassed = 0;
  int recoveries = 0;
  bool isDrifting = false;
  bool completed = false;
  bool failed = false;
  double _driftAngle = 0;

  double get speed => velocity.distance;
  double get driftAngleRadians => _driftAngle;
  double get nextCheckpointProgress =>
      (checkpointsPassed + 1) / scenario.checkpointCount;
  DriftTrackProjection get projection => scenario.project(position);

  Offset checkpointAt(int index) =>
      scenario.pointAt((index + 1) / scenario.checkpointCount);

  DriftStepResult step({
    required double deltaSeconds,
    required double steering,
    required bool handbrake,
    required bool braking,
  }) {
    if (completed || failed || deltaSeconds <= 0) {
      return DriftStepResult(completed: completed, failed: failed);
    }
    final double delta = deltaSeconds.clamp(0, .025).toDouble();
    elapsedSeconds += delta;

    final DriftTrackProjection before = scenario.project(position);
    final double surfaceGrip = scenario.gripAt(before.progress);
    final double safeSteering = steering.clamp(-1, 1).toDouble();
    final double yawRate = (0.82 + speed * 3.4) * safeSteering;
    heading += yawRate * delta;

    final Offset forward = Offset(math.cos(heading), math.sin(heading));
    final Offset right = Offset(-forward.dy, forward.dx);
    double forwardSpeed = velocity.dx * forward.dx + velocity.dy * forward.dy;
    double lateralSpeed = velocity.dx * right.dx + velocity.dy * right.dy;

    if (braking) {
      forwardSpeed = math.max(0, forwardSpeed - .54 * delta);
    } else {
      // Auto-throttle keeps the short mobile run moving; braking and drift are
      // still deliberate player decisions rather than a tap-to-advance rail.
      forwardSpeed += .205 * delta;
    }
    final double lateralGrip = surfaceGrip * (handbrake ? .68 : 7.1);
    lateralSpeed *= math.exp(-lateralGrip * delta);
    forwardSpeed *= math.exp(-.20 * delta);
    forwardSpeed = forwardSpeed.clamp(0, .43).toDouble();
    lateralSpeed = lateralSpeed.clamp(-.31, .31).toDouble();
    velocity = forward * forwardSpeed + right * lateralSpeed;
    position += velocity * delta;

    final DriftTrackProjection after = scenario.project(position);
    final bool onTrack = after.distance <= scenario.trackWidth * .57;
    if (onTrack) {
      offTrackSeconds = math.max(0, offTrackSeconds - delta * 1.8);
    } else {
      offTrackSeconds += delta;
      velocity *= math.exp(-1.45 * delta);
    }

    final double previousDriftScore = driftScore;
    final double forwardNow =
        velocity.dx * forward.dx + velocity.dy * forward.dy;
    final double lateralNow = velocity.dx * right.dx + velocity.dy * right.dy;
    _driftAngle = math.atan2(
      lateralNow.abs(),
      math.max(.025, forwardNow.abs()),
    );
    isDrifting =
        handbrake &&
        onTrack &&
        speed >= .105 &&
        _driftAngle >= .16 &&
        _driftAngle <= .93;
    if (isDrifting) {
      driftChainSeconds += delta;
      final double angleQuality = ((_driftAngle - .12) / .58)
          .clamp(.22, 1.0)
          .toDouble();
      final double speedFactor = (speed / .25).clamp(.55, 1.42).toDouble();
      final double chainFactor = (1 + driftChainSeconds * .10)
          .clamp(1, 2.25)
          .toDouble();
      driftScore += delta * 76 * angleQuality * speedFactor * chainFactor;
    } else {
      driftChainSeconds = math.max(0, driftChainSeconds - delta * 1.8);
    }

    bool passedCheckpoint = false;
    if (checkpointsPassed < scenario.checkpointCount) {
      final double gateProgress =
          (checkpointsPassed + 1) / scenario.checkpointCount;
      if (_crossedProgressForward(
            before.progress,
            after.progress,
            gateProgress,
          ) &&
          after.distance <= scenario.trackWidth * .48) {
        checkpointsPassed++;
        passedCheckpoint = true;
        if (checkpointsPassed == scenario.checkpointCount) completed = true;
      }
    }

    bool recovered = false;
    if (offTrackSeconds >= 1.05) {
      recoveries++;
      recovered = true;
      offTrackSeconds = 0;
      final double progress = checkpointsPassed / scenario.checkpointCount;
      position = scenario.pointAt(progress);
      final Offset tangent = scenario.tangentAt(progress);
      heading = math.atan2(tangent.dy, tangent.dx);
      velocity = tangent * .105;
      driftChainSeconds = 0;
      isDrifting = false;
      if (recoveries > scenario.maximumRecoveries) failed = true;
    }

    return DriftStepResult(
      passedCheckpoint: passedCheckpoint,
      recovered: recovered,
      completed: completed,
      failed: failed,
      driftPoints: (driftScore - previousDriftScore).floor(),
    );
  }

  void reset() {
    position = scenario.pointAt(0);
    final Offset tangent = scenario.tangentAt(0);
    heading = math.atan2(tangent.dy, tangent.dx);
    velocity = tangent * .115;
    elapsedSeconds = 0;
    driftScore = 0;
    driftChainSeconds = 0;
    offTrackSeconds = 0;
    checkpointsPassed = 0;
    recoveries = 0;
    isDrifting = false;
    completed = false;
    failed = false;
    _driftAngle = 0;
  }

  bool _crossedProgressForward(
    double previousProgress,
    double currentProgress,
    double gateProgress,
  ) {
    double progressDelta = currentProgress - previousProgress;
    if (progressDelta < -.5) {
      progressDelta += 1;
    } else if (progressDelta > .5) {
      progressDelta -= 1;
    }
    if (progressDelta <= 0 || progressDelta > .025) return false;

    final double wrappedGateProgress =
        gateProgress - gateProgress.floorToDouble();
    double gateDistance = wrappedGateProgress - previousProgress;
    if (gateDistance < 0) gateDistance += 1;
    return gateDistance <= progressDelta;
  }
}
