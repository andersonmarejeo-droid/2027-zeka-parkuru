import 'dart:math' as math;

import 'magnet_path_scenario.dart';

class MagneticPuck {
  MagneticPuck({required this.x, required this.y});

  double x;
  double y;
  double vx = 0;
  double vy = 0;
}

class MagnetStepResult {
  const MagnetStepResult({required this.gatesReached, required this.collided});

  final List<int> gatesReached;
  final bool collided;
}

class MagnetPathEngine {
  MagnetPathEngine({required this.scenario}) : puck = MagneticPuck(
    x: scenario.start.x,
    y: scenario.start.y,
  );

  final MagnetPathScenario scenario;
  final MagneticPuck puck;
  int nextGate = 0;
  double collisionCooldown = 0;

  MagnetStepResult step({
    required double deltaSeconds,
    required double worldHeight,
    required double magnetX,
    required double magnetY,
    required bool attract,
  }) {
    final double delta = deltaSeconds.clamp(0, .025).toDouble();
    final double dx = magnetX - puck.x;
    final double dy = magnetY - puck.y;
    final double distanceSquared = dx * dx + dy * dy + .035;
    final double distance = math.sqrt(distanceSquared);
    final double direction = attract ? 1 : -1;
    final double acceleration = scenario.fieldStrength / distanceSquared;
    puck.vx += dx / distance * acceleration * direction * delta;
    puck.vy += dy / distance * acceleration * direction * delta;
    final double damping = math.pow(1 - scenario.coast, delta).toDouble();
    puck.vx *= damping;
    puck.vy *= damping;
    final double speed = math.sqrt(puck.vx * puck.vx + puck.vy * puck.vy);
    if (speed > scenario.speedLimit) {
      final double scale = scenario.speedLimit / speed;
      puck.vx *= scale;
      puck.vy *= scale;
    }
    puck.x += puck.vx * delta;
    puck.y += puck.vy * delta;

    if (puck.x < .085) {
      puck.x = .085;
      puck.vx = puck.vx.abs() * .48;
    } else if (puck.x > .915) {
      puck.x = .915;
      puck.vx = -puck.vx.abs() * .48;
    }
    final double yMin = .08;
    final double yMax = worldHeight - .08;
    if (puck.y < yMin) {
      puck.y = yMin;
      puck.vy = puck.vy.abs() * .48;
    } else if (puck.y > yMax) {
      puck.y = yMax;
      puck.vy = -puck.vy.abs() * .48;
    }

    collisionCooldown = math.max(0, collisionCooldown - delta);
    bool collided = false;
    for (final MagnetBaffle baffle in scenario.baffles) {
      final double by = baffle.y * worldHeight;
      final double ox = puck.x - baffle.x;
      final double oy = puck.y - by;
      final double minDistance = baffle.radius + .026;
      final double d2 = ox * ox + oy * oy;
      if (d2 >= minDistance * minDistance) continue;
      final double d = math.sqrt(math.max(.0001, d2));
      final double nx = ox / d;
      final double ny = oy / d;
      puck.x = baffle.x + nx * minDistance;
      puck.y = by + ny * minDistance;
      final double dot = puck.vx * nx + puck.vy * ny;
      if (dot < 0) {
        puck.vx -= 1.45 * dot * nx;
        puck.vy -= 1.45 * dot * ny;
      }
      collided = true;
      if (collisionCooldown <= 0) collisionCooldown = .48;
    }

    final List<int> reached = <int>[];
    if (nextGate < scenario.gates.length) {
      final MagnetPoint gate = scenario.gates[nextGate];
      final double gx = puck.x - gate.x;
      final double gy = puck.y - gate.y * worldHeight;
      if (gx * gx + gy * gy <= scenario.gateRadius * scenario.gateRadius) {
        reached.add(nextGate);
        nextGate++;
      }
    }
    return MagnetStepResult(gatesReached: reached, collided: collided && collisionCooldown >= .47);
  }

  void reset() {
    puck
      ..x = scenario.start.x
      ..y = scenario.start.y
      ..vx = 0
      ..vy = 0;
    nextGate = 0;
    collisionCooldown = 0;
  }
}
