import 'dart:math' as math;

import 'skate_combo_scenario.dart';

enum SkateJumpState { upcoming, airborne, landed, bailed }

enum SkateActionQuality { none, early, late, clean, good, perfect, bailed }

class SkateInputResult {
  const SkateInputResult({
    this.quality = SkateActionQuality.none,
    this.jumpIndex,
    this.failed = false,
  });

  final SkateActionQuality quality;
  final int? jumpIndex;
  final bool failed;
}

class SkateStepResult {
  const SkateStepResult({
    this.landed = 0,
    this.bailed = 0,
    this.completed = false,
    this.failed = false,
  });

  final int landed;
  final int bailed;
  final bool completed;
  final bool failed;
}

/// Combo rhythm and landing judgement, independent from display frame rate.
class SkateComboEngine {
  SkateComboEngine({required this.scenario})
    : _states = List<SkateJumpState>.filled(
        scenario.jumps.length,
        SkateJumpState.upcoming,
        growable: false,
      );

  final SkateComboScenario scenario;
  final List<SkateJumpState> _states;
  double elapsed = 0;
  double speed = .43;
  double rotation = 0;
  double balance = 0;
  int score = 0;
  int misses = 0;
  int combo = 0;
  int bestCombo = 0;
  int perfectLandings = 0;
  int jumpIndex = 0;
  int _pushesOnApproach = 0;
  bool completed = false;
  bool failed = false;

  List<SkateJumpState> get states => List<SkateJumpState>.unmodifiable(_states);
  bool get airborne =>
      jumpIndex < _states.length &&
      _states[jumpIndex] == SkateJumpState.airborne;
  SkateJump? get currentJump =>
      jumpIndex < scenario.jumps.length ? scenario.jumps[jumpIndex] : null;
  double get airTimeLeft => !airborne || currentJump == null
      ? 0
      : (currentJump!.landingSeconds - elapsed).clamp(0, double.infinity);
  int get landedCount =>
      _states.where((SkateJumpState s) => s == SkateJumpState.landed).length;
  double get accuracy => landedCount / math.max(1, scenario.jumps.length);

  SkateInputResult pump() {
    if (completed || failed || airborne || currentJump == null) {
      return const SkateInputResult();
    }
    final SkateJump jump = currentJump!;
    final double untilTakeoff = jump.takeoffSeconds - elapsed;
    if (untilTakeoff > 1.48) {
      return SkateInputResult(
        quality: SkateActionQuality.early,
        jumpIndex: jumpIndex,
      );
    }
    if (untilTakeoff < .1) {
      return SkateInputResult(
        quality: SkateActionQuality.late,
        jumpIndex: jumpIndex,
      );
    }
    final double error = (untilTakeoff - .72).abs();
    _pushesOnApproach++;
    speed = (speed + (error <= scenario.pushPerfectWindow ? .19 : .12))
        .clamp(.32, 1.0)
        .toDouble();
    final SkateActionQuality quality = error <= scenario.pushPerfectWindow
        ? SkateActionQuality.perfect
        : SkateActionQuality.clean;
    score += quality == SkateActionQuality.perfect ? 35 : 20;
    return SkateInputResult(quality: quality, jumpIndex: jumpIndex);
  }

  SkateInputResult addRotation(double degrees) {
    if (!airborne || completed || failed || degrees == 0) {
      return const SkateInputResult();
    }
    rotation = (rotation + degrees).clamp(-1800, 1800).toDouble();
    return SkateInputResult(
      quality: SkateActionQuality.good,
      jumpIndex: jumpIndex,
    );
  }

  void setBalance(double value) {
    if (!airborne || completed || failed) return;
    balance = value.clamp(-1, 1).toDouble();
  }

  SkateStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .1).toDouble();
    if (delta <= 0 || completed || failed) return const SkateStepResult();
    elapsed += delta;
    speed = (speed - delta * .012).clamp(.32, 1).toDouble();
    int landed = 0;
    int bailed = 0;
    while (jumpIndex < scenario.jumps.length) {
      final SkateJump jump = scenario.jumps[jumpIndex];
      if (_states[jumpIndex] == SkateJumpState.upcoming &&
          elapsed >= jump.takeoffSeconds) {
        _states[jumpIndex] = SkateJumpState.airborne;
        rotation = 0;
        balance = 0;
        if (speed < jump.minimumSpeed || _pushesOnApproach == 0) {
          // An under-speed launch has a shorter, less controllable arc.
          rotation = -jump.rotationTolerance * 1.6;
        }
        _pushesOnApproach = 0;
      }
      if (_states[jumpIndex] != SkateJumpState.airborne ||
          elapsed < jump.landingSeconds) {
        break;
      }
      final double rotationError = (rotation - jump.targetRotation).abs();
      final double balanceError = (balance - jump.targetBalance).abs();
      if (speed >= jump.minimumSpeed &&
          rotationError <= jump.rotationTolerance &&
          balanceError <= jump.balanceTolerance) {
        _states[jumpIndex] = SkateJumpState.landed;
        combo++;
        bestCombo = math.max(bestCombo, combo);
        final bool perfect =
            rotationError <= jump.rotationTolerance * .42 &&
            balanceError <= jump.balanceTolerance * .48 &&
            speed >= jump.minimumSpeed + .1;
        if (perfect) perfectLandings++;
        score += (120 + combo * 32 + (perfect ? 110 : 0) + speed * 90).round();
        landed++;
        speed = (speed + .065).clamp(.32, 1).toDouble();
      } else {
        _states[jumpIndex] = SkateJumpState.bailed;
        misses++;
        combo = 0;
        bailed++;
      }
      jumpIndex++;
      if (misses > scenario.missLimit) {
        failed = true;
        break;
      }
    }
    if (!failed &&
        jumpIndex == scenario.jumps.length &&
        elapsed >= scenario.finishSeconds) {
      completed = true;
    }
    return SkateStepResult(
      landed: landed,
      bailed: bailed,
      completed: completed,
      failed: failed,
    );
  }

  void reset() {
    for (int index = 0; index < _states.length; index++) {
      _states[index] = SkateJumpState.upcoming;
    }
    elapsed = 0;
    speed = .43;
    rotation = 0;
    balance = 0;
    score = 0;
    misses = 0;
    combo = 0;
    bestCombo = 0;
    perfectLandings = 0;
    jumpIndex = 0;
    _pushesOnApproach = 0;
    completed = false;
    failed = false;
  }
}
