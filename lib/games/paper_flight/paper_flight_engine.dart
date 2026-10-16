import 'dart:math' as math;

import 'paper_flight_scenario.dart';

class GliderState {
  GliderState({
    required this.x,
    required this.altitude,
    required this.distance,
  });

  double x;
  double altitude;
  double distance;
  double lateralSpeed = 0;
  double climbRate = 0;
  double airspeed = .68;
  double bank = 0;
  double pitch = 0;
}

class FlightStepResult {
  const FlightStepResult({
    this.gatePassed = false,
    this.gateMissed = false,
    this.enteredThermal = false,
    this.landed = false,
    this.approachMissed = false,
    this.crashed = false,
  });

  final bool gatePassed;
  final bool gateMissed;
  final bool enteredThermal;
  final bool landed;
  final bool approachMissed;
  final bool crashed;
}

/// Fixed-step paper glider physics: bank, pitch, lift, thermal, drift and flare.
class PaperFlightEngine {
  PaperFlightEngine({required this.scenario})
    : plane = GliderState(x: .5, altitude: .62, distance: 0);

  final PaperFlightScenario scenario;
  final GliderState plane;
  int nextGate = 0;
  int misses = 0;
  int thermalsUsed = 0;
  int landingAttempts = 0;
  double elapsedSeconds = 0;
  bool isLanded = false;
  bool isCrashed = false;
  int _nextThermal = 0;

  bool get gatesComplete => nextGate >= scenario.gates.length;
  double get windStrength {
    final FlightWind wind = scenario.windAt(plane.distance, elapsedSeconds);
    return math.sqrt(wind.cross * wind.cross + wind.vertical * wind.vertical);
  }

  void setControl({required double bank, required double pitch}) {
    plane
      ..bank = bank.clamp(-1, 1).toDouble()
      ..pitch = pitch.clamp(-1, 1).toDouble();
  }

  FlightStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .024).toDouble();
    if (delta == 0 || isLanded || isCrashed) return const FlightStepResult();
    elapsedSeconds += delta;
    final FlightWind wind = scenario.windAt(plane.distance, elapsedSeconds);
    final FlightThermal? thermal = _thermalAt(plane.x, plane.distance);
    final bool enteredThermal =
        thermal != null &&
        (plane.distance - thermal.distance).abs() <
            scenario.cruiseSpeed * delta * 1.2;
    if (enteredThermal) thermalsUsed++;

    plane
      ..lateralSpeed +=
          (plane.bank * (.19 + plane.airspeed * .12) + wind.cross * .7) * delta
      ..lateralSpeed *= math.exp(-.82 * delta)
      ..lateralSpeed = plane.lateralSpeed.clamp(-.23, .23).toDouble()
      ..x += plane.lateralSpeed * delta;
    if (plane.x < .08) {
      plane
        ..x = .08
        ..lateralSpeed = plane.lateralSpeed.abs() * .35;
    } else if (plane.x > .92) {
      plane
        ..x = .92
        ..lateralSpeed = -plane.lateralSpeed.abs() * .35;
    }

    final double lift =
        plane.pitch * .22 +
        (thermal?.lift ?? 0) +
        wind.vertical * .42 -
        .038 -
        plane.bank.abs() * .018;
    plane
      ..climbRate = (plane.climbRate + lift * delta).clamp(-.18, .18).toDouble()
      ..climbRate *= math.exp(-.68 * delta)
      ..altitude += plane.climbRate * delta
      ..airspeed =
          (plane.airspeed -
                  (plane.pitch.abs() * .035 +
                          plane.bank.abs() * .012 -
                          (thermal?.lift ?? 0) * .1) *
                      delta)
              .clamp(.42, .86)
              .toDouble();
    final double oldDistance = plane.distance;
    final double forward = (1 + wind.forward).clamp(.78, 1.22).toDouble();
    plane.distance += scenario.cruiseSpeed * plane.airspeed * forward * delta;

    bool gatePassed = false;
    bool gateMissed = false;
    if (nextGate < scenario.gates.length) {
      final FlightGate gate = scenario.gates[nextGate];
      if (oldDistance < gate.distance && plane.distance >= gate.distance) {
        final double t =
            (gate.distance - oldDistance) /
            math.max(.0001, plane.distance - oldDistance);
        final double crossX = plane.x - plane.lateralSpeed * delta * (1 - t);
        final double gateX = gate.centerAt(elapsedSeconds - delta * (1 - t));
        final bool inside =
            (crossX - gateX).abs() <= gate.width / 2 &&
            (plane.altitude - gate.altitude).abs() <= gate.height / 2;
        if (inside) {
          nextGate++;
          gatePassed = true;
        } else {
          misses++;
          gateMissed = true;
          nextGate++;
        }
      }
    }

    if (plane.altitude < .145) {
      isCrashed = true;
      return FlightStepResult(
        gatePassed: gatePassed,
        gateMissed: gateMissed,
        enteredThermal: enteredThermal,
        crashed: true,
      );
    }

    if (plane.distance >= 1) {
      final bool onStrip =
          (plane.x - scenario.landing.centerX).abs() <=
              scenario.landing.width / 2 &&
          (plane.altitude - scenario.landing.altitude).abs() <=
              scenario.landing.altitudeTolerance &&
          plane.climbRate.abs() <= scenario.landing.maxSinkRate;
      if (onStrip) {
        isLanded = true;
        plane.distance = 1;
        return FlightStepResult(
          gatePassed: gatePassed,
          gateMissed: gateMissed,
          enteredThermal: enteredThermal,
          landed: true,
        );
      }
      landingAttempts++;
      misses++;
      plane
        ..distance = .91
        ..lateralSpeed *= .24
        ..climbRate *= .32;
      return FlightStepResult(
        gatePassed: gatePassed,
        gateMissed: gateMissed,
        enteredThermal: enteredThermal,
        approachMissed: true,
      );
    }
    return FlightStepResult(
      gatePassed: gatePassed,
      gateMissed: gateMissed,
      enteredThermal: enteredThermal,
    );
  }

  FlightThermal? _thermalAt(double x, double distance) {
    if (_nextThermal >= scenario.thermals.length) return null;
    final FlightThermal thermal = scenario.thermals[_nextThermal];
    if ((distance - thermal.distance).abs() > .045 ||
        (x - thermal.centerX).abs() > thermal.radius) {
      return null;
    }
    if ((distance - thermal.distance).abs() < .009) _nextThermal++;
    return thermal;
  }

  void reset() {
    plane
      ..x = .5
      ..altitude = .62
      ..distance = 0
      ..lateralSpeed = 0
      ..climbRate = 0
      ..airspeed = .68
      ..bank = 0
      ..pitch = 0;
    nextGate = 0;
    misses = 0;
    thermalsUsed = 0;
    landingAttempts = 0;
    elapsedSeconds = 0;
    isLanded = false;
    isCrashed = false;
    _nextThermal = 0;
  }
}
