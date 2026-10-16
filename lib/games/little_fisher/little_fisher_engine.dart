import 'dart:math' as math;

import 'little_fisher_scenario.dart';

enum FishingCastResult { hooked, wrongBait, wrongDepth, blocked }

class FishingStepResult {
  const FishingStepResult({
    this.caught = false,
    this.lineSnapped = false,
    this.fishEscaped = false,
  });

  final bool caught;
  final bool lineSnapped;
  final bool fishEscaped;

  bool get missed => lineSnapped || fishEscaped;
}

/// Models bait selection, layered current, drag, tension and fish stamina.
class LittleFisherEngine {
  LittleFisherEngine({required this.scenario});

  final LittleFisherScenario scenario;
  int fishIndex = 0;
  int misses = 0;
  int catches = 0;
  double elapsedSeconds = 0;
  double lineTension = .42;
  double fishDistance = 1;
  double staminaRemaining = 0;
  double lineSeconds = 0;
  bool isHooked = false;
  bool isReeling = false;
  double _castCooldown = 0;

  bool get isComplete => fishIndex >= scenario.fishCount;
  bool get canCast => !isComplete && !isHooked && _castCooldown <= 0;
  FishPlan? get currentFish => isComplete ? null : scenario.fish[fishIndex];

  FishingCastResult cast({required int bait, required int depth}) {
    if (!canCast || bait < 0 || bait > 2 || depth < 0 || depth > 2) {
      return FishingCastResult.blocked;
    }
    final FishPlan fish = currentFish!;
    if (bait != fish.preferredBait) {
      misses++;
      _castCooldown = .58;
      return FishingCastResult.wrongBait;
    }
    if (depth != fish.preferredDepth) {
      misses++;
      _castCooldown = .58;
      return FishingCastResult.wrongDepth;
    }
    isHooked = true;
    isReeling = false;
    lineTension = .42;
    fishDistance = 1;
    staminaRemaining = fish.stamina;
    lineSeconds = 0;
    return FishingCastResult.hooked;
  }

  void setReeling(bool held) {
    if (!isHooked) return;
    isReeling = held;
  }

  FishingStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .024).toDouble();
    if (delta == 0 || isComplete) return const FishingStepResult();
    elapsedSeconds += delta;
    if (!isHooked) {
      _castCooldown = math.max(0, _castCooldown - delta);
      return const FishingStepResult();
    }

    final FishPlan fish = currentFish!;
    lineSeconds += delta;
    final double pullWave =
        .42 + .22 * math.sin(lineSeconds * fish.pullFrequency + fish.phase);
    final FishingCurrent current = scenario.currentAt(
      elapsedSeconds,
      fish.preferredDepth,
    );
    final double currentPull =
        math.sqrt(current.x * current.x + current.y * current.y) * .42;
    final double pull = (fish.strength * pullWave + currentPull)
        .clamp(.08, .72)
        .toDouble();
    final double tensionChange = isReeling
        ? (.10 + pull * .14)
        : (pull * .24 - .20);
    lineTension = (lineTension + tensionChange * delta)
        .clamp(0, 1.05)
        .toDouble();

    if (lineTension >= .91) return _loseFish(lineSnapped: true);
    if (lineTension <= .11) return _loseFish(lineSnapped: false);
    if (lineSeconds > scenario.maxLineSeconds) {
      return _loseFish(lineSnapped: false);
    }

    if (isReeling && lineTension >= .29 && lineTension <= .79) {
      staminaRemaining -= delta * (.58 + fish.strength * .12);
      fishDistance = math.max(0, fishDistance - delta * .045);
      if (staminaRemaining <= 0 || fishDistance <= .035) {
        fishIndex++;
        catches++;
        isHooked = false;
        isReeling = false;
        _castCooldown = .42;
        lineTension = .42;
        fishDistance = 1;
        return const FishingStepResult(caught: true);
      }
    }
    return const FishingStepResult();
  }

  FishingStepResult _loseFish({required bool lineSnapped}) {
    misses++;
    isHooked = false;
    isReeling = false;
    _castCooldown = .72;
    lineTension = lineSnapped ? 1 : 0;
    fishDistance = 1;
    staminaRemaining = 0;
    return FishingStepResult(
      lineSnapped: lineSnapped,
      fishEscaped: !lineSnapped,
    );
  }
}
