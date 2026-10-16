import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'deep_current_scenario.dart';

class DeepCurrentStepResult {
  const DeepCurrentStepResult({
    this.collision = false,
    this.resourceWarning = false,
    this.failed = false,
  });

  final bool collision;
  final bool resourceWarning;
  final bool failed;
}

class DeepCurrentActionResult {
  const DeepCurrentActionResult({
    this.accepted = false,
    this.revealed = 0,
    this.collected = false,
    this.docked = false,
  });

  final bool accepted;
  final int revealed;
  final bool collected;
  final bool docked;
}

/// Fixed-step-feel submarine motion and mission-resource simulation.
class DeepCurrentEngine {
  DeepCurrentEngine({required this.scenario})
    : position = DeepCurrentScenario.base,
      oxygen = scenario.oxygenCapacity,
      battery = scenario.batteryCapacity,
      hull = scenario.hullCapacity,
      _collected = List<bool>.filled(scenario.salvage.length, false),
      _revealUntil = List<double>.filled(scenario.salvage.length, 0);

  final DeepCurrentScenario scenario;
  final List<bool> _collected;
  final List<double> _revealUntil;
  Offset position;
  Offset velocity = Offset.zero;
  double oxygen;
  double battery;
  double hull;
  double elapsed = 0;
  double pingCooldown = 0;
  double _collisionCooldown = 0;
  bool failed = false;
  bool completed = false;

  int get collectedCount => _collected.where((bool value) => value).length;
  int get remainingCount => _collected.length - collectedCount;
  double get cargoMass =>
      <int>[
        for (int i = 0; i < _collected.length; i++)
          if (_collected[i]) i,
      ].fold<double>(
        0,
        (double total, int index) => total + scenario.salvage[index].mass,
      );
  bool get allCollected => remainingCount == 0;
  double get depth => ((position.dy - .52) / .34).clamp(0, 1).toDouble();
  double get pressure => depth;
  double get dockDistance => (position - DeepCurrentScenario.base).distance;
  List<int> get revealedTargets => <int>[
    for (int i = 0; i < _collected.length; i++)
      if (!_collected[i] && _revealUntil[i] > elapsed) i,
  ];
  List<int> get collectedTargets => <int>[
    for (int i = 0; i < _collected.length; i++)
      if (_collected[i]) i,
  ];
  bool get canPing =>
      !failed && !completed && pingCooldown <= 0 && battery >= 4.5;

  Offset currentAt(Offset point) {
    Offset current = Offset.zero;
    for (final DeepCurrentFlow flow in scenario.currents) {
      final double distance = (point - flow.center).distance;
      if (distance >= flow.radius) continue;
      final double strength = (1 - distance / flow.radius) * .72;
      current += flow.force * strength;
    }
    return current;
  }

  DeepCurrentStepResult step(double deltaSeconds, Offset steering) {
    if (failed || completed || deltaSeconds <= 0) {
      return DeepCurrentStepResult(failed: failed);
    }
    final double total = deltaSeconds.clamp(0, .10).toDouble();
    final int steps = math.max(1, (total / (1 / 60)).ceil());
    final double dt = total / steps;
    bool collided = false;
    for (int index = 0; index < steps; index++) {
      elapsed += dt;
      pingCooldown = math.max(0, pingCooldown - dt);
      _collisionCooldown = math.max(0, _collisionCooldown - dt);
      final Offset oldPosition = position;
      final Offset input = steering.distance > 1
          ? steering / steering.distance
          : steering;
      final double cargoFactor = (1 - cargoMass * .20).clamp(.72, 1).toDouble();
      final Offset desiredVelocity = input * (scenario.subSpeed * cargoFactor);
      final double response = 1 - math.exp(-3.6 * dt);
      velocity = Offset.lerp(velocity, desiredVelocity, response)!;
      velocity += currentAt(position) * dt;
      position = position + velocity * dt;
      position = Offset(
        position.dx.clamp(.045, .955).toDouble(),
        position.dy.clamp(.105, .895).toDouble(),
      );
      final double propulsion = input.distance;
      battery -=
          dt *
          (.50 +
              propulsion * 1.10 +
              currentAt(position).distance * 2.1 +
              cargoMass * .18);
      oxygen -= dt * (.62 + depth * .55 + cargoMass * .12);
      if (depth > scenario.safeDepth) {
        hull -= (depth - scenario.safeDepth) * 13 * dt;
      }
      if (_collidesWithReef(position) && _collisionCooldown <= 0) {
        collided = true;
        hull -= 19;
        _collisionCooldown = 1.1;
        position = oldPosition;
        velocity = velocity * -.18;
      }
      if (oxygen <= 0 || battery <= 0 || hull <= 0) {
        oxygen = math.max(0, oxygen);
        battery = math.max(0, battery);
        hull = math.max(0, hull);
        failed = true;
        break;
      }
    }
    return DeepCurrentStepResult(
      collision: collided,
      resourceWarning:
          oxygen < scenario.oxygenCapacity * .2 ||
          battery < scenario.batteryCapacity * .2 ||
          hull < 35,
      failed: failed,
    );
  }

  DeepCurrentActionResult ping() {
    if (!canPing) return const DeepCurrentActionResult();
    battery = math.max(0, battery - 4.5);
    pingCooldown = 2.4;
    int revealed = 0;
    for (int index = 0; index < scenario.salvage.length; index++) {
      if (_collected[index]) continue;
      final double distance =
          (scenario.salvage[index].position - position).distance;
      if (distance > scenario.sonarRange) continue;
      _revealUntil[index] = elapsed + 8.0;
      revealed++;
    }
    return DeepCurrentActionResult(accepted: true, revealed: revealed);
  }

  DeepCurrentActionResult collect() {
    if (failed || completed) return const DeepCurrentActionResult();
    int nearest = -1;
    double nearestDistance = .072;
    for (int index = 0; index < scenario.salvage.length; index++) {
      if (_collected[index] || _revealUntil[index] <= elapsed) continue;
      final double distance =
          (scenario.salvage[index].position - position).distance;
      if (distance <= nearestDistance) {
        nearest = index;
        nearestDistance = distance;
      }
    }
    if (nearest < 0) return const DeepCurrentActionResult();
    _collected[nearest] = true;
    return const DeepCurrentActionResult(accepted: true, collected: true);
  }

  DeepCurrentActionResult dock() {
    if (failed || completed || !allCollected || dockDistance > .115) {
      return const DeepCurrentActionResult();
    }
    completed = true;
    return const DeepCurrentActionResult(accepted: true, docked: true);
  }

  bool _collidesWithReef(Offset point) => scenario.reefs.any(
    (DeepCurrentReef reef) =>
        (point - reef.center).distance < reef.radius + .024,
  );
}
