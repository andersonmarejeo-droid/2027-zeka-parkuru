import 'dart:math' as math;

import 'ring_toss_scenario.dart';

class RingProjectile {
  RingProjectile() : x = .5, y = .84;

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double spin = 0;
  double flightSeconds = 0;
  int floorBounces = 0;
  bool inFlight = false;
}

class RingTossStepResult {
  const RingTossStepResult({
    this.captured = false,
    this.missed = false,
    this.pegBounce = false,
    this.bumperHit = false,
  });

  final bool captured;
  final bool missed;
  final bool pegBounce;
  final bool bumperHit;
}

/// Normalized, deterministic side-view ring flight and target capture.
class RingTossEngine {
  RingTossEngine({required this.scenario}) : ring = RingProjectile();

  static const RingPoint startPoint = RingPoint(.5, .84);
  static const double ringRadius = .024;
  static const double pegRadius = .009;
  final RingTossScenario scenario;
  RingProjectile? ring;
  int targetIndex = 0;
  int captures = 0;
  int misses = 0;
  int bumperHits = 0;
  int pegBounces = 0;
  double elapsedSeconds = 0;
  double _respawnDelay = 0;
  double _pegCooldown = 0;

  bool get isComplete => targetIndex >= scenario.targetCount;
  bool get canThrow => !isComplete && ring != null && !ring!.inFlight;
  RingTarget? get currentTarget =>
      isComplete ? null : scenario.targets[targetIndex];
  RingPoint? get currentTargetPosition =>
      isComplete ? null : scenario.targetAt(targetIndex, elapsedSeconds);

  bool launch({
    required double directionX,
    required double directionY,
    required double power,
    required int spin,
  }) {
    if (!canThrow || spin < -1 || spin > 1) return false;
    final double length = math.sqrt(
      directionX * directionX + directionY * directionY,
    );
    if (length < .001) return false;
    final double strength = power.clamp(.18, 1).toDouble() * 1.5;
    final RingProjectile projectile = ring!;
    projectile
      ..x = startPoint.x
      ..y = startPoint.y
      ..vx = directionX / length * strength
      ..vy = directionY / length * strength
      ..spin = spin.toDouble()
      ..flightSeconds = 0
      ..floorBounces = 0
      ..inFlight = true;
    return true;
  }

  RingTossStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .024).toDouble();
    if (delta == 0 || isComplete) return const RingTossStepResult();
    elapsedSeconds += delta;
    _pegCooldown = math.max(0, _pegCooldown - delta);
    if (ring == null) {
      _respawnDelay -= delta;
      if (_respawnDelay <= 0 && !isComplete) ring = RingProjectile();
      return const RingTossStepResult();
    }
    final RingProjectile projectile = ring!;
    if (!projectile.inFlight) return const RingTossStepResult();

    projectile.flightSeconds += delta;
    final double oldX = projectile.x;
    final double oldY = projectile.y;
    final RingPoint wind = scenario.windAt(elapsedSeconds);
    projectile
      ..vx += (wind.x + projectile.spin * .018) * delta
      ..vy += (scenario.gravity + wind.y - projectile.spin.abs() * .004) * delta
      ..x += projectile.vx * delta
      ..y += projectile.vy * delta;

    bool bumperHit = false;
    for (final RingBumper bumper in scenario.bumpers) {
      final double dx = projectile.x - bumper.x;
      final double dy = projectile.y - bumper.y;
      final double distance = math.sqrt(dx * dx + dy * dy);
      final double contact = bumper.radius + ringRadius;
      if (distance < contact && distance > .0001) {
        final double nx = dx / distance;
        final double ny = dy / distance;
        final double normalSpeed = projectile.vx * nx + projectile.vy * ny;
        if (normalSpeed < 0) {
          projectile
            ..vx -= 1.72 * normalSpeed * nx
            ..vy -= 1.72 * normalSpeed * ny
            ..x = bumper.x + nx * contact
            ..y = bumper.y + ny * contact;
          bumperHits++;
          bumperHit = true;
          break;
        }
      }
    }

    bool pegBounce = false;
    if (_pegCooldown <= 0 && currentTarget != null) {
      final RingPoint peg = currentTargetPosition!;
      final double dx = projectile.x - peg.x;
      final double dy = projectile.y - peg.y;
      final double distance = math.sqrt(dx * dx + dy * dy);
      final double captureRadius = currentTarget!.radius;
      final double speed = math.sqrt(
        projectile.vx * projectile.vx + projectile.vy * projectile.vy,
      );
      if (distance <= captureRadius && speed <= currentTarget!.captureSpeed) {
        captures++;
        targetIndex++;
        ring = null;
        _respawnDelay = .34;
        return RingTossStepResult(captured: true, bumperHit: bumperHit);
      }
      if (distance <= pegRadius + ringRadius && distance > .0001) {
        final double nx = dx / distance;
        final double ny = dy / distance;
        final double normalSpeed = projectile.vx * nx + projectile.vy * ny;
        if (normalSpeed < 0) {
          projectile
            ..vx -= 1.58 * normalSpeed * nx
            ..vy -= 1.58 * normalSpeed * ny
            ..x = peg.x + nx * (pegRadius + ringRadius)
            ..y = peg.y + ny * (pegRadius + ringRadius);
          pegBounces++;
          _pegCooldown = .16;
          pegBounce = true;
        }
      }
    }

    if (projectile.y >= .93) {
      projectile
        ..y = .93
        ..vy = -projectile.vy.abs() * .34
        ..vx *= .70;
      projectile.floorBounces++;
      if (projectile.vy.abs() < .10 || projectile.floorBounces >= 4) {
        misses++;
        ring = null;
        _respawnDelay = .34;
        return RingTossStepResult(
          missed: true,
          pegBounce: pegBounce,
          bumperHit: bumperHit,
        );
      }
    }

    if (projectile.x < .025 || projectile.x > .975) {
      projectile
        ..x = projectile.x.clamp(.025, .975).toDouble()
        ..vx = -projectile.vx * .54;
      bumperHits++;
      bumperHit = true;
    }
    if (projectile.y < .025 ||
        projectile.flightSeconds > 4.2 ||
        (projectile.x == oldX && projectile.y == oldY)) {
      misses++;
      ring = null;
      _respawnDelay = .34;
      return RingTossStepResult(
        missed: true,
        pegBounce: pegBounce,
        bumperHit: bumperHit,
      );
    }
    return RingTossStepResult(pegBounce: pegBounce, bumperHit: bumperHit);
  }
}
