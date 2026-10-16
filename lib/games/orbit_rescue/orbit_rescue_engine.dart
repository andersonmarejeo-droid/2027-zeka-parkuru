import 'dart:math' as math;

import 'orbit_rescue_scenario.dart';

class OrbitStepResult {
  const OrbitStepResult({
    this.cleared = 0,
    this.missed = 0,
    this.collision = false,
    this.docked = false,
    this.failed = false,
  });

  final int cleared;
  final int missed;
  final bool collision;
  final bool docked;
  final bool failed;
}

/// Deterministic, fixed-substep three-body flight and rescue gate simulation.
class OrbitRescueEngine {
  OrbitRescueEngine({required this.scenario})
    : fuel = scenario.fuelCapacity,
      shield = scenario.shieldCapacity;

  final OrbitRescueScenario scenario;
  double x = .075;
  double y = .5;
  double velocityX = .158;
  double velocityY = 0;
  double fuel;
  double shield;
  double thrustX = 0;
  double thrustY = 0;
  double elapsed = 0;
  int nextGate = 0;
  int misses = 0;
  int pulsesUsed = 0;
  int gatesCleared = 0;
  int bestCombo = 0;
  int combo = 0;
  bool completed = false;
  bool failed = false;

  List<bool> _cleared = <bool>[];
  List<bool> get clearedGates => List<bool>.unmodifiable(_cleared);
  OrbitGate? get currentGate =>
      nextGate < scenario.gates.length ? scenario.gates[nextGate] : null;
  double get targetY {
    final OrbitGate? gate = currentGate;
    if (gate == null) return .5;
    final double timeToGate = ((gate.x - x) / math.max(.08, velocityX))
        .clamp(0, .9)
        .toDouble();
    return gate.yAt(elapsed + timeToGate);
  }

  double get speed => math.sqrt(velocityX * velocityX + velocityY * velocityY);
  double get accuracy => gatesCleared / math.max(1, scenario.gates.length);

  void setControl({required double x, required double y}) {
    if (completed || failed) return;
    double cx = x.clamp(-1, 1).toDouble();
    double cy = y.clamp(-1, 1).toDouble();
    final double magnitude = math.sqrt(cx * cx + cy * cy);
    if (magnitude > 1) {
      cx /= magnitude;
      cy /= magnitude;
    }
    thrustX = cx;
    thrustY = cy;
  }

  bool pulse() {
    if (completed || failed || pulsesUsed >= scenario.pulseLimit || fuel < 6) {
      return false;
    }
    double dx = thrustX;
    double dy = thrustY;
    if (dx.abs() + dy.abs() < .08) {
      final OrbitGate? target = currentGate;
      if (target == null) return false;
      dx = target.x - x;
      dy = target.yAt(elapsed + .35) - y;
      final double length = math.sqrt(dx * dx + dy * dy);
      if (length > 0) {
        dx /= length;
        dy /= length;
      }
    }
    velocityX += dx * .105;
    velocityY += dy * .105;
    fuel = math.max(0, fuel - 6);
    pulsesUsed++;
    return true;
  }

