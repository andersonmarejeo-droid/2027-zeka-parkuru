import 'dart:math' as math;

import '../shared/content_seed.dart';

enum SnowSurface { packed, powder, ice, moguls }

class SnowGate {
  const SnowGate({
    required this.distance,
    required this.centerX,
    required this.width,
    required this.surface,
    required this.crosswind,
    required this.safeSpeed,
  });

  final double distance;
  final double centerX;
  final double width;
  final SnowSurface surface;
  final double crosswind;
  final double safeSpeed;

  String get signature =>
      '${distance.toStringAsFixed(2)}:${centerX.toStringAsFixed(3)}:'
      '${width.toStringAsFixed(3)}:${surface.index}:'
      '${crosswind.toStringAsFixed(2)}:${safeSpeed.toStringAsFixed(2)}';
}

class SnowboardSlalomScenario {
  const SnowboardSlalomScenario({
    required this.level,
    required this.seed,
    required this.gates,
    required this.missLimit,
    required this.initialSpeed,
    required this.finishDistance,
  });

  static const int campaignLevels = 10;
  static const int practiceCourses = 300;

  final int level;
  final int seed;
  final List<SnowGate> gates;
  final int missLimit;
  final double initialSpeed;
  final double finishDistance;

  String get signature =>
      '$level|$missLimit|${gates.map((SnowGate gate) => gate.signature).join(';')}';

  static SnowboardSlalomScenario forLevel(int level) {
    final int normalized = RangeError.checkValueInInterval(
      level,
      1,
      campaignLevels,
      'level',
    );
    return _create(
      normalized,
      ContentSeed.forLevel(gameId: 'snowboard_slalom', level: normalized),
    );
  }

  static SnowboardSlalomScenario forPracticeCourse(int index) {
    final int normalized = RangeError.checkValueInInterval(
      index,
      1,
      practiceCourses,
      'index',
    );
    return _create(
      1 + ((normalized - 1) % campaignLevels),
      ContentSeed.forLevel(
        gameId: 'snowboard_slalom_practice',
        level: normalized,
      ),
    );
  }

  static SnowboardSlalomScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int gateCount = 5 + level;
    final double width = .47 - level * .026;
    final List<SnowGate> gates = <SnowGate>[];
    double center = .5;
    for (int index = 0; index < gateCount; index++) {
      final double maxShift = level >= 8 ? .19 : .23;
      center = (center + (random.nextDouble() * 2 - 1) * maxShift)
          .clamp(.16 + width / 2, .84 - width / 2)
          .toDouble();
      SnowSurface surface = switch (level) {
        <= 2 => random.nextBool() ? SnowSurface.packed : SnowSurface.powder,
        <= 5 => SnowSurface.values[random.nextInt(3)],
        _ => SnowSurface.values[random.nextInt(SnowSurface.values.length)],
      };
      if (level >= 7 && index.isEven) surface = SnowSurface.ice;
      if (level >= 9 && index % 4 == 3) surface = SnowSurface.moguls;
      gates.add(
        SnowGate(
          distance: 1.6 + index * (1.95 - level * .025),
          centerX: center,
          width: width,
          surface: surface,
          crosswind: (random.nextDouble() * 2 - 1) * (.02 + level * .007),
          safeSpeed: surface == SnowSurface.moguls
              ? .72 - level * .007
              : surface == SnowSurface.ice
              ? .9
              : 1.0,
        ),
      );
    }
    return SnowboardSlalomScenario(
      level: level,
      seed: seed,
      gates: List<SnowGate>.unmodifiable(gates),
      missLimit: level >= 10
          ? 1
          : level >= 8
          ? 2
          : level >= 5
          ? 3
          : 4,
      initialSpeed: .48 + level * .017,
      finishDistance: gates.last.distance + 1.55,
    );
  }
}
