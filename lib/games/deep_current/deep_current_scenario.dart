import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../shared/content_seed.dart';

class DeepCurrentSalvage {
  const DeepCurrentSalvage({
    required this.position,
    required this.mass,
    required this.value,
  });

  final Offset position;
  final double mass;
  final int value;

  String get signature =>
      '${_point(position)}:${mass.toStringAsFixed(3)}:$value';
}

class DeepCurrentReef {
  const DeepCurrentReef({required this.center, required this.radius});

  final Offset center;
  final double radius;

  String get signature => '${_point(center)}:${radius.toStringAsFixed(3)}';
}

class DeepCurrentFlow {
  const DeepCurrentFlow({
    required this.center,
    required this.radius,
    required this.force,
  });

  final Offset center;
  final double radius;
  final Offset force;

  String get signature =>
      '${_point(center)}:${radius.toStringAsFixed(3)}:${_point(force)}';
}

class DeepCurrentScenario {
  const DeepCurrentScenario._({
    required this.level,
    required this.seed,
    required this.salvage,
    required this.reefs,
    required this.currents,
    required this.oxygenCapacity,
    required this.batteryCapacity,
    required this.hullCapacity,
    required this.safeDepth,
    required this.sonarRange,
    required this.subSpeed,
  });

  static const int campaignLevels = 20;
  static const int practiceMissions = 300;
  static const Offset base = Offset(.105, .50);

  final int level;
  final int seed;
  final List<DeepCurrentSalvage> salvage;
  final List<DeepCurrentReef> reefs;
  final List<DeepCurrentFlow> currents;
  final double oxygenCapacity;
  final double batteryCapacity;
  final double hullCapacity;
  final double safeDepth;
  final double sonarRange;
  final double subSpeed;

  String get signature => <String>[
    '$level:$seed:${oxygenCapacity.toStringAsFixed(2)}:${batteryCapacity.toStringAsFixed(2)}:${safeDepth.toStringAsFixed(3)}',
    's:${salvage.map((DeepCurrentSalvage item) => item.signature).join(';')}',
    'r:${reefs.map((DeepCurrentReef reef) => reef.signature).join(';')}',
    'c:${currents.map((DeepCurrentFlow flow) => flow.signature).join(';')}',
  ].join('::');

  static DeepCurrentScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'deep_current_campaign', level: level),
    );
  }

  static DeepCurrentScenario forPracticeMission(int index) {
    if (index < 1 || index > practiceMissions) {
      throw RangeError.range(index, 1, practiceMissions, 'index');
    }
    return _build(
      1 + ((index - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'deep_current_practice', level: index),
    );
  }

  static DeepCurrentScenario _build(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int cargoCount = (1 + (level - 1) ~/ 6).clamp(1, 4);
    final List<DeepCurrentSalvage> salvage = <DeepCurrentSalvage>[
      for (int index = 0; index < cargoCount; index++)
        DeepCurrentSalvage(
          position: Offset(
            .30 + index * .145 + random.nextDouble() * .035,
            .39 + random.nextDouble() * .22,
          ),
          mass: .12 + random.nextDouble() * (.20 + level * .004),
          value: 90 + index * 25 + level * 3,
        ),
    ];
    final int reefCount = (2 + level ~/ 2).clamp(2, 12);
    final List<DeepCurrentReef> reefs = <DeepCurrentReef>[
      for (int index = 0; index < reefCount; index++)
        DeepCurrentReef(
          center: Offset(
            .22 + random.nextDouble() * .70,
            index.isEven
                ? .13 + random.nextDouble() * .14
                : .73 + random.nextDouble() * .13,
          ),
          radius: .035 + random.nextDouble() * .035,
        ),
    ];
    final int currentCount = (1 + level ~/ 5).clamp(1, 5);
    final List<DeepCurrentFlow> currents = <DeepCurrentFlow>[
      for (int index = 0; index < currentCount; index++)
        DeepCurrentFlow(
          center: Offset(
            .28 + random.nextDouble() * .62,
            .28 + random.nextDouble() * .44,
          ),
          radius: .16 + random.nextDouble() * .14,
          force: Offset(
            (random.nextDouble() - .5) * (.025 + level * .0009),
            (random.nextDouble() - .5) * (.035 + level * .0012),
          ),
        ),
    ];
    return DeepCurrentScenario._(
      level: level,
      seed: seed,
      salvage: List<DeepCurrentSalvage>.unmodifiable(salvage),
      reefs: List<DeepCurrentReef>.unmodifiable(reefs),
      currents: List<DeepCurrentFlow>.unmodifiable(currents),
      oxygenCapacity: (96 - level * 1.35).clamp(66, 95).toDouble(),
      batteryCapacity: (105 - level * 1.45).clamp(74, 104).toDouble(),
      hullCapacity: 100,
      safeDepth: (.91 - level * .006).clamp(.77, .90).toDouble(),
      sonarRange: (.53 + level * .006).clamp(.53, .68).toDouble(),
      subSpeed: (.205 - level * .0032).clamp(.14, .202).toDouble(),
    );
  }
}

String _point(Offset point) =>
    '${point.dx.toStringAsFixed(4)},${point.dy.toStringAsFixed(4)}';
