import 'dart:math' as math;

import 'kite_runner_scenario.dart';

class KiteState {
  KiteState({required this.x, required this.altitude});

  double x;
  double altitude;
  double distance = 0;
  double lateralSpeed = 0;
  double climbRate = 0;
  double lineLength = .56;
  double lineTension = .28;
}

class KiteStepResult {
  const KiteStepResult({
    this.gatePassed = false,
    this.gateMissed = false,
    this.wireHit = false,
    this.lineSnapped = false,
    this.fell = false,
    this.finished = false,
    this.failed = false,
  });

  final bool gatePassed;
  final bool gateMissed;
  final bool wireHit;
  final bool lineSnapped;
  final bool fell;
  final bool finished;
  final bool failed;
}

class KiteRunnerEngine {
  KiteRunnerEngine({required this.scenario})
    : kite = KiteState(x: .5, altitude: .57);

  final KiteRunnerScenario scenario;
  final KiteState kite;
  int nextGate = 0;
  int misses = 0;
  int wiresAvoided = 0;
  double elapsed = 0;
  double _stressSeconds = 0;
  int _nextWire = 0;
  bool finished = false;
  bool failed = false;
  double steer = 0;
  double reel = 0;

  bool get gatesComplete => nextGate >= scenario.gates.length;

  void setControl({required double steer, required double reel}) {
    this
      ..steer = steer.clamp(-1, 1).toDouble()
      ..reel = reel.clamp(-1, 1).toDouble();
  }

  KiteStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .02).toDouble();
    if (delta <= 0 || finished || failed) return const KiteStepResult();
    elapsed += delta;
    final KiteWind wind = scenario.windAt(kite.distance, elapsed);
    final double oldDistance = kite.distance;
    final double normalizedLine = (kite.lineLength - .24) / .52;
    final double steeringLoad = (steer * wind.cross).abs();
    final double shortLineLoad = (1 - normalizedLine).clamp(0, 1).toDouble();
    kite.lineTension =
        (.22 +
                reel.clamp(0, 1) * .26 +
                wind.gust.abs() * .72 +
                steeringLoad * .64 +
                shortLineLoad * .34)
            .clamp(.12, 1.3)
            .toDouble();
    if (kite.lineTension > scenario.snapThreshold) {
      _stressSeconds += delta * (1 + kite.lineTension - scenario.snapThreshold);
    } else {
      _stressSeconds = math.max(0, _stressSeconds - delta * .8);
    }

    kite
      ..lineLength = (kite.lineLength - reel * .22 * delta)
          .clamp(.24, .76)
          .toDouble()
      ..lateralSpeed =
          (kite.lateralSpeed + (steer * .75 + wind.cross * .20) * delta)
              .clamp(-.42, .42)
              .toDouble()
      ..lateralSpeed *= math.exp(-.58 * delta)
      ..x += kite.lateralSpeed * delta;
    if (kite.x < .08) {
      kite
        ..x = .08
        ..lateralSpeed = kite.lateralSpeed.abs() * .3;
    } else if (kite.x > .92) {
      kite
        ..x = .92
        ..lateralSpeed = -kite.lateralSpeed.abs() * .3;
    }

    final double lift =
        wind.lift * (.72 + normalizedLine * .45) -
        .067 -
        reel.clamp(0, 1) * .48 -
        (-reel).clamp(0, 1) * .38 -
        steer.abs() * .011;
    kite
      ..climbRate = (kite.climbRate + lift * delta).clamp(-.42, .42).toDouble()
      ..climbRate *= math.exp(-2.4 * delta)
      ..altitude += kite.climbRate * delta
      ..distance += scenario.cruiseSpeed * (1 + wind.phase * .08) * delta;

    bool gatePassed = false;
    bool gateMissed = false;
    if (nextGate < scenario.gates.length) {
      final KiteGate gate = scenario.gates[nextGate];
      if (oldDistance < gate.distance && kite.distance >= gate.distance) {
        final double gateX = gate.centerAt(elapsed);
        if ((kite.x - gateX).abs() <= gate.width / 2 &&
            (kite.altitude - gate.altitude).abs() <= gate.height / 2) {
          nextGate++;
          gatePassed = true;
        } else {
          nextGate++;
          misses++;
          gateMissed = true;
        }
      }
    }

    bool wireHit = false;
    if (_nextWire < scenario.wires.length) {
      final KiteWire wire = scenario.wires[_nextWire];
      if (oldDistance < wire.distance && kite.distance >= wire.distance) {
        _nextWire++;
        if ((kite.x - wire.centerX).abs() <= wire.width / 2 &&
            (kite.altitude - wire.altitude).abs() <= .055) {
          misses += 2;
          wireHit = true;
        } else {
          wiresAvoided++;
        }
      }
    }

    final bool lineSnapped = _stressSeconds > (scenario.level >= 9 ? .55 : .82);
    final bool fell = kite.altitude < .13;
    if (lineSnapped || fell || misses > scenario.missLimit) {
      failed = true;
      return KiteStepResult(
        gatePassed: gatePassed,
        gateMissed: gateMissed,
        wireHit: wireHit,
        lineSnapped: lineSnapped,
        fell: fell,
        failed: true,
      );
    }
    if (kite.distance >= 1) {
      finished = gatesComplete;
      if (!finished) {
        failed = true;
        misses++;
      }
      return KiteStepResult(
        gatePassed: gatePassed,
        gateMissed: gateMissed,
        wireHit: wireHit,
        finished: finished,
        failed: failed,
      );
    }
    return KiteStepResult(
      gatePassed: gatePassed,
      gateMissed: gateMissed,
      wireHit: wireHit,
    );
  }

  void reset() {
    kite
      ..x = .5
      ..altitude = .57
      ..distance = 0
      ..lateralSpeed = 0
      ..climbRate = 0
      ..lineLength = .56
      ..lineTension = .28;
    nextGate = 0;
    misses = 0;
    wiresAvoided = 0;
    elapsed = 0;
    _stressSeconds = 0;
    _nextWire = 0;
    finished = false;
    failed = false;
    steer = 0;
    reel = 0;
  }
}
