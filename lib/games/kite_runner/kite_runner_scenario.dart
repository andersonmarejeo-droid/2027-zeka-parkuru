import 'dart:math' as math;

import '../shared/content_seed.dart';

class KiteGate {
  const KiteGate({
    required this.distance,
    required this.centerX,
    required this.altitude,
    required this.width,
    required this.height,
    required this.sway,
    required this.phase,
  });

  final double distance;
  final double centerX;
  final double altitude;
  final double width;
  final double height;
  final double sway;
  final double phase;

  double centerAt(double seconds) =>
      centerX + sway * math.sin(seconds * .8 + phase);

  String get signature => <double>[
    distance,
    centerX,
    altitude,
    width,
    height,
    sway,
    phase,
  ].map((double value) => value.toStringAsFixed(4)).join(':');
}

class KiteWire {
  const KiteWire({
    required this.distance,
    required this.centerX,
    required this.altitude,
    required this.width,
  });

  final double distance;
  final double centerX;
  final double altitude;
  final double width;

  String get signature =>
      '${distance.toStringAsFixed(4)}:${centerX.toStringAsFixed(4)}:'
      '${altitude.toStringAsFixed(4)}:${width.toStringAsFixed(4)}';
}

class KiteWind {
  const KiteWind({
    required this.cross,
    required this.lift,
    required this.gust,
    required this.phase,
  });

  final double cross;
  final double lift;
  final double gust;
  final double phase;
}

/// Deterministic kite-and-tether courses. Unlike gliding, control is about
/// trimming tether length and steering tension through changing crosswinds.
class KiteRunnerScenario {
  const KiteRunnerScenario({
    required this.level,
    required this.seed,
    required this.gates,
    required this.wires,
    required this.crosswind,
    required this.lift,
    required this.gustStrength,
    required this.snapThreshold,
    required this.missLimit,
    required this.cruiseSpeed,
    required this.goldTimeSeconds,
  });

  static const int campaignLevels = 10;
  static const int practiceRoutes = 300;

  final int level;
  final int seed;
  final List<KiteGate> gates;
  final List<KiteWire> wires;
  final double crosswind;
  final double lift;
  final double gustStrength;
  final double snapThreshold;
  final int missLimit;
  final double cruiseSpeed;
  final double goldTimeSeconds;

  KiteWind windAt(double distance, double elapsed) {
    final double progress = distance.clamp(0, 1).toDouble();
    final double gustWave = math.sin(
      elapsed * (1.25 + level * .025) + seed % 31,
    );
    final double crossWave = math.sin(
      distance * 13 + elapsed * .44 + seed % 17,
    );
    return KiteWind(
      cross: crosswind * (.62 + .38 * progress) + gustWave * gustStrength * .42,
      lift: lift + progress * .08 + math.cos(elapsed * .37 + seed % 23) * .08,
      gust: gustWave * gustStrength,
      phase: crossWave,
    );
  }

  String get signature =>
      '$level|${gates.map((KiteGate gate) => gate.signature).join(';')}|'
      '${wires.map((KiteWire wire) => wire.signature).join(';')}|'
      '$crosswind|$lift|$gustStrength|$snapThreshold|$missLimit|'
      '$cruiseSpeed|$goldTimeSeconds';

  static KiteRunnerScenario forLevel(int level) {
    final int normalized = RangeError.checkValueInInterval(
      level,
      1,
      campaignLevels,
      'level',
    );
    return _create(
      normalized,
      ContentSeed.forLevel(gameId: 'kite_runner', level: normalized),
    );
  }

  static KiteRunnerScenario forPracticeRoute(int index) {
    final int normalized = RangeError.checkValueInInterval(
      index,
      1,
      practiceRoutes,
      'index',
    );
    return _create(
      1 + ((normalized - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'kite_runner_practice', level: normalized),
    );
  }

  static KiteRunnerScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int gateCount = level + 2;
    final double gateWidth = switch (level) {
      <= 3 => .43,
      <= 6 => .41,
      <= 8 => .27,
      9 => .22,
      _ => .18,
    };
    final double heightWindow = switch (level) {
      <= 3 => .38,
      <= 6 => .31,
      <= 8 => .24,
      9 => .20,
      _ => .16,
    };
    double plannedAltitude = .56;
    double plannedX = .5;
    final double lateralStep = switch (level) {
      <= 6 => .36,
      <= 8 => .28,
      _ => .22,
    };
    final double verticalStep = switch (level) {
      <= 6 => .12,
      <= 8 => .10,
      _ => .08,
    };
    final List<KiteGate> gates = List<KiteGate>.generate(gateCount, (
      int index,
    ) {
      final double distance = .13 + (index + 1) * (.72 / (gateCount + 1));
      plannedAltitude =
          (plannedAltitude + (random.nextDouble() - .5) * verticalStep)
              .clamp(.40, .70)
              .toDouble();
      plannedX = (plannedX + (random.nextDouble() - .5) * lateralStep)
          .clamp(.31, .69)
          .toDouble();
      return KiteGate(
        distance: distance,
        centerX: plannedX,
        altitude: plannedAltitude,
        width: gateWidth,
        height: heightWindow,
        sway: level >= 5 ? .012 + random.nextDouble() * .024 : 0,
        phase: random.nextDouble() * math.pi * 2,
      );
    }, growable: false);
    final int wireCount = level < 4 ? 0 : (level - 2) ~/ 2;
    final List<KiteWire> wires = List<KiteWire>.generate(wireCount, (
      int index,
    ) {
      final int gateGap = math.min(index + 1, gateCount - 1);
      final double leftDistance = gates[gateGap - 1].distance;
      final double rightDistance = gates[gateGap].distance;
      return KiteWire(
        distance: (leftDistance + rightDistance) * .5,
        centerX: .22 + random.nextDouble() * .56,
        altitude: .32 + random.nextDouble() * .38,
        width: .15 + random.nextDouble() * .035,
      );
    }, growable: false);
    return KiteRunnerScenario(
      level: level,
      seed: seed,
      gates: List<KiteGate>.unmodifiable(gates),
      wires: List<KiteWire>.unmodifiable(wires),
      crosswind: level <= 2 ? 0 : .08 + level * .019,
      lift: .14 - level * .004,
      gustStrength: level <= 2 ? 0 : .035 + level * .012,
      snapThreshold: .96 - level * .023,
      missLimit: level >= 10
          ? 1
          : level >= 8
          ? 2
          : 3,
      cruiseSpeed: .077 + level * .002,
      goldTimeSeconds: 40 - level * 1.7,
    );
  }
}
