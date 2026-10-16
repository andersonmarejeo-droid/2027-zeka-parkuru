import 'dart:math' as math;

import '../shared/content_seed.dart';

class CourierCheckpoint {
  const CourierCheckpoint({
    required this.progress,
    required this.centerX,
    required this.centerAltitude,
    required this.halfWidth,
    required this.halfHeight,
    required this.crosswind,
    required this.updraft,
    required this.safeSpeed,
    this.coolantVent = false,
    this.deliveryDock = false,
  });

  final double progress;
  final double centerX;
  final double centerAltitude;
  final double halfWidth;
  final double halfHeight;
  final double crosswind;
  final double updraft;
  final double safeSpeed;
  final bool coolantVent;
  final bool deliveryDock;

  String get signature =>
      '${progress.toStringAsFixed(2)}:${centerX.toStringAsFixed(3)}:'
      '${centerAltitude.toStringAsFixed(3)}:${halfWidth.toStringAsFixed(3)}:'
      '${halfHeight.toStringAsFixed(3)}:${crosswind.toStringAsFixed(2)}:'
      '${updraft.toStringAsFixed(2)}:${safeSpeed.toStringAsFixed(2)}:'
      '${coolantVent ? 1 : 0}:${deliveryDock ? 1 : 0}';
}

class JetpackCourierScenario {
  const JetpackCourierScenario({
    required this.level,
    required this.seed,
    required this.checkpoints,
    required this.missLimit,
    required this.fuelCapacity,
    required this.packageTolerance,
    required this.forwardSpeed,
    required this.finishProgress,
  });

  static const int campaignLevels = 10;
  static const int practiceFlights = 300;

  final int level;
  final int seed;
  final List<CourierCheckpoint> checkpoints;
  final int missLimit;
  final double fuelCapacity;
  final double packageTolerance;
  final double forwardSpeed;
  final double finishProgress;

  String get signature =>
      '$level|$missLimit|${fuelCapacity.toStringAsFixed(1)}|'
      '${checkpoints.map((CourierCheckpoint point) => point.signature).join(';')}';

  static JetpackCourierScenario forLevel(int level) {
    final int normalized = RangeError.checkValueInInterval(
      level,
      1,
      campaignLevels,
      'level',
    );
    return _create(
      normalized,
      ContentSeed.forLevel(gameId: 'jetpack_courier', level: normalized),
    );
  }

  static JetpackCourierScenario forPracticeFlight(int index) {
    final int normalized = RangeError.checkValueInInterval(
      index,
      1,
      practiceFlights,
      'index',
    );
    return _create(
      1 + ((normalized - 1) % campaignLevels),
      ContentSeed.forLevel(
        gameId: 'jetpack_courier_practice',
        level: normalized,
      ),
    );
  }

  static JetpackCourierScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int checkpointCount = 4 + level;
    final double halfWidth = .245 - level * .0125;
    final double halfHeight = .225 - level * .0105;
    final List<CourierCheckpoint> points = <CourierCheckpoint>[];
    double x = .5;
    double altitude = .43;
    final double spacing = 1.68 - level * .025;
    for (int index = 0; index < checkpointCount; index++) {
      final bool dock = index == checkpointCount - 1;
      final double shift = level >= 8 ? .145 : .18;
      x = (x + (random.nextDouble() * 2 - 1) * shift)
          .clamp(.20 + halfWidth, .80 - halfWidth)
          .toDouble();
      altitude = (altitude + (random.nextDouble() * 2 - 1) * shift)
          .clamp(.25 + halfHeight, .78 - halfHeight)
          .toDouble();
      final bool vent = !dock && level >= 4 && index % 3 == 1;
      points.add(
        CourierCheckpoint(
          // The final ring is a deliberate docking approach, not another
          // ordinary gate: give the player a longer runway to shed altitude
          // and lateral momentum before touching down.
          progress: 1.35 + index * spacing + (dock ? spacing : 0),
          centerX: x,
          centerAltitude: dock ? .24 : altitude,
          halfWidth: dock ? halfWidth * .76 : halfWidth,
          halfHeight: dock ? math.min(halfHeight * .35, .05) : halfHeight,
          crosswind: (random.nextDouble() * 2 - 1) * (.018 + level * .0058),
          updraft: (random.nextDouble() * 2 - 1) * (.012 + level * .0035),
          safeSpeed: dock
              ? .44 - level * .012
              : .94 - level * .027 + (vent ? .07 : 0),
          coolantVent: vent,
          deliveryDock: dock,
        ),
      );
    }
    return JetpackCourierScenario(
      level: level,
      seed: seed,
      checkpoints: List<CourierCheckpoint>.unmodifiable(points),
      missLimit: level >= 10
          ? 1
          : level >= 8
          ? 2
          : level >= 5
          ? 3
          : 4,
      fuelCapacity: 100 - level * 1.8,
      packageTolerance: level >= 9
          ? 36
          : level >= 6
          ? 52
          : 68,
      forwardSpeed: 1.32 + level * .025,
      finishProgress: points.last.progress + .72,
    );
  }
}
