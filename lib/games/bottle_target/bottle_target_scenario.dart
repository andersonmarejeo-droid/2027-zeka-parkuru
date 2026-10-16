import 'dart:math' as math;

import '../shared/content_seed.dart';

enum BottleKind { target, neutral }

class BottleSpec {
  const BottleSpec({
    required this.kind,
    required this.x,
    required this.y,
    required this.radius,
    required this.weight,
  });

  final BottleKind kind;
  final double x;
  final double y;
  final double radius;
  final double weight;

  String get signature =>
      '${kind.index}:${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}:'
      '${radius.toStringAsFixed(3)}:${weight.toStringAsFixed(2)}';
}

class RangeObstacleSpec {
  const RangeObstacleSpec({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.reflective,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final bool reflective;

  String get signature =>
      '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}:'
      '${width.toStringAsFixed(3)}:${height.toStringAsFixed(3)}:$reflective';
}

class BottleTargetScenario {
  const BottleTargetScenario._({
    required this.level,
    required this.seed,
    required this.shots,
    required this.gravity,
    required this.wallBanking,
    required this.bottles,
    required this.obstacles,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;

  static final Map<int, BottleTargetScenario> _campaign =
      <int, BottleTargetScenario>{};
  static final Map<int, BottleTargetScenario> _practice =
      <int, BottleTargetScenario>{};

  final int level;
  final int seed;
  final int shots;
  final double gravity;
  final bool wallBanking;
  final List<BottleSpec> bottles;
  final List<RangeObstacleSpec> obstacles;

  int get targetCount => bottles
      .where((BottleSpec bottle) => bottle.kind == BottleKind.target)
      .length;

  String get signature =>
      '$level|$shots|${gravity.toStringAsFixed(3)}|$wallBanking|'
      '${bottles.map((BottleSpec bottle) => bottle.signature).join(';')}|'
      '${obstacles.map((RangeObstacleSpec obstacle) => obstacle.signature).join(';')}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static BottleTargetScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static BottleTargetScenario forPracticeRound(int index) {
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
    ..._campaign.values.map((BottleTargetScenario game) => game.signature),
    ..._practice.values.map((BottleTargetScenario game) => game.signature),
  };

  static BottleTargetScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 200; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'bottle_target:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int targetCount = switch (level) {
        <= 3 => 1,
        <= 6 => 2,
        <= 8 => 3,
        _ => 4,
      };
      final List<double> targetLanes = switch (targetCount) {
        1 => <double>[.50],
        2 => <double>[.36, .64],
        3 => <double>[.28, .50, .72],
        _ => <double>[.24, .41, .59, .76],
      };
      final List<BottleSpec> bottles = <BottleSpec>[
        for (final (int targetIndex, double lane) in targetLanes.indexed)
          BottleSpec(
            kind: BottleKind.target,
            x: lane + (random.nextDouble() - .5) * .035,
            y: level == 10
                ? (targetIndex.isEven ? .525 : .625) +
                      random.nextDouble() * .018
                : .565 + random.nextDouble() * .035,
            radius: level < 7 ? .045 : (.045 - level * .0012),
            weight: .72 + random.nextDouble() * (.08 + level * .035),
          ),
        if (level >= 4) ...<BottleSpec>[
          BottleSpec(
            kind: BottleKind.neutral,
            x: .135 + random.nextDouble() * .025,
            y: .715 + random.nextDouble() * .02,
            radius: .047,
            weight: 1.1,
          ),
          BottleSpec(
            kind: BottleKind.neutral,
            x: .84 + random.nextDouble() * .025,
            y: .69 + random.nextDouble() * .02,
            radius: .043,
            weight: 1.25,
          ),
        ],
      ];
      final int obstacleCount = level < 4
          ? 0
          : level < 7
          ? 1
          : level < 9
          ? 2
          : 3;
      final List<RangeObstacleSpec> obstacles = <RangeObstacleSpec>[
        for (int obstacle = 0; obstacle < obstacleCount; obstacle++)
          RangeObstacleSpec(
            x: obstacle.isEven
                ? .18 + random.nextDouble() * .10
                : .72 + random.nextDouble() * .10,
            y: .405 + obstacle * .035,
            width: .10 + random.nextDouble() * .035,
            height: .025 + random.nextDouble() * .018,
            reflective: level >= 7 && random.nextBool(),
          ),
      ];
      final BottleTargetScenario candidate = BottleTargetScenario._(
        level: level,
        seed: seed,
        shots: targetCount + (level >= 7 ? 1 : 2),
        gravity: 1.55 + level * .07,
        wallBanking: level >= 8,
        bottles: List<BottleSpec>.unmodifiable(bottles),
        obstacles: List<RangeObstacleSpec>.unmodifiable(obstacles),
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate distinct bottle range $level.');
  }

  static bool _isFair(BottleTargetScenario scenario) {
    final int neutralCount = scenario.bottles
        .where((BottleSpec bottle) => bottle.kind == BottleKind.neutral)
        .length;
    return scenario.targetCount > 0 &&
        scenario.shots >= scenario.targetCount &&
        scenario.gravity >= 1.5 &&
        scenario.obstacles.length <= 3 &&
        neutralCount <= 2 &&
        scenario.bottles.every(
          (BottleSpec bottle) =>
              bottle.x > .10 &&
              bottle.x < .90 &&
              bottle.y > .52 &&
              bottle.y < .77,
        );
  }
}
