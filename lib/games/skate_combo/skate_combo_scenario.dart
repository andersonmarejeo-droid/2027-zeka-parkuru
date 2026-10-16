import 'dart:math' as math;

import '../shared/content_seed.dart';

enum SkateFeature { quarterPipe, stairGap, railTransfer, bowlLip }

class SkateJump {
  const SkateJump({
    required this.takeoffSeconds,
    required this.airtimeSeconds,
    required this.targetRotation,
    required this.targetBalance,
    required this.minimumSpeed,
    required this.balanceTolerance,
    required this.rotationTolerance,
    required this.feature,
  });

  final double takeoffSeconds;
  final double airtimeSeconds;
  final double targetRotation;
  final double targetBalance;
  final double minimumSpeed;
  final double balanceTolerance;
  final double rotationTolerance;
  final SkateFeature feature;

  double get landingSeconds => takeoffSeconds + airtimeSeconds;

  String get signature =>
      '${takeoffSeconds.toStringAsFixed(2)}:${airtimeSeconds.toStringAsFixed(2)}:'
      '${targetRotation.toStringAsFixed(0)}:${targetBalance.toStringAsFixed(2)}:'
      '${minimumSpeed.toStringAsFixed(2)}:${feature.index}';
}

class SkateComboScenario {
  const SkateComboScenario({
    required this.level,
    required this.seed,
    required this.jumps,
    required this.missLimit,
    required this.pushPerfectWindow,
    required this.finishSeconds,
  });

  static const int campaignLevels = 10;
  static const int practiceRoutes = 300;

  final int level;
  final int seed;
  final List<SkateJump> jumps;
  final int missLimit;
  final double pushPerfectWindow;
  final double finishSeconds;

  String get signature =>
      '$level|$missLimit|${jumps.map((SkateJump jump) => jump.signature).join(';')}';

  static SkateComboScenario forLevel(int level) {
    final int normalized = RangeError.checkValueInInterval(
      level,
      1,
      campaignLevels,
      'level',
    );
    return _create(
      normalized,
      ContentSeed.forLevel(gameId: 'skate_combo', level: normalized),
    );
  }

  static SkateComboScenario forPracticeRoute(int index) {
    final int normalized = RangeError.checkValueInInterval(
      index,
      1,
      practiceRoutes,
      'index',
    );
    return _create(
      1 + ((normalized - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'skate_combo_practice', level: normalized),
    );
  }

  static SkateComboScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int jumpCount = 3 + (level + 1) ~/ 2;
    final double airtime = 1.24 - level * .026;
    final List<SkateJump> jumps = <SkateJump>[];
    double takeoff = 2.0;
    for (int index = 0; index < jumpCount; index++) {
      final bool finale = index == jumpCount - 1;
      final int rotations = switch (level) {
        <= 2 => index.isEven ? 360 : 540,
        <= 4 => index.isEven ? 540 : 720,
        <= 6 => index.isEven ? 720 : 540,
        7 || 8 => index.isEven ? 900 : 720,
        9 => index.isEven ? 1080 : 900,
        _ =>
          finale
              ? 1440
              : index.isEven
              ? 1080
              : 900,
      };
      jumps.add(
        SkateJump(
          takeoffSeconds: takeoff,
          airtimeSeconds: airtime - (finale && level >= 8 ? .08 : 0),
          targetRotation: rotations.toDouble(),
          targetBalance: (random.nextDouble() * .62 - .31),
          minimumSpeed: .39 + level * .037 + (finale ? .045 : 0),
          balanceTolerance: math.max(.105, .37 - level * .024),
          rotationTolerance: math.max(55, 176 - level * 11).toDouble(),
          feature:
              SkateFeature.values[random.nextInt(SkateFeature.values.length)],
        ),
      );
      takeoff += math.max(1.8, 3.15 - level * .105) + random.nextDouble() * .32;
    }
    return SkateComboScenario(
      level: level,
      seed: seed,
      jumps: List<SkateJump>.unmodifiable(jumps),
      missLimit: level >= 10
          ? 1
          : level >= 8
          ? 2
          : level >= 5
          ? 3
          : 4,
      pushPerfectWindow: math.max(.12, .33 - level * .018),
      finishSeconds: jumps.last.landingSeconds + .55,
    );
  }
}
