import 'dart:math' as math;

import '../shared/content_seed.dart';

class PinballTarget {
  const PinballTarget({
    required this.x,
    required this.y,
    required this.radius,
    required this.driftX,
    required this.driftY,
    required this.phase,
    required this.frequency,
  });

  final double x;
  final double y;
  final double radius;
  final double driftX;
  final double driftY;
  final double phase;
  final double frequency;

  ({double x, double y}) at(double seconds) => (
    x: x + driftX * math.sin(seconds * frequency + phase),
    y: y + driftY * math.sin(seconds * frequency * .73 + phase * 1.7),
  );

  String get signature => <double>[
    x,
    y,
    radius,
    driftX,
    driftY,
    phase,
    frequency,
  ].map((double value) => value.toStringAsFixed(4)).join(':');
}

class PinballBumper {
  const PinballBumper({required this.x, required this.y, required this.radius});

  final double x;
  final double y;
  final double radius;

  String get signature =>
      '${x.toStringAsFixed(4)}:${y.toStringAsFixed(4)}:${radius.toStringAsFixed(4)}';
}

/// A deterministic table: all target sequences and collision geometry are
/// reproducible from the seed for replay and QA.
class NeonPinballScenario {
  const NeonPinballScenario({
    required this.level,
    required this.seed,
    required this.targets,
    required this.bumpers,
    required this.goldTimeSeconds,
    required this.comboWindowSeconds,
    required this.totalBalls,
    required this.hasLock,
  });

  static const int campaignLevels = 10;
  static const int practiceLayouts = 300;

  final int level;
  final int seed;
  final List<PinballTarget> targets;
  final List<PinballBumper> bumpers;
  final double goldTimeSeconds;
  final double comboWindowSeconds;
  final int totalBalls;
  final bool hasLock;

  int get lockTargetIndex => targets.length ~/ 2;

  String get signature =>
      '$level|${targets.map((PinballTarget target) => target.signature).join(';')}|'
      '${bumpers.map((PinballBumper bumper) => bumper.signature).join(';')}|'
      '$goldTimeSeconds|$comboWindowSeconds|$hasLock';

  static NeonPinballScenario forLevel(int level) {
    final int normalized = RangeError.checkValueInInterval(
      level,
      1,
      campaignLevels,
      'level',
    );
    return _create(
      normalized,
      ContentSeed.forLevel(gameId: 'neon_pinball', level: normalized),
    );
  }

  static NeonPinballScenario forPracticeLayout(int index) {
    final int normalized = RangeError.checkValueInInterval(
      index,
      1,
      practiceLayouts,
      'index',
    );
    return _create(
      1 + ((normalized - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'neon_pinball_practice', level: normalized),
    );
  }

  static NeonPinballScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int targetCount = level + 2;
    final double radius = switch (level) {
      <= 3 => .039,
      <= 6 => .034,
      <= 8 => .030,
      9 => .027,
      _ => .024,
    };
    final double driftScale = level >= 7 ? .038 + (level - 7) * .009 : .012;
    final List<PinballTarget> targets = <PinballTarget>[];
    for (int index = 0; index < targetCount; index++) {
      double x = .5;
      double y = .3;
      for (int attempt = 0; attempt < 120; attempt++) {
        x = .19 + random.nextDouble() * .62;
        y = .17 + random.nextDouble() * .48;
        final bool spaced = targets.every((PinballTarget other) {
          final double dx = (other.x - x) * 1.04;
          final double dy = other.y - y;
          return math.sqrt(dx * dx + dy * dy) >= .105;
        });
        if (spaced) break;
      }
      targets.add(
        PinballTarget(
          x: x,
          y: y,
          radius: radius,
          driftX: level >= 5 ? (random.nextDouble() * 2 - 1) * driftScale : 0,
          driftY: level >= 7
              ? (random.nextDouble() * 2 - 1) * driftScale * .45
              : 0,
          phase: random.nextDouble() * math.pi * 2,
          frequency: .32 + random.nextDouble() * (level >= 7 ? .74 : .22),
        ),
      );
    }

    final List<PinballBumper> bumpers = <PinballBumper>[
      PinballBumper(
        x: .34 + random.nextDouble() * .10,
        y: .40 + random.nextDouble() * .07,
        radius: .039 - math.min(level, 10) * .0008,
      ),
      PinballBumper(
        x: .56 + random.nextDouble() * .10,
        y: .40 + random.nextDouble() * .07,
        radius: .039 - math.min(level, 10) * .0008,
      ),
      if (level >= 4)
        PinballBumper(
          x: .46 + random.nextDouble() * .08,
          y: .26 + random.nextDouble() * .07,
          radius: .034 - math.min(level, 10) * .00065,
        ),
    ];
    return NeonPinballScenario(
      level: level,
      seed: seed,
      targets: List<PinballTarget>.unmodifiable(targets),
      bumpers: List<PinballBumper>.unmodifiable(bumpers),
      goldTimeSeconds: 82 - level * 2.8,
      comboWindowSeconds: level >= 7 ? 2.5 : 4.0,
      totalBalls: level >= 9 ? 2 : 3,
      hasLock: level >= 9,
    );
  }
}
