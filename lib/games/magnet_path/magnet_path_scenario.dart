import 'dart:math' as math;

import '../shared/content_seed.dart';

class MagnetPoint {
  const MagnetPoint({required this.x, required this.y});

  final double x;
  /// Vertical position relative to the board height.
  final double y;

  String get signature => '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}';
}

class MagnetBaffle {
  const MagnetBaffle({required this.x, required this.y, required this.radius});

  final double x;
  final double y;
  final double radius;

  String get signature =>
      '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}:'
      '${radius.toStringAsFixed(3)}';
}

class MagnetPathScenario {
  const MagnetPathScenario._({
    required this.level,
    required this.seed,
    required this.start,
    required this.gates,
    required this.baffles,
    required this.gateRadius,
    required this.fieldStrength,
    required this.speedLimit,
    required this.coast,
    required this.collisionLimit,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, MagnetPathScenario> _campaign =
      <int, MagnetPathScenario>{};
  static final Map<int, MagnetPathScenario> _practice =
      <int, MagnetPathScenario>{};

  final int level;
  final int seed;
  final MagnetPoint start;
  final List<MagnetPoint> gates;
  final List<MagnetBaffle> baffles;
  final double gateRadius;
  final double fieldStrength;
  final double speedLimit;
  final double coast;
  final int collisionLimit;

  String get signature =>
      '$level|${start.signature}|${gateRadius.toStringAsFixed(3)}|'
      '${fieldStrength.toStringAsFixed(3)}|${speedLimit.toStringAsFixed(3)}|'
      '${coast.toStringAsFixed(3)}|${gates.map((MagnetPoint p) => p.signature).join(';')}|'
      '${baffles.map((MagnetBaffle b) => b.signature).join(';')}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static MagnetPathScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static MagnetPathScenario forPracticeRound(int index) {
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
    ..._campaign.values.map((MagnetPathScenario scenario) => scenario.signature),
    ..._practice.values.map((MagnetPathScenario scenario) => scenario.signature),
  };

  static MagnetPathScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'magnet_path:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int gateCount = 1 + level ~/ 2;
      final double gateRadius = .094 - level * .0038;
      final double fieldStrength = .235 - level * .0105;
      final double speedLimit = .34 + level * .018;
      final double coast = .22 + level * .032;
      final MagnetPoint start = MagnetPoint(x: .15, y: .84);
      final List<MagnetPoint> gates = <MagnetPoint>[];
      for (int index = 0; index < gateCount; index++) {
        final double progress = (index + 1) / (gateCount + 1);
        final double baseX = index.isEven ? .72 : .28;
        gates.add(
          MagnetPoint(
            x: (baseX + (random.nextDouble() - .5) * .18).clamp(.22, .78).toDouble(),
            y: .84 - progress * .64,
          ),
        );
      }
      gates.add(MagnetPoint(x: .84, y: .12));

      final List<MagnetBaffle> baffles = <MagnetBaffle>[];
      final int baffleCount = math.max(0, level - 2);
      for (int index = 0; index < baffleCount; index++) {
        bool placed = false;
        for (int attempt = 0; attempt < 80 && !placed; attempt++) {
          final double x = .19 + random.nextDouble() * .62;
          final double y = .17 + random.nextDouble() * .66;
          final double radius = .025 + random.nextDouble() * .018;
          final bool clearsRoute = <MagnetPoint>[start, ...gates].every(
            (MagnetPoint point) {
              final double dx = point.x - x;
              final double dy = point.y - y;
              return dx * dx + dy * dy >
                  math.pow(radius + gateRadius * 1.45, 2);
            },
          );
          if (clearsRoute && baffles.every((MagnetBaffle other) {
            final double dx = other.x - x;
            final double dy = other.y - y;
            return dx * dx + dy * dy > math.pow(other.radius + radius + .055, 2);
          })) {
            baffles.add(MagnetBaffle(x: x, y: y, radius: radius));
            placed = true;
          }
        }
      }
      final MagnetPathScenario candidate = MagnetPathScenario._(
        level: level,
        seed: seed,
        start: start,
        gates: List<MagnetPoint>.unmodifiable(gates),
        baffles: List<MagnetBaffle>.unmodifiable(baffles),
        gateRadius: gateRadius,
        fieldStrength: fieldStrength,
        speedLimit: speedLimit,
        coast: coast,
        collisionLimit: level >= 9 ? 3 : 4,
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Magnet Path course.');
  }

  static bool _isFair(MagnetPathScenario scenario) {
    if (scenario.gates.length < 2 ||
        scenario.gateRadius < .05 ||
        scenario.fieldStrength <= .1 ||
        scenario.speedLimit < .35 ||
        scenario.collisionLimit < 3) {
      return false;
    }
    final List<MagnetPoint> route = <MagnetPoint>[scenario.start, ...scenario.gates];
    for (int index = 1; index < route.length; index++) {
      if (route[index].x < .12 || route[index].x > .88 ||
          route[index].y < .08 || route[index].y > .92) {
        return false;
      }
    }
    for (final MagnetBaffle baffle in scenario.baffles) {
      for (final MagnetPoint gate in route) {
        final double dx = gate.x - baffle.x;
        final double dy = gate.y - baffle.y;
        if (dx * dx + dy * dy < math.pow(baffle.radius + scenario.gateRadius, 2)) {
          return false;
        }
      }
    }
    return true;
  }
}
