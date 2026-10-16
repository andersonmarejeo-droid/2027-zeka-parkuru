import 'dart:math' as math;

import 'mini_golf_scenario.dart';

class GolfBall {
  GolfBall({required this.x, required this.y});

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double stoppedFor = 0;
}

class GolfStepResult {
  const GolfStepResult({
    required this.enteredHole,
    required this.gateBounce,
    required this.bumperHit,
    required this.inSand,
  });

  final bool enteredHole;
  final bool gateBounce;
  final bool bumperHit;
  final bool inSand;
}

class MiniGolfEngine {
  MiniGolfEngine({required this.scenario})
    : ball = GolfBall(x: scenario.start.x, y: scenario.start.y) {
    ball.stoppedFor = .25;
  }

  static const double ballRadius = .016;
  static const double cupRadius = .037;
  final MiniGolfScenario scenario;
  final GolfBall ball;
  double _gateCooldown = 0;

  bool get isSettled => ball.stoppedFor >= .20;

  bool strike({
    required double directionX,
    required double directionY,
    required double power,
    required int spin,
  }) {
    if (!isSettled) return false;
    final double magnitude = math.sqrt(
      directionX * directionX + directionY * directionY,
    );
    if (magnitude < .001) return false;
    final double dx = directionX / magnitude;
    final double dy = directionY / magnitude;
    final double shotPower = power.clamp(.16, .98).toDouble();
    ball
      ..vx = dx * shotPower
      ..vy = dy * shotPower
      ..vx += -dy * spin * .10
      ..vy += dx * spin * .10
      ..stoppedFor = 0;
    return true;
  }

  GolfStepResult step({
    required double deltaSeconds,
    required double worldHeight,
    required double elapsedSeconds,
  }) {
    final double delta = deltaSeconds.clamp(0, .022).toDouble();
    final double oldX = ball.x;
    final double oldY = ball.y;
    ball.vx += scenario.windX * delta;
    ball.vy += scenario.windY * delta;
    ball.x += ball.vx * delta;
    ball.y += ball.vy * delta;

    final bool inSand = _insideSand(ball.x, ball.y, worldHeight);
    final double drag = inSand ? scenario.sandDrag : scenario.grassDrag;
    final double damping = math.exp(-drag * delta);
    ball
      ..vx *= damping
      ..vy *= damping;

    bool gateBounce = false;
    final double gateY = scenario.gateY * worldHeight;
    final bool crossedGate =
        (oldY - gateY) * (ball.y - gateY) <= 0 && oldY != ball.y;
    if (crossedGate && _gateCooldown <= 0) {
      final double progress = (gateY - oldY) / (ball.y - oldY);
      final double crossingX = oldX + (ball.x - oldX) * progress;
      final double gapCenter = scenario.gateCenterAt(elapsedSeconds);
      if ((crossingX - gapCenter).abs() > scenario.gateWidth / 2 - ballRadius) {
        ball
          ..y = oldY + (gateY - oldY) * .94
          ..vy = -ball.vy.abs() * .57;
        _gateCooldown = .24;
        gateBounce = true;
      }
    }
    _gateCooldown = math.max(0, _gateCooldown - delta);

    bool bumperHit = false;
    for (final GolfBumper bumper in scenario.bumpers) {
      final double dx = ball.x - bumper.x;
      final double dy = ball.y - bumper.y * worldHeight;
      final double minimum = bumper.radius + ballRadius;
      final double distanceSquared = dx * dx + dy * dy;
      if (distanceSquared >= minimum * minimum) continue;
      final double distance = math.sqrt(math.max(.0001, distanceSquared));
      final double nx = dx / distance;
      final double ny = dy / distance;
      ball
        ..x = bumper.x + nx * minimum
        ..y = bumper.y * worldHeight + ny * minimum;
      final double normalSpeed = ball.vx * nx + ball.vy * ny;
      if (normalSpeed < 0) {
        ball
          ..vx -= 1.58 * normalSpeed * nx
          ..vy -= 1.58 * normalSpeed * ny;
      }
      bumperHit = true;
    }

    if (ball.x < .075 + ballRadius) {
      ball
        ..x = .075 + ballRadius
        ..vx = ball.vx.abs() * .64;
    } else if (ball.x > .925 - ballRadius) {
      ball
        ..x = .925 - ballRadius
        ..vx = -ball.vx.abs() * .64;
    }
    if (ball.y < .075 + ballRadius) {
      ball
        ..y = .075 + ballRadius
        ..vy = ball.vy.abs() * .64;
    } else if (ball.y > worldHeight - .075 - ballRadius) {
      ball
        ..y = worldHeight - .075 - ballRadius
        ..vy = -ball.vy.abs() * .64;
    }

    double speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
    bool enteredHole = false;
    final double holeX = ball.x - scenario.hole.x;
    final double holeY = ball.y - scenario.hole.y * worldHeight;
    final double holeDistance = math.sqrt(holeX * holeX + holeY * holeY);
    if (holeDistance < cupRadius && speed < .23) {
      enteredHole = true;
      ball
        ..x = scenario.hole.x
        ..y = scenario.hole.y * worldHeight
        ..vx = 0
        ..vy = 0
        ..stoppedFor = .25;
    } else if (holeDistance < cupRadius && speed >= .23) {
      final double nx = holeX / math.max(.001, holeDistance);
      final double ny = holeY / math.max(.001, holeDistance);
      final double towardHole = ball.vx * nx + ball.vy * ny;
      if (towardHole < 0) {
        ball
          ..vx -= 1.42 * towardHole * nx
          ..vy -= 1.42 * towardHole * ny;
      }
    }

    speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
    if (speed < .024) {
      ball
        ..vx = 0
        ..vy = 0
        ..stoppedFor += delta;
    } else {
      ball.stoppedFor = 0;
    }
    return GolfStepResult(
      enteredHole: enteredHole,
      gateBounce: gateBounce,
      bumperHit: bumperHit,
      inSand: inSand,
    );
  }

  bool _insideSand(double x, double y, double worldHeight) =>
      scenario.sand.any((GolfPatch patch) {
        final double dx = (x - patch.x) / (patch.width / 2);
        final double dy = (y / worldHeight - patch.y) / (patch.height / 2);
        return dx * dx + dy * dy <= 1;
      });

  void reset() {
    ball
      ..x = scenario.start.x
      ..y = scenario.start.y
      ..vx = 0
      ..vy = 0
      ..stoppedFor = .25;
    _gateCooldown = 0;
  }
}
