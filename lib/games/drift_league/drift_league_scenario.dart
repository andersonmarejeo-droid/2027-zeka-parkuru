import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../shared/content_seed.dart';

class DriftSurfaceWindow {
  const DriftSurfaceWindow({
    required this.start,
    required this.end,
    required this.grip,
    required this.kind,
  });

  final double start;
  final double end;
  final double grip;
  final int kind;

  String get signature =>
      '${start.toStringAsFixed(4)}:${end.toStringAsFixed(4)}:'
      '${grip.toStringAsFixed(3)}:$kind';
}

class DriftLeagueScenario {
  const DriftLeagueScenario._({
    required this.level,
    required this.seed,
    required this.centerline,
    required this.surfaces,
    required this.trackWidth,
    required this.checkpointCount,
    required this.checkpointRadius,
    required this.targetDriftScore,
    required this.goldTimeSeconds,
    required this.maximumRecoveries,
    required this.shapePhase,
  });

  static const int campaignLevels = 20;
  static const int practiceRoutes = 300;
  static const int _sampleCount = 96;

  final int level;
  final int seed;
  final List<Offset> centerline;
  final List<DriftSurfaceWindow> surfaces;
  final double trackWidth;
  final int checkpointCount;
  final double checkpointRadius;
  final int targetDriftScore;
  final double goldTimeSeconds;
  final int maximumRecoveries;
  final double shapePhase;

  String get signature => <String>[
    '$level:$seed',
    'width:${trackWidth.toStringAsFixed(4)}',
    'gates:$checkpointCount:${checkpointRadius.toStringAsFixed(4)}',
    'drift:$targetDriftScore:$maximumRecoveries',
    'shape:${shapePhase.toStringAsFixed(6)}',
    centerline
        .map(
          (Offset point) =>
              '${point.dx.toStringAsFixed(4)},${point.dy.toStringAsFixed(4)}',
        )
        .join(';'),
    surfaces.map((DriftSurfaceWindow surface) => surface.signature).join(';'),
  ].join('|');

  static void _checkLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
  }

  static DriftLeagueScenario forLevel(int level) {
    _checkLevel(level);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'drift_league_campaign', level: level),
    );
  }

  static DriftLeagueScenario forPracticeRoute(int index) {
    if (index < 1 || index > practiceRoutes) {
      throw RangeError.range(index, 1, practiceRoutes, 'index');
    }
    final int level = 1 + ((index - 1) % campaignLevels);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'drift_league_practice', level: index),
    );
  }

  static DriftLeagueScenario _build(int level, int seed) {
    _checkLevel(level);
    final math.Random random = math.Random(seed);
    final double phase = random.nextDouble() * math.pi * 2;
    final double rotation = (random.nextDouble() - .5) * .34;
    final double radiusX = .315 + (random.nextDouble() - .5) * .025;
    final double radiusY = .328 + (random.nextDouble() - .5) * .025;
    final double lobe = .025 + random.nextDouble() * .018;
    final List<Offset> centerline = List<Offset>.generate(_sampleCount, (
      int index,
    ) {
      final double angle = math.pi * 2 * index / _sampleCount + rotation;
      final double harmonic =
          1 +
          lobe * math.cos(2 * angle + phase) +
          .018 * math.sin(3 * angle - phase);
      return Offset(
        .5 + radiusX * math.cos(angle) * harmonic,
        .5 + radiusY * math.sin(angle) * harmonic,
      );
    }, growable: false);

    final int surfaceCount = level < 3 ? 0 : math.min(4, 1 + (level - 3) ~/ 5);
    final List<DriftSurfaceWindow> surfaces = <DriftSurfaceWindow>[];
    for (int index = 0; index < surfaceCount; index++) {
      final double start = .08 + random.nextDouble() * .78;
      final double end = math.min(
        .98,
        start + .055 + random.nextDouble() * .095,
      );
      final int kind = 1 + random.nextInt(3);
      surfaces.add(
        DriftSurfaceWindow(
          start: start,
          end: end,
          grip: switch (kind) {
            1 => .64 + random.nextDouble() * .08,
            2 => .43 + random.nextDouble() * .08,
            _ => .77 + random.nextDouble() * .08,
          },
          kind: kind,
        ),
      );
    }

    return DriftLeagueScenario._(
      level: level,
      seed: seed,
      centerline: List<Offset>.unmodifiable(centerline),
      surfaces: List<DriftSurfaceWindow>.unmodifiable(surfaces),
      trackWidth: (.215 - level * .00145).clamp(.184, .214).toDouble(),
      checkpointCount: math.min(8, 4 + (level - 1) ~/ 4),
      checkpointRadius: (.061 - level * .00115).clamp(.038, .060).toDouble(),
      targetDriftScore: 52 + level * 19,
      goldTimeSeconds: 28 - level * .26,
      maximumRecoveries: math.max(1, 5 - (level - 1) ~/ 5),
      shapePhase: phase,
    );
  }

  Offset pointAt(double progress) {
    final double wrapped = progress - progress.floorToDouble();
    final double sample = wrapped * centerline.length;
    final int index = sample.floor() % centerline.length;
    final int next = (index + 1) % centerline.length;
    final double mix = sample - sample.floor();
    return Offset.lerp(centerline[index], centerline[next], mix)!;
  }

  Offset tangentAt(double progress) {
    final Offset before = pointAt(progress - .004);
    final Offset after = pointAt(progress + .004);
    final Offset delta = after - before;
    final double length = math.max(.0001, delta.distance);
    return delta / length;
  }

  double gripAt(double progress) {
    final double wrapped = progress - progress.floorToDouble();
    for (final DriftSurfaceWindow surface in surfaces) {
      if (wrapped >= surface.start && wrapped <= surface.end) {
        return surface.grip;
      }
    }
    return .88 - math.min(.12, level * .0035);
  }

  int surfaceKindAt(double progress) {
    final double wrapped = progress - progress.floorToDouble();
    for (final DriftSurfaceWindow surface in surfaces) {
      if (wrapped >= surface.start && wrapped <= surface.end) {
        return surface.kind;
      }
    }
    return 0;
  }

  DriftTrackProjection project(Offset position) {
    double bestDistanceSquared = double.infinity;
    double bestProgress = 0;
    for (int index = 0; index < centerline.length; index++) {
      final Offset a = centerline[index];
      final Offset b = centerline[(index + 1) % centerline.length];
      final Offset segment = b - a;
      final double lengthSquared =
          segment.dx * segment.dx + segment.dy * segment.dy;
      final Offset relative = position - a;
      final double mix = lengthSquared <= .0000001
          ? 0
          : ((relative.dx * segment.dx + relative.dy * segment.dy) /
                    lengthSquared)
                .clamp(0, 1)
                .toDouble();
      final Offset nearest = a + segment * mix;
      final double distanceSquared = (position - nearest).distanceSquared;
      if (distanceSquared < bestDistanceSquared) {
        bestDistanceSquared = distanceSquared;
        bestProgress = (index + mix) / centerline.length;
      }
    }
    return DriftTrackProjection(
      progress: bestProgress,
      distance: math.sqrt(bestDistanceSquared),
    );
  }
}

class DriftTrackProjection {
  const DriftTrackProjection({required this.progress, required this.distance});

  final double progress;
  final double distance;
}
