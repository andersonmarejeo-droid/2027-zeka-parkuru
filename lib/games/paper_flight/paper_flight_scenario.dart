import 'dart:math' as math;

import '../shared/content_seed.dart';

class FlightGate {
  const FlightGate({
    required this.distance,
    required this.centerX,
    required this.altitude,
    required this.width,
    required this.height,
    required this.drift,
    required this.frequency,
    required this.phase,
  });

  final double distance;
  final double centerX;
  final double altitude;
  final double width;
  final double height;
  final double drift;
  final double frequency;
  final double phase;

  double centerAt(double elapsed) =>
      centerX + drift * math.sin(elapsed * frequency + phase);

  String get signature =>
      '${distance.toStringAsFixed(3)}:${centerX.toStringAsFixed(3)}:'
      '${altitude.toStringAsFixed(3)}:${width.toStringAsFixed(3)}:'
      '${height.toStringAsFixed(3)}:${drift.toStringAsFixed(3)}:'
      '${frequency.toStringAsFixed(3)}:${phase.toStringAsFixed(3)}';
}

class FlightThermal {
  const FlightThermal({
    required this.distance,
    required this.centerX,
    required this.radius,
    required this.lift,
  });

  final double distance;
  final double centerX;
  final double radius;
  final double lift;

  String get signature =>
      '${distance.toStringAsFixed(3)}:${centerX.toStringAsFixed(3)}:'
      '${radius.toStringAsFixed(3)}:${lift.toStringAsFixed(3)}';
}

class FlightWind {
  const FlightWind({
    required this.cross,
    required this.vertical,
    required this.forward,
  });

  final double cross;
  final double vertical;
  final double forward;
}

class FlightLandingStrip {
  const FlightLandingStrip({
    required this.centerX,
    required this.width,
    required this.altitude,
    required this.altitudeTolerance,
    required this.maxSinkRate,
  });

  final double centerX;
  final double width;
  final double altitude;
  final double altitudeTolerance;
  final double maxSinkRate;

  String get signature =>
      '${centerX.toStringAsFixed(3)}:${width.toStringAsFixed(3)}:'
      '${altitude.toStringAsFixed(3)}:'
      '${altitudeTolerance.toStringAsFixed(3)}:'
      '${maxSinkRate.toStringAsFixed(3)}';
}

