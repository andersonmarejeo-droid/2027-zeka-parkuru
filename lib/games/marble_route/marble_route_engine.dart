import 'dart:math' as math;

import 'marble_route_scenario.dart';

class RouteMarble {
  RouteMarble({required this.x, required this.y});

  double x;
  double y;
  double vx = 0;
  double vy = 0;
}

class MarbleStepResult {
  const MarbleStepResult({
    this.gatePassed = false,
    this.gateBounced = false,
    this.bumperHit = false,
    this.fell = false,
    this.reachedGoal = false,
    this.surfaceChanged = false,
  });

  final bool gatePassed;
  final bool gateBounced;
  final bool bumperHit;
  final bool fell;
  final bool reachedGoal;
  final bool surfaceChanged;
}

/// Fixed-delta board physics. Touch tilt and device motion can share setTilt.
class MarbleRouteEngine {
  MarbleRouteEngine({required this.scenario})
    : marble = RouteMarble(x: scenario.start.x, y: scenario.start.y),
      _checkpointX = scenario.start.x,
      _checkpointY = scenario.start.y;

  static const double marbleRadius = .019;
  static const double goalRadius = .044;

  final MarbleRouteScenario scenario;
  final RouteMarble marble;
  double elapsedSeconds = 0;
  double tiltX = 0;
  double tiltY = 0;
  int nextGate = 0;
  int misses = 0;
  int bumpHits = 0;
  bool isComplete = false;
  MarbleSurfaceKind currentSurface = MarbleSurfaceKind.felt;
  double _checkpointX;
  double _checkpointY;
  double _gateCooldown = 0;
  double _bumperCooldown = 0;
  double _fallCooldown = 0;
  double _goalBounceCooldown = 0;

  double get speed => math.sqrt(marble.vx * marble.vx + marble.vy * marble.vy);
  bool get allGatesPassed => nextGate >= scenario.gates.length;

  void setTilt(double x, double y) {
    tiltX = x.clamp(-1, 1).toDouble();
    tiltY = y.clamp(-1, 1).toDouble();
  }

  MarbleStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .024).toDouble();
    if (delta == 0 || isComplete) return const MarbleStepResult();
    elapsedSeconds += delta;
    _gateCooldown = math.max(0, _gateCooldown - delta);
    _bumperCooldown = math.max(0, _bumperCooldown - delta);
    _fallCooldown = math.max(0, _fallCooldown - delta);
    _goalBounceCooldown = math.max(0, _goalBounceCooldown - delta);

    final MarbleSurface? surface = _surfaceAt(marble.x, marble.y);
    final MarbleSurfaceKind nextSurface =
        surface?.kind ?? MarbleSurfaceKind.felt;
    final bool surfaceChanged = nextSurface != currentSurface;
    currentSurface = nextSurface;
    final double drag = surface?.drag ?? .82;
    final double flowX = surface?.flowX ?? 0;
    final double flowY = surface?.flowY ?? 0;
    marble
      ..vx += (tiltX * scenario.tiltResponse + flowX) * delta
      ..vy += (tiltY * scenario.tiltResponse + flowY) * delta;
    final double damping = math.exp(-drag * delta);
    marble
      ..vx *= damping
      ..vy *= damping;
    final double velocity = speed;
    if (velocity > .74) {
      marble
        ..vx *= .74 / velocity
        ..vy *= .74 / velocity;
    }

    final double oldX = marble.x;
    final double oldY = marble.y;
    marble
      ..x += marble.vx * delta
      ..y += marble.vy * delta;
    _collideWithRails();

    final MarbleStepResult? gateResult = _collideWithGate(oldX, oldY, delta);
    if (gateResult?.gatePassed ?? false) {
      return MarbleStepResult(gatePassed: true, surfaceChanged: surfaceChanged);
    }
    final bool bumperHit = _collideWithBumpers();
    if (bumperHit) {
      bumpHits++;
      return MarbleStepResult(bumperHit: true, surfaceChanged: surfaceChanged);
    }
    if (_fellIntoPit()) {
      misses++;
      _restoreCheckpoint();
      return MarbleStepResult(fell: true, surfaceChanged: surfaceChanged);
    }
    final bool reachedGoal = _tryGoal();
    return MarbleStepResult(
      gateBounced: gateResult?.gateBounced ?? false,
      reachedGoal: reachedGoal,
      surfaceChanged: surfaceChanged,
    );
  }

  MarbleSurface? _surfaceAt(double x, double y) {
    for (final MarbleSurface surface in scenario.surfaces) {
      if (surface.contains(x, y)) return surface;
    }
    return null;
  }

  void _collideWithRails() {
    const double left = .075 + marbleRadius;
    const double right = .925 - marbleRadius;
    const double top = .055 + marbleRadius;
    const double bottom = .945 - marbleRadius;
    if (marble.x < left) {
      marble
        ..x = left
        ..vx = marble.vx.abs() * .62;
    } else if (marble.x > right) {
      marble
        ..x = right
        ..vx = -marble.vx.abs() * .62;
    }
    if (marble.y < top) {
      marble
        ..y = top
        ..vy = marble.vy.abs() * .62;
    } else if (marble.y > bottom) {
      marble
        ..y = bottom
        ..vy = -marble.vy.abs() * .62;
    }
  }

  MarbleStepResult? _collideWithGate(double oldX, double oldY, double delta) {
    if (nextGate >= scenario.gates.length || _gateCooldown > 0) return null;
    final MarbleGate gate = scenario.gates[nextGate];
    final bool crossed =
        (oldY - gate.y) * (marble.y - gate.y) <= 0 && oldY != marble.y;
    if (!crossed) return null;
    final double amount = (gate.y - oldY) / (marble.y - oldY);
    final double crossingX = oldX + (marble.x - oldX) * amount;
    final double crossingTime = elapsedSeconds - delta + amount * delta;
    final double apertureCenter = gate.centerAt(crossingTime);
    final bool fits =
        (crossingX - apertureCenter).abs() <= gate.width / 2 - marbleRadius;
    if (!fits) {
      final bool movingUp = marble.y < oldY;
      marble
        ..y = oldY + (gate.y - oldY) * .86
        ..vy = movingUp ? marble.vy.abs() * .58 : -marble.vy.abs() * .58;
      _gateCooldown = .18;
      return const MarbleStepResult(gateBounced: true);
    }
    if (marble.y < oldY) {
      nextGate++;
      _checkpointX = crossingX.clamp(.12, .88).toDouble();
      _checkpointY = math.max(.075 + marbleRadius, gate.y - .043);
      marble.y = math.min(marble.y, _checkpointY);
      return const MarbleStepResult(gatePassed: true);
    }
    return null;
  }

  bool _collideWithBumpers() {
    for (final MarbleBumper bumper in scenario.bumpers) {
      final double dx = marble.x - bumper.center.x;
      final double dy = marble.y - bumper.center.y;
      final double minDistance = marbleRadius + bumper.radius;
      final double distanceSquared = dx * dx + dy * dy;
      if (distanceSquared >= minDistance * minDistance) continue;
      final double distance = math.sqrt(math.max(.0001, distanceSquared));
      final double nx = dx / distance;
      final double ny = dy / distance;
      marble
        ..x = bumper.center.x + nx * minDistance
        ..y = bumper.center.y + ny * minDistance;
      final double normalSpeed = marble.vx * nx + marble.vy * ny;
      if (normalSpeed < 0) {
        marble
          ..vx -= 1.55 * normalSpeed * nx
          ..vy -= 1.55 * normalSpeed * ny;
      }
      if (_bumperCooldown <= 0) {
        _bumperCooldown = .12;
        return true;
      }
    }
    return false;
  }

  bool _fellIntoPit() {
    if (_fallCooldown > 0) return false;
    for (final MarblePit pit in scenario.pits) {
      final double dx = marble.x - pit.center.x;
      final double dy = marble.y - pit.center.y;
      if (dx * dx + dy * dy < pit.radius * pit.radius) return true;
    }
    return false;
  }

  void _restoreCheckpoint() {
    marble
      ..x = _checkpointX
      ..y = _checkpointY
      ..vx = 0
      ..vy = 0;
    setTilt(0, 0);
    _fallCooldown = .65;
  }

  bool _tryGoal() {
    if (!allGatesPassed) return false;
    final double dx = marble.x - scenario.goal.x;
    final double dy = marble.y - scenario.goal.y;
    final double distance = math.sqrt(dx * dx + dy * dy);
    if (distance >= goalRadius) return false;
    if (speed <= .28) {
      isComplete = true;
      marble
        ..x = scenario.goal.x
        ..y = scenario.goal.y
        ..vx = 0
        ..vy = 0;
      setTilt(0, 0);
      return true;
    }
    if (_goalBounceCooldown <= 0 && distance > .001) {
      final double nx = dx / distance;
      final double ny = dy / distance;
      final double towardGoal = marble.vx * nx + marble.vy * ny;
      if (towardGoal < 0) {
        marble
          ..vx -= 1.42 * towardGoal * nx
          ..vy -= 1.42 * towardGoal * ny;
      }
      _goalBounceCooldown = .18;
    }
    return false;
  }

  void reset() {
    marble
      ..x = scenario.start.x
      ..y = scenario.start.y
      ..vx = 0
      ..vy = 0;
    elapsedSeconds = 0;
    nextGate = 0;
    misses = 0;
    bumpHits = 0;
    isComplete = false;
    currentSurface = MarbleSurfaceKind.felt;
    _checkpointX = scenario.start.x;
    _checkpointY = scenario.start.y;
    _gateCooldown = 0;
    _bumperCooldown = 0;
    _fallCooldown = 0;
    _goalBounceCooldown = 0;
    setTilt(0, 0);
  }
}
