import 'dart:math' as math;

import 'neon_pinball_scenario.dart';

class PinballOrb {
  PinballOrb({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.radius = .018,
  });

  double x;
  double y;
  double vx;
  double vy;
  final double radius;
}

class PinballStepResult {
  const PinballStepResult({
    this.targetHit,
    this.wrongTargetHit = false,
    this.bumperHit = false,
    this.flipperHit = false,
    this.drained = false,
    this.multiballStarted = false,
    this.completed = false,
    this.failed = false,
  });

  final int? targetHit;
  final bool wrongTargetHit;
  final bool bumperHit;
  final bool flipperHit;
  final bool drained;
  final bool multiballStarted;
  final bool completed;
  final bool failed;
}

/// Small fixed-step pinball model in normalized table coordinates.
///
/// The ball has independent momentum; targets must be struck in lit order.
/// At levels 9–10 the lock target releases a second orb for true multiball.
class NeonPinballEngine {
  static const double _tableAspect = 1.32;

  NeonPinballEngine({required this.scenario});

  final NeonPinballScenario scenario;
  final List<PinballOrb> _orbs = <PinballOrb>[];
  final Set<int> _litTargets = <int>{};
  int launchesUsed = 0;
  int nextTarget = 0;
  int score = 0;
  int combo = 0;
  int bestCombo = 0;
  int drains = 0;
  int wrongTargets = 0;
  double elapsed = 0;
  double _lastScoringTime = double.negativeInfinity;
  bool leftFlipper = false;
  bool rightFlipper = false;
  bool completed = false;
  bool failed = false;
  bool lockOpened = false;

  List<PinballOrb> get orbs => List<PinballOrb>.unmodifiable(_orbs);
  Set<int> get litTargets => Set<int>.unmodifiable(_litTargets);
  int get ballsRemaining =>
      (scenario.totalBalls - launchesUsed + _orbs.length).clamp(0, 3);
  bool get waitingToLaunch =>
      _orbs.isEmpty &&
      !completed &&
      !failed &&
      launchesUsed < scenario.totalBalls;
  bool get multiballActive => _orbs.length > 1;
  int get currentMultiplier => combo >= 8
      ? 4
      : combo >= 4
      ? 3
      : combo >= 2
      ? 2
      : 1;

  bool launch({double aim = 0}) {
    if (!waitingToLaunch) return false;
    launchesUsed++;
    final double normalizedAim = aim.clamp(-1, 1).toDouble();
    _orbs.add(
      PinballOrb(
        x: .5,
        y: .865,
        vx: normalizedAim * .46,
        vy: -1.02 - scenario.level * .016,
      ),
    );
    return true;
  }

  void setFlippers({required bool left, required bool right}) {
    leftFlipper = left;
    rightFlipper = right;
  }

  PinballStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .018).toDouble();
    if (delta <= 0 || completed || failed || _orbs.isEmpty) {
      return const PinballStepResult();
    }
    elapsed += delta;
    int? targetHit;
    bool wrongTargetHit = false;
    bool bumperHit = false;
    bool flipperHit = false;
    bool drained = false;
    bool multiballStarted = false;
    final List<PinballOrb> remove = <PinballOrb>[];

    for (final PinballOrb orb in List<PinballOrb>.of(_orbs)) {
      orb
        ..vy = (orb.vy + .92 * delta).clamp(-1.55, 1.48).toDouble()
        ..vx *= math.exp(-.12 * delta)
        ..x += orb.vx * delta
        ..y += orb.vy * delta;

      if (orb.x < .105) {
        orb
          ..x = .105
          ..vx = orb.vx.abs() * .82;
      } else if (orb.x > .895) {
        orb
          ..x = .895
          ..vx = -orb.vx.abs() * .82;
      }
      if (orb.y < .075) {
        orb
          ..y = .075
          ..vy = orb.vy.abs() * .76;
      }

      for (final PinballBumper bumper in scenario.bumpers) {
        final double dx = orb.x - bumper.x;
        final double dy = (orb.y - bumper.y) * _tableAspect;
        final double distance = math.sqrt(dx * dx + dy * dy);
        final double reach = orb.radius + bumper.radius;
        if (distance >= reach || distance < .0001) continue;
        final double nx = dx / distance;
        final double ny = dy / distance;
        orb
          ..x = bumper.x + nx * reach
          ..y = bumper.y + ny * reach / _tableAspect
          ..vx = nx * .84 + (-ny) * .19
          ..vy = (ny * .84 + ny.abs() * .12) / _tableAspect;
        score += 24 * currentMultiplier;
        bumperHit = true;
        break;
      }

      for (
        int targetIndex = 0;
        targetIndex < scenario.targets.length;
        targetIndex++
      ) {
        final PinballTarget target = scenario.targets[targetIndex];
        final ({double x, double y}) center = target.at(elapsed);
        final double dx = orb.x - center.x;
        final double dy = (orb.y - center.y) * _tableAspect;
        final double distance = math.sqrt(dx * dx + dy * dy);
        if (distance < orb.radius + target.radius && distance > .0001) {
          final double nx = dx / distance;
          final double ny = dy / distance;
          final double reach = orb.radius + target.radius;
          orb
            ..x = center.x + nx * reach
            ..y = center.y + ny * reach / _tableAspect;
          if (targetIndex == nextTarget) {
            orb
              ..vx = nx * math.max(.53, orb.vx.abs() + .24)
              ..vy = ny * math.max(.48, orb.vy.abs() + .2) / _tableAspect;
            targetHit = nextTarget;
            _litTargets.add(nextTarget);
            nextTarget++;
            if (elapsed - _lastScoringTime <= scenario.comboWindowSeconds) {
              combo++;
            } else {
              combo = 1;
            }
            _lastScoringTime = elapsed;
            bestCombo = math.max(bestCombo, combo);
            score += 100 * currentMultiplier;
            if (scenario.hasLock &&
                targetHit == scenario.lockTargetIndex &&
                !lockOpened) {
              lockOpened = true;
              _orbs.add(
                PinballOrb(
                  x: .5,
                  y: .49,
                  vx: orb.vx > 0 ? -.56 : .56,
                  vy: -.68,
                ),
              );
              multiballStarted = true;
            }
            if (nextTarget >= scenario.targets.length) completed = true;
          } else {
            orb
              ..vx = nx * math.max(.4, orb.vx.abs() + .12)
              ..vy = ny * math.max(.38, orb.vy.abs() + .12) / _tableAspect;
            if (targetIndex > nextTarget) {
              wrongTargets++;
              combo = 0;
              wrongTargetHit = true;
            }
          }
          break;
        }
      }

      if (_hitFlipper(orb, left: true)) flipperHit = true;
      if (_hitFlipper(orb, left: false)) flipperHit = true;

      if (orb.y > 1.015) {
        remove.add(orb);
        drains++;
        combo = 0;
        drained = true;
      }
    }

    _orbs.removeWhere(remove.contains);
    if (!completed && _orbs.isEmpty && launchesUsed >= scenario.totalBalls) {
      failed = true;
    }
    return PinballStepResult(
      targetHit: targetHit,
      wrongTargetHit: wrongTargetHit,
      bumperHit: bumperHit,
      flipperHit: flipperHit,
      drained: drained,
      multiballStarted: multiballStarted,
      completed: completed,
      failed: failed,
    );
  }

  bool _hitFlipper(PinballOrb orb, {required bool left}) {
    final bool active = left ? leftFlipper : rightFlipper;
    final double pivotX = left ? .29 : .71;
    const double pivotY = .865;
    final double endX = left ? (active ? .48 : .49) : (active ? .52 : .51);
    final double endY = active ? .785 : .845;
    final double vx = endX - pivotX;
    final double vy = (endY - pivotY) * _tableAspect;
    final double lengthSq = vx * vx + vy * vy;
    final double t =
        (((orb.x - pivotX) * vx + (orb.y - pivotY) * vy) / lengthSq)
            .clamp(0, 1)
            .toDouble();
    final double px = pivotX + vx * t;
    final double py = pivotY + vy * t / _tableAspect;
    final double dx = orb.x - px;
    final double dy = (orb.y - py) * _tableAspect;
    final double radius = orb.radius + (active ? .016 : .009);
    if (dx * dx + dy * dy > radius * radius || orb.vy <= 0) return false;
    final double normalLength = math.sqrt(dx * dx + dy * dy).clamp(.0001, 1);
    final double nx = dx / normalLength;
    final double ny = dy / normalLength;
    orb
      ..x = px + nx * radius
      ..y = py + ny * radius / _tableAspect
      ..vx = nx * .48 + (left ? .28 : -.28) + (active ? (left ? .26 : -.26) : 0)
      ..vy = -(.82 + (active ? .52 : .1)) / _tableAspect;
    if (!active) wrongTargets++;
    return true;
  }
}
