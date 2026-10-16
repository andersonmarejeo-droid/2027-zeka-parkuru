import 'dart:math' as math;

import 'jetpack_courier_scenario.dart';

enum CourierCheckpointState { upcoming, cleared, missed }

class CourierStepResult {
  const CourierStepResult({
    this.cleared = 0,
    this.missed = 0,
    this.impact = false,
    this.overheated = false,
    this.completed = false,
    this.failed = false,
  });

  final int cleared;
  final int missed;
  final bool impact;
  final bool overheated;
  final bool completed;
  final bool failed;
}

/// Fuel, heat, cargo shock and inertial flight control for delivery routes.
class JetpackCourierEngine {
  JetpackCourierEngine({required this.scenario})
    : _states = List<CourierCheckpointState>.filled(
        scenario.checkpoints.length,
        CourierCheckpointState.upcoming,
        growable: false,
      ),
      fuel = scenario.fuelCapacity;

  final JetpackCourierScenario scenario;
  final List<CourierCheckpointState> _states;
  double progress = 0;
  double x = .5;
  double altitude = .43;
  double lateralVelocity = 0;
  double verticalVelocity = 0;
  double fuel;
  double heat = 0;
  double packageIntegrity = 100;
  double elapsed = 0;
  double steer = 0;
  double throttle = 0;
  int nextCheckpoint = 0;
  int misses = 0;
  int combo = 0;
  int bestCombo = 0;
  int checkpointsCleared = 0;
  bool thermalLock = false;
  bool completed = false;
  bool failed = false;

  List<CourierCheckpointState> get states =>
      List<CourierCheckpointState>.unmodifiable(_states);
  CourierCheckpoint? get currentCheckpoint =>
      nextCheckpoint < scenario.checkpoints.length
      ? scenario.checkpoints[nextCheckpoint]
      : null;
  bool get thrustActive => throttle > .02 && fuel > 0 && !thermalLock;
  double get velocity => math.sqrt(
    lateralVelocity * lateralVelocity + verticalVelocity * verticalVelocity,
  );
  double get accuracy =>
      checkpointsCleared / math.max(1, scenario.checkpoints.length);

  void setControl({required double steer, required double throttle}) {
    if (completed || failed) return;
    this.steer = steer.clamp(-1, 1).toDouble();
    this.throttle = throttle.clamp(0, 1).toDouble();
  }

  CourierStepResult step(double deltaSeconds) {
    final double dt = deltaSeconds.clamp(0, .04).toDouble();
    if (dt <= 0 || completed || failed) return const CourierStepResult();
    elapsed += dt;
    final CourierCheckpoint? point = currentCheckpoint;
    final double crosswind = point?.crosswind ?? 0;
    final double updraft = point?.updraft ?? 0;
    bool overheatedNow = false;

    if (!thermalLock && heat >= 100) {
      thermalLock = true;
      overheatedNow = true;
    } else if (thermalLock && heat <= 64) {
      thermalLock = false;
    }
    final bool active = thrustActive;
    final double actualThrottle = active ? throttle : 0;
    if (active) {
      fuel = math.max(
        0,
        fuel - actualThrottle * (1.8 + scenario.level * .055) * dt,
      );
      heat =
          (heat +
                  (actualThrottle * (3.1 + scenario.level * .10) -
                          (1 - actualThrottle) * 1.5) *
                      dt)
              .clamp(0, 108)
              .toDouble();
    } else {
      heat = math.max(0, heat - 1.7 * dt);
    }

    lateralVelocity += (steer * 1.18 + crosswind * .78) * dt;
    lateralVelocity *= math.exp(-1.42 * dt);
    lateralVelocity = lateralVelocity.clamp(-.72, .72).toDouble();
    verticalVelocity += (actualThrottle * 1.55 - .92 + updraft) * dt;
    verticalVelocity *= math.exp(-.24 * dt);
    verticalVelocity = verticalVelocity.clamp(-.72, .72).toDouble();
    x += lateralVelocity * dt;
    altitude += verticalVelocity * dt;
    progress += scenario.forwardSpeed * dt;
    packageIntegrity =
        (packageIntegrity -
                math.max(0, velocity - scenario.packageTolerance / 100) *
                    .018 *
                    dt)
            .clamp(0, 100)
            .toDouble();

    bool impact = false;
    if (x < .1 || x > .9 || altitude < .12 || altitude > .9) {
      impact = true;
      packageIntegrity -= 18;
      misses++;
      combo = 0;
      x = x.clamp(.15, .85).toDouble();
      altitude = altitude.clamp(.16, .86).toDouble();
      lateralVelocity *= -.18;
      verticalVelocity *= -.22;
    }

    int cleared = 0;
    int missed = 0;
    while (nextCheckpoint < scenario.checkpoints.length &&
        progress >= scenario.checkpoints[nextCheckpoint].progress) {
      final CourierCheckpoint checkpoint = scenario.checkpoints[nextCheckpoint];
      final bool inWindow =
          (x - checkpoint.centerX).abs() <= checkpoint.halfWidth &&
          (altitude - checkpoint.centerAltitude).abs() <= checkpoint.halfHeight;
      final bool controlled =
          velocity <= checkpoint.safeSpeed &&
          packageIntegrity > 0 &&
          (!thermalLock || checkpoint.coolantVent);
      if (inWindow && controlled) {
        _states[nextCheckpoint] = CourierCheckpointState.cleared;
        checkpointsCleared++;
        combo++;
        bestCombo = math.max(bestCombo, combo);
        cleared++;
        if (checkpoint.coolantVent) heat = math.max(0, heat - 18);
        if (checkpoint.deliveryDock) {
          packageIntegrity = math.min(100, packageIntegrity + 8);
        }
      } else {
        _states[nextCheckpoint] = CourierCheckpointState.missed;
        packageIntegrity = math.max(0, packageIntegrity - 20);
        misses++;
        combo = 0;
        missed++;
      }
      nextCheckpoint++;
      if (misses > scenario.missLimit || packageIntegrity <= 0) failed = true;
    }
    if (!failed &&
        nextCheckpoint == scenario.checkpoints.length &&
        progress >= scenario.finishProgress) {
      completed = true;
    }
    return CourierStepResult(
      cleared: cleared,
      missed: missed,
      impact: impact,
      overheated: overheatedNow,
      completed: completed,
      failed: failed,
    );
  }

  void reset() {
    for (int index = 0; index < _states.length; index++) {
      _states[index] = CourierCheckpointState.upcoming;
    }
    progress = 0;
    x = .5;
    altitude = .43;
    lateralVelocity = 0;
    verticalVelocity = 0;
    fuel = scenario.fuelCapacity;
    heat = 0;
    packageIntegrity = 100;
    elapsed = 0;
    steer = 0;
    throttle = 0;
    nextCheckpoint = 0;
    misses = 0;
    combo = 0;
    bestCombo = 0;
    checkpointsCleared = 0;
    thermalLock = false;
    completed = false;
    failed = false;
  }
}
