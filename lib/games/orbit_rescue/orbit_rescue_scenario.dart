import 'dart:math' as math;

import '../shared/content_seed.dart';

class OrbitBody {
  const OrbitBody({
    required this.x,
    required this.y,
    required this.radius,
    required this.gravity,
    required this.tintIndex,
  });

  final double x;
  final double y;
  final double radius;
  final double gravity;
  final int tintIndex;

  String get signature =>
      '${x.toStringAsFixed(3)},${y.toStringAsFixed(3)},'
      '${radius.toStringAsFixed(3)},${gravity.toStringAsFixed(5)},$tintIndex';
}

class OrbitGate {
  const OrbitGate({
    required this.x,
    required this.y,
    required this.radius,
    required this.safeSpeed,
    this.docking = false,
    this.motionAmplitude = 0,
    this.motionPeriod = 1,
    this.motionPhase = 0,
  });

  final double x;
  final double y;
  final double radius;
  final double safeSpeed;
  final bool docking;
  final double motionAmplitude;
  final double motionPeriod;
  final double motionPhase;

  double yAt(double elapsed) =>
      y +
      motionAmplitude *
          math.sin(elapsed * math.pi * 2 / motionPeriod + motionPhase);

  String get signature =>
      '${x.toStringAsFixed(3)},${y.toStringAsFixed(3)},'
      '${radius.toStringAsFixed(3)},${safeSpeed.toStringAsFixed(3)},'
      '${docking ? 1 : 0},${motionAmplitude.toStringAsFixed(3)},'
      '${motionPeriod.toStringAsFixed(2)},${motionPhase.toStringAsFixed(3)}';
}

class OrbitRescueScenario {
  const OrbitRescueScenario({
    required this.level,
    required this.seed,
    required this.bodies,
    required this.gates,
    required this.fuelCapacity,
    required this.shieldCapacity,
    required this.pulseLimit,
    required this.missLimit,
  });

  static const int campaignLevels = 10;
  static const int practiceCourses = 300;

  final int level;
  final int seed;
  final List<OrbitBody> bodies;
  final List<OrbitGate> gates;
  final double fuelCapacity;
  final double shieldCapacity;
  final int pulseLimit;
  final int missLimit;

  String get signature =>
      '$level|$pulseLimit|${fuelCapacity.toStringAsFixed(1)}|'
      '${bodies.map((OrbitBody body) => body.signature).join(';')}|'
      '${gates.map((OrbitGate gate) => gate.signature).join(';')}';

  static OrbitRescueScenario forLevel(int level) {
    final int normalized = RangeError.checkValueInInterval(
      level,
      1,
      campaignLevels,
      'level',
    );
    return _create(
      normalized,
      ContentSeed.forLevel(gameId: 'orbit_rescue', level: normalized),
    );
  }

  static OrbitRescueScenario forPracticeCourse(int index) {
    final int normalized = RangeError.checkValueInInterval(
      index,
      1,
      practiceCourses,
      'index',
    );
    return _create(
      1 + ((normalized - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'orbit_rescue_practice', level: normalized),
    );
  }

  static OrbitRescueScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int gateCount = 4 + ((level + 1) ~/ 2);
    final double aperture = .165 - level * .0082;
    final List<OrbitGate> gates = <OrbitGate>[];
    double routeY = .5;
    for (int index = 0; index < gateCount; index++) {
      final bool docking = index == gateCount - 1;
      final double x = docking ? .91 : .21 + index * (.66 / (gateCount - 1));
      final double y;
      if (docking) {
        y = .5;
      } else {
        final double step = .07 - level * .0025;
        final double candidate = (routeY + (random.nextDouble() * 2 - 1) * step)
            .clamp(.34, .66)
            .toDouble();
        y = index == gateCount - 2
            ? (.5 + (candidate - .5).clamp(-.04, .04)).toDouble()
            : candidate;
        routeY = y;
      }
      gates.add(
        OrbitGate(
          x: x,
          y: y,
          radius: docking ? aperture * .82 : aperture,
          safeSpeed: docking ? .255 - level * .006 : .36 - level * .006,
          docking: docking,
          motionAmplitude: docking ? .012 + level * .0024 : 0,
          motionPeriod: docking ? 5.4 - level * .08 : 1,
          motionPhase: docking ? random.nextDouble() * math.pi * 2 : 0,
        ),
      );
    }
    final List<OrbitBody> bodies = <OrbitBody>[
      for (int index = 0; index < 3; index++)
        OrbitBody(
          x: .31 + index * .215 + (random.nextDouble() - .5) * .045,
          y: index.isEven
              ? .20 + random.nextDouble() * .055
              : .745 + random.nextDouble() * .055,
          radius: .043 + level * .0017,
          gravity: .00033 + level * .000026,
          tintIndex: (index + level) % 3,
        ),
    ];
    return OrbitRescueScenario(
      level: level,
      seed: seed,
      bodies: List<OrbitBody>.unmodifiable(bodies),
      gates: List<OrbitGate>.unmodifiable(gates),
      fuelCapacity: 100 - level * 4.6,
      shieldCapacity: 100 - math.max(0, level - 2) * 4.5,
      pulseLimit: math.max(2, 9 - level ~/ 2),
      missLimit: level >= 10
          ? 1
          : level >= 8
          ? 2
          : level >= 5
          ? 3
          : 4,
    );
  }
}
