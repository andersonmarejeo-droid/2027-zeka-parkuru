import 'dart:math' as math;

import 'snowboard_slalom_scenario.dart';

enum SnowGateState { upcoming, cleared, missed }

class SnowStepResult {
  const SnowStepResult({
    this.cleared = 0,
    this.missed = 0,
    this.fell = false,
    this.completed = false,
    this.failed = false,
  });

  final int cleared;
  final int missed;
  final bool fell;
  final bool completed;
  final bool failed;
}

/// Inertial carve, surface grip and edge-load simulation for slalom gates.
class SnowboardSlalomEngine {
  SnowboardSlalomEngine({required this.scenario})
    : _states = List<SnowGateState>.filled(
        scenario.gates.length,
        SnowGateState.upcoming,
        growable: false,
      ),
      speed = scenario.initialSpeed;

  final SnowboardSlalomScenario scenario;
  final List<SnowGateState> _states;
  double routeDistance = 0;
  double x = .5;
  double lateralVelocity = 0;
  double speed;
  double edgeLoad = 0;
  double elapsed = 0;
  double carve = 0;
  bool braking = false;
  int nextGate = 0;
  int misses = 0;
  int combo = 0;
  int bestCombo = 0;
  int gatesCleared = 0;
  bool completed = false;
  bool failed = false;

  List<SnowGateState> get states => List<SnowGateState>.unmodifiable(_states);
  SnowGate? get currentGate =>
      nextGate < scenario.gates.length ? scenario.gates[nextGate] : null;
  SnowSurface get surface => currentGate?.surface ?? SnowSurface.packed;
  double get accuracy => gatesCleared / math.max(1, scenario.gates.length);
  double get grip => switch (surface) {
    SnowSurface.packed => .78,
    SnowSurface.powder => .94,
    SnowSurface.ice => .38,
    SnowSurface.moguls => .61,
  };

  void setCarve(double value) {
    if (completed || failed) return;
    carve = value.clamp(-1, 1).toDouble();
  }

  void setBrake(bool value) {
    if (completed || failed) return;
    braking = value;
  }

  SnowStepResult step(double deltaSeconds) {
    final double dt = deltaSeconds.clamp(0, .04).toDouble();
    if (dt <= 0 || completed || failed) return const SnowStepResult();
    elapsed += dt;
    final SnowGate? gate = currentGate;
    final double wind = gate?.crosswind ?? 0;
    final double surfaceGrip = grip;

    speed =
        (speed +
                dt * (.006 + scenario.level * .00035) -
                (braking ? dt * .27 : 0) -
                (surface == SnowSurface.powder ? dt * .018 : 0))
            .clamp(.27, 1.05)
            .toDouble();
    lateralVelocity += (carve * surfaceGrip * 1.18 + wind * .7) * dt;
    lateralVelocity *= math.exp(-(surfaceGrip * .96 + .14) * dt);
    lateralVelocity = lateralVelocity.clamp(-.82, .82).toDouble();
    x += lateralVelocity * dt;
    routeDistance += speed * dt;
    edgeLoad =
        (edgeLoad +
                (carve.abs() *
                            speed *
                            (surface == SnowSurface.ice ? .43 : .25) -
                        (braking ? .48 : .16)) *
                    dt)
            .clamp(0, 1.2)
            .toDouble();

    bool fell = false;
    int cleared = 0;
    int missed = 0;
    if (x < .13 || x > .87 || edgeLoad >= .99) {
      fell = true;
      if (nextGate < scenario.gates.length) {
        _missCurrentGate();
        nextGate++;
        missed++;
        if (misses > scenario.missLimit) failed = true;
      }
      x = x.clamp(.24, .76).toDouble();
      lateralVelocity = 0;
      speed = math.max(.31, speed * .74);
      edgeLoad = .32;
    }

    while (!failed &&
        nextGate < scenario.gates.length &&
        routeDistance >= scenario.gates[nextGate].distance) {
      final SnowGate crossed = scenario.gates[nextGate];
      final bool centered = (x - crossed.centerX).abs() <= crossed.width / 2;
      final bool controlledSpeed = speed <= crossed.safeSpeed;
      final bool stableEdge = edgeLoad < .88;
      if (centered && controlledSpeed && stableEdge) {
        _states[nextGate] = SnowGateState.cleared;
        combo++;
        bestCombo = math.max(bestCombo, combo);
        gatesCleared++;
        cleared++;
        edgeLoad = math.max(0, edgeLoad - .22);
      } else {
        _missCurrentGate();
        missed++;
      }
      nextGate++;
      if (misses > scenario.missLimit) failed = true;
    }
    if (!failed &&
        nextGate == scenario.gates.length &&
        routeDistance >= scenario.finishDistance) {
      completed = true;
    }
    return SnowStepResult(
      cleared: cleared,
      missed: missed,
      fell: fell,
      completed: completed,
      failed: failed,
    );
  }

  void _missCurrentGate() {
    if (nextGate >= scenario.gates.length) return;
    _states[nextGate] = SnowGateState.missed;
    misses++;
    combo = 0;
  }

  void reset() {
    for (int index = 0; index < _states.length; index++) {
      _states[index] = SnowGateState.upcoming;
    }
    routeDistance = 0;
    x = .5;
    lateralVelocity = 0;
    speed = scenario.initialSpeed;
    edgeLoad = 0;
    elapsed = 0;
    carve = 0;
    braking = false;
    nextGate = 0;
    misses = 0;
    combo = 0;
    bestCombo = 0;
    gatesCleared = 0;
    completed = false;
    failed = false;
  }
}