class PaperFlightScenario {
  const PaperFlightScenario._({
    required this.level,
    required this.seed,
    required this.gates,
    required this.thermals,
    required this.windCross,
    required this.windVertical,
    required this.windForward,
    required this.windGust,
    required this.windFrequency,
    required this.windPhase,
    required this.landing,
    required this.missLimit,
    required this.goldTimeSeconds,
    required this.cruiseSpeed,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, PaperFlightScenario> _campaign =
      <int, PaperFlightScenario>{};
  static final Map<int, PaperFlightScenario> _practice =
      <int, PaperFlightScenario>{};

  final int level;
  final int seed;
  final List<FlightGate> gates;
  final List<FlightThermal> thermals;
  final double windCross;
  final double windVertical;
  final double windForward;
  final double windGust;
  final double windFrequency;
  final double windPhase;
  final FlightLandingStrip landing;
  final int missLimit;
  final double goldTimeSeconds;
  final double cruiseSpeed;

  FlightWind windAt(double distance, double elapsed) {
    final double wave = math.sin(elapsed * windFrequency + windPhase);
    final double depthWave = math.cos(
      elapsed * windFrequency * .81 + windPhase,
    );
    return FlightWind(
      cross: windCross + windGust * wave,
      vertical: windVertical + windGust * .35 * depthWave,
      forward:
          (windForward + windGust * .28 * math.sin(distance * 12 + windPhase))
              .clamp(-.2, .2)
              .toDouble(),
    );
  }

  String get signature =>
      '$level|${gates.map((FlightGate gate) => gate.signature).join(';')}|'
      '${thermals.map((FlightThermal thermal) => thermal.signature).join(';')}|'
      '${windCross.toStringAsFixed(3)}:${windVertical.toStringAsFixed(3)}:'
      '${windForward.toStringAsFixed(3)}:${windGust.toStringAsFixed(3)}:'
      '${windFrequency.toStringAsFixed(3)}:${windPhase.toStringAsFixed(3)}|'
      '${landing.signature}|$missLimit:${goldTimeSeconds.toStringAsFixed(2)}:'
      '${cruiseSpeed.toStringAsFixed(3)}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static PaperFlightScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static PaperFlightScenario forPracticeRound(int index) {
    if (index < 1 || index > maximumPracticeRounds) {
      throw RangeError.range(index, 1, maximumPracticeRounds, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      forLevel(level);
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      _practice[next] = _build(level, replayIndex: next);
    }
    return _practice[index]!;
  }

  static Set<String> get _usedSignatures => <String>{
    ..._campaign.values.map((PaperFlightScenario course) => course.signature),
    ..._practice.values.map((PaperFlightScenario course) => course.signature),
  };

  static PaperFlightScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'paper_flight:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int gateCount = level + 2;
      final double gateWidth = (.35 - level * .018).clamp(.16, .33).toDouble();
      final double gateHeight = (.27 - level * .012).clamp(.13, .25).toDouble();
      final List<FlightGate> gates = <FlightGate>[];
      double previousX = .5;
      double previousAltitude = .61;
      for (int index = 0; index < gateCount; index++) {
        previousX =
            (previousX + (random.nextDouble() - .5) * (.12 + level * .008))
                .clamp(.31, .69)
                .toDouble();
        previousAltitude = (previousAltitude + (random.nextDouble() - .5) * .13)
            .clamp(.39, .75)
            .toDouble();
        final double movement = level <= 3
            ? 0
            : .004 + (level - 3) * .004 + random.nextDouble() * .009;
        gates.add(
          FlightGate(
            distance: .12 + (index + 1) * .70 / (gateCount + 1),
            centerX: previousX,
            altitude: previousAltitude,
            width: gateWidth,
            height: gateHeight,
            drift: movement,
            frequency: .42 + level * .043 + random.nextDouble() * .12,
            phase: random.nextDouble() * math.pi * 2,
          ),
        );
      }

      final List<FlightThermal> thermals = <FlightThermal>[];
      final int thermalCount = level <= 2 ? 1 : (level + 1) ~/ 2;
      for (int index = 0; index < thermalCount; index++) {
        final double distance = .19 + (index + 1) * .61 / (thermalCount + 1);
        final double nearbyX = gates
            .firstWhere(
              (FlightGate gate) => (gate.distance - distance).abs() < .15,
              orElse: () => gates.first,
            )
            .centerX;
        thermals.add(
          FlightThermal(
            distance: distance,
            centerX: (nearbyX + (random.nextDouble() - .5) * .12)
                .clamp(.28, .72)
                .toDouble(),
            radius: .14 - level * .004,
            lift: .04 + level * .004 + random.nextDouble() * .022,
          ),
        );
      }

      final double landingX =
          (gates.last.centerX + (random.nextDouble() - .5) * .08)
              .clamp(.34, .66)
              .toDouble();
      final PaperFlightScenario candidate = PaperFlightScenario._(
        level: level,
        seed: seed,
        gates: List<FlightGate>.unmodifiable(gates),
        thermals: List<FlightThermal>.unmodifiable(thermals),
        windCross: (random.nextDouble() - .5) * (level <= 2 ? 0 : level * .012),
        windVertical:
            (random.nextDouble() - .5) * (level <= 2 ? 0 : level * .009),
        windForward:
            (random.nextDouble() - .5) * (level <= 2 ? 0 : level * .028),
        windGust: level <= 2 ? 0 : .003 + level * .0028,
        windFrequency: .48 + level * .065,
        windPhase: random.nextDouble() * math.pi * 2,
        landing: FlightLandingStrip(
          centerX: landingX,
          width: (.38 - level * .017).clamp(.2, .35).toDouble(),
          altitude: .28 + random.nextDouble() * .09,
          altitudeTolerance: (.17 - level * .007).clamp(.09, .16).toDouble(),
          maxSinkRate: (.12 - level * .005).clamp(.065, .11).toDouble(),
        ),
        missLimit: level <= 3
            ? 4
            : level <= 6
            ? 3
            : level <= 8
            ? 2
            : 1,
        goldTimeSeconds: math.max(22, 62 - level * 3.7),
        cruiseSpeed: .095 + level * .0015,
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique, fair paper-flight route.');
  }

  static bool _isFair(PaperFlightScenario course) {
    if (course.gates.length < 3 || course.gates.length > 12) return false;
    FlightGate previous = const FlightGate(
      distance: 0,
      centerX: .5,
      altitude: .61,
      width: 1,
      height: 1,
      drift: 0,
      frequency: 0,
      phase: 0,
    );
    for (final FlightGate gate in course.gates) {
      if (gate.centerX - gate.drift - gate.width / 2 < .16 ||
          gate.centerX + gate.drift + gate.width / 2 > .84 ||
          gate.altitude - gate.height / 2 < .24 ||
          gate.altitude + gate.height / 2 > .88 ||
          (gate.centerX - previous.centerX).abs() > .19 ||
          (gate.altitude - previous.altitude).abs() > .17) {
        return false;
      }
      previous = gate;
    }
    return course.landing.centerX >= .34 &&
        course.landing.centerX <= .66 &&
        course.landing.width >= .2 &&
        course.landing.altitudeTolerance >= .09 &&
        course.gates.first.distance > .1 &&
        course.gates.last.distance < .9;
  }
}
