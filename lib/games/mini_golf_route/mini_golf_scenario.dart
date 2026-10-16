import 'dart:math' as math;

import '../shared/content_seed.dart';

class GolfPoint {
  const GolfPoint({required this.x, required this.y});

  final double x;

  /// Vertical position relative to course height.
  final double y;

  String get signature => '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}';
}

class GolfPatch {
  const GolfPatch({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  String get signature =>
      '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}:'
      '${width.toStringAsFixed(3)}:${height.toStringAsFixed(3)}';
}

class GolfBumper {
  const GolfBumper({required this.x, required this.y, required this.radius});

  final double x;
  final double y;
  final double radius;

  String get signature =>
      '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}:'
      '${radius.toStringAsFixed(3)}';
}

class MiniGolfScenario {
  const MiniGolfScenario._({
    required this.level,
    required this.seed,
    required this.start,
    required this.hole,
    required this.par,
    required this.strokeLimit,
    required this.gateY,
    required this.gateWidth,
    required this.gateAmplitude,
    required this.gateFrequency,
    required this.gatePhase,
    required this.windX,
    required this.windY,
    required this.grassDrag,
    required this.sandDrag,
    required this.sand,
    required this.bumpers,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, MiniGolfScenario> _campaign = <int, MiniGolfScenario>{};
  static final Map<int, MiniGolfScenario> _practice = <int, MiniGolfScenario>{};

  final int level;
  final int seed;
  final GolfPoint start;
  final GolfPoint hole;
  final int par;
  final int strokeLimit;
  final double gateY;
  final double gateWidth;
  final double gateAmplitude;
  final double gateFrequency;
  final double gatePhase;
  final double windX;
  final double windY;
  final double grassDrag;
  final double sandDrag;
  final List<GolfPatch> sand;
  final List<GolfBumper> bumpers;

  double gateCenterAt(double elapsedSeconds) =>
      .5 + gateAmplitude * math.sin(elapsedSeconds * gateFrequency + gatePhase);

  String get signature =>
      '$level|${start.signature}|${hole.signature}|$par|$strokeLimit|'
      '${gateY.toStringAsFixed(3)}:${gateWidth.toStringAsFixed(3)}:'
      '${gateAmplitude.toStringAsFixed(3)}:${gateFrequency.toStringAsFixed(3)}:'
      '${gatePhase.toStringAsFixed(3)}|${windX.toStringAsFixed(3)}:'
      '${windY.toStringAsFixed(3)}|${sand.map((GolfPatch p) => p.signature).join(';')}|'
      '${bumpers.map((GolfBumper p) => p.signature).join(';')}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static MiniGolfScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static MiniGolfScenario forPracticeRound(int index) {
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
    ..._campaign.values.map((MiniGolfScenario scenario) => scenario.signature),
    ..._practice.values.map((MiniGolfScenario scenario) => scenario.signature),
  };

  static MiniGolfScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'mini_golf_route:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int par = level <= 3
          ? 3
          : level <= 6
          ? 4
          : level <= 8
          ? 4
          : 3;
      final int strokeLimit = par + (level >= 9 ? 2 : 3);
      final GolfPoint start = const GolfPoint(x: .5, y: .86);
      final GolfPoint hole = GolfPoint(
        x: (.5 + (random.nextDouble() - .5) * (.10 + level * .018))
            .clamp(.38, .62)
            .toDouble(),
        y: .14,
      );
      final double gateY = .53 + (random.nextDouble() - .5) * .08;
      final double gateWidth = (.34 - level * .014).clamp(.18, .32).toDouble();
      final double gateAmplitude = level <= 3 ? 0 : .012 + (level - 3) * .017;
      final double gateFrequency = .58 + level * .065;
      final double gatePhase = random.nextDouble() * math.pi * 2;
      final double windMagnitude = level <= 3 ? 0 : (level - 3) * .012;
      final double windAngle = random.nextDouble() * math.pi * 2;
      final double windX = math.cos(windAngle) * windMagnitude;
      final double windY = math.sin(windAngle) * windMagnitude;
      final double grassDrag = .48 + level * .028;
      final double sandDrag = 1.2 + level * .045;

      final List<GolfPatch> sand = <GolfPatch>[];
      final int sandCount = math.max(0, level - 2);
      for (int index = 0; index < sandCount; index++) {
        bool added = false;
        for (int attempt = 0; attempt < 80 && !added; attempt++) {
          final double x = .17 + random.nextDouble() * .66;
          final double y = .24 + random.nextDouble() * .55;
          final double width = .10 + random.nextDouble() * .13;
          final double height = .065 + random.nextDouble() * .075;
          bool awayFromCup(GolfPoint point) {
            final double dx = (x - point.x) / width;
            final double dy = (y - point.y) / height;
            return dx * dx + dy * dy > 1.45;
          }

          if (awayFromCup(start) &&
              awayFromCup(hole) &&
              sand.every(
                (GolfPatch other) =>
                    ((x - other.x) / (width + other.width)).abs() > .45 ||
                    ((y - other.y) / (height + other.height)).abs() > .45,
              )) {
            sand.add(GolfPatch(x: x, y: y, width: width, height: height));
            added = true;
          }
        }
      }

      final List<GolfBumper> bumpers = <GolfBumper>[];
      final int bumperCount = math.max(0, level - 4);
      for (int index = 0; index < bumperCount; index++) {
        for (int attempt = 0; attempt < 80; attempt++) {
          final double x = .18 + random.nextDouble() * .64;
          final double y = .26 + random.nextDouble() * .54;
          final double radius = .022 + random.nextDouble() * .018;
          final bool clearsAnchor = <GolfPoint>[start, hole].every((
            GolfPoint point,
          ) {
            final double dx = x - point.x;
            final double dy = y - point.y;
            return dx * dx + dy * dy > math.pow(radius + .07, 2);
          });
          if (clearsAnchor &&
              bumpers.every((GolfBumper other) {
                final double dx = x - other.x;
                final double dy = y - other.y;
                return dx * dx + dy * dy >
                    math.pow(radius + other.radius + .05, 2);
              })) {
            bumpers.add(GolfBumper(x: x, y: y, radius: radius));
            break;
          }
        }
      }

      final MiniGolfScenario candidate = MiniGolfScenario._(
        level: level,
        seed: seed,
        start: start,
        hole: hole,
        par: par,
        strokeLimit: strokeLimit,
        gateY: gateY,
        gateWidth: gateWidth,
        gateAmplitude: gateAmplitude,
        gateFrequency: gateFrequency,
        gatePhase: gatePhase,
        windX: windX,
        windY: windY,
        grassDrag: grassDrag,
        sandDrag: sandDrag,
        sand: List<GolfPatch>.unmodifiable(sand),
        bumpers: List<GolfBumper>.unmodifiable(bumpers),
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Mini Golf course.');
  }

  static bool _isFair(MiniGolfScenario scenario) =>
      scenario.par >= 3 &&
      scenario.strokeLimit >= scenario.par + 2 &&
      scenario.hole.x >= .38 &&
      scenario.hole.x <= .62 &&
      scenario.gateWidth >= .18 &&
      scenario.gateAmplitude < .16 &&
      scenario.grassDrag < scenario.sandDrag;
}