  OrbitStepResult step(double deltaSeconds) {
    final double frame = deltaSeconds.clamp(0, .04).toDouble();
    if (frame <= 0 || completed || failed) return const OrbitStepResult();
    final int steps = math.max(1, (frame / (1 / 120)).ceil());
    final double dt = frame / steps;
    int cleared = 0;
    int missed = 0;
    bool collision = false;
    bool docked = false;
    for (int substep = 0; substep < steps; substep++) {
      elapsed += dt;
      final (double gravityX, double gravityY) = _gravityAt(x, y);
      final double inputMagnitude = math.sqrt(
        thrustX * thrustX + thrustY * thrustY,
      );
      if (inputMagnitude > .02 && fuel > 0) {
        velocityX += thrustX * .255 * dt;
        velocityY += thrustY * .255 * dt;
        fuel = math.max(0, fuel - inputMagnitude * 2.1 * dt);
      }
      velocityX += gravityX * dt;
      velocityY += gravityY * dt;
      final double drag = math.exp(-.025 * dt);
      velocityX *= drag;
      velocityY *= drag;
      velocityX = velocityX.clamp(-.42, .42).toDouble();
      velocityY = velocityY.clamp(-.42, .42).toDouble();
      x += velocityX * dt;
      y += velocityY * dt;

      for (final OrbitBody body in scenario.bodies) {
        final double dx = x - body.x;
        final double dy = y - body.y;
        final double distance = math.sqrt(dx * dx + dy * dy);
        if (distance < body.radius + .018) {
          collision = true;
          shield = math.max(0, shield - 22);
          misses++;
          combo = 0;
          final double safeDistance = body.radius + .021;
          final double nx = distance == 0 ? 1 : dx / distance;
          final double ny = distance == 0 ? 0 : dy / distance;
          x = body.x + nx * safeDistance;
          y = body.y + ny * safeDistance;
          final double toward = velocityX * nx + velocityY * ny;
          if (toward < 0) {
            velocityX -= nx * toward * 1.55;
            velocityY -= ny * toward * 1.55;
          }
          break;
        }
      }
      if (y < .045 || y > .955 || x < .018) {
        collision = true;
        shield = math.max(0, shield - 14);
        misses++;
        combo = 0;
        y = y.clamp(.05, .95).toDouble();
        x = math.max(.025, x);
        velocityY *= -.36;
        velocityX = math.max(.04, velocityX * .55);
      }
      if (misses > scenario.missLimit || shield <= 0 || x > .985) {
        failed = true;
        break;
      }

      while (nextGate < scenario.gates.length &&
          x >= scenario.gates[nextGate].x) {
        final OrbitGate gate = scenario.gates[nextGate];
        final bool aligned =
            (y - gate.yAt(elapsed)).abs() <= gate.radius &&
            (x - gate.x).abs() <= gate.radius * 1.15;
        final bool controlled = speed <= gate.safeSpeed;
        if (aligned && controlled) {
          _markCleared(nextGate);
          nextGate++;
          gatesCleared++;
          combo++;
          bestCombo = math.max(bestCombo, combo);
          cleared++;
          if (gate.docking) {
            completed = true;
            docked = true;
          }
        } else {
          _markCleared(nextGate);
          nextGate++;
          misses++;
          combo = 0;
          shield = math.max(0, shield - 16);
          missed++;
          if (misses > scenario.missLimit || shield <= 0 || gate.docking) {
            failed = true;
          }
        }
        if (completed || failed) break;
      }
      if (completed || failed) break;
    }
    return OrbitStepResult(
      cleared: cleared,
      missed: missed,
      collision: collision,
      docked: docked,
      failed: failed,
    );
  }

  (double, double) _gravityAt(double px, double py) {
    double ax = 0;
    double ay = 0;
    for (final OrbitBody body in scenario.bodies) {
      final double dx = body.x - px;
      final double dy = body.y - py;
      final double distanceSquared = dx * dx + dy * dy;
      final double inverse = 1 / math.pow(distanceSquared + .006, 1.5);
      ax += dx * body.gravity * inverse;
      ay += dy * body.gravity * inverse;
    }
    final double magnitude = math.sqrt(ax * ax + ay * ay);
    if (magnitude > .19) {
      ax *= .19 / magnitude;
      ay *= .19 / magnitude;
    }
    return (ax, ay);
  }

  void _markCleared(int index) {
    if (_cleared.length != scenario.gates.length) {
      _cleared = List<bool>.filled(scenario.gates.length, false);
    }
    _cleared[index] = true;
  }

  void reset() {
    x = .075;
    y = .5;
    velocityX = .158;
    velocityY = 0;
    fuel = scenario.fuelCapacity;
    shield = scenario.shieldCapacity;
    thrustX = 0;
    thrustY = 0;
    elapsed = 0;
    nextGate = 0;
    misses = 0;
    pulsesUsed = 0;
    gatesCleared = 0;
    bestCombo = 0;
    combo = 0;
    completed = false;
    failed = false;
    _cleared = <bool>[];
  }
}
