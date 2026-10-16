import 'dart:math' as math;

import '../shared/content_seed.dart';

enum BalloonObjectKind { target, decoy, storm, star }

class BalloonSpawnSpec {
  const BalloonSpawnSpec({
    required this.kind,
    required this.lane,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.colorOffset,
  });

  final BalloonObjectKind kind;
  final int lane;
  final double speed;
  final double sway;
  final double phase;
  final int colorOffset;

  String get signature =>
      '${kind.index}:$lane:${speed.toStringAsFixed(3)}:'
      '${sway.toStringAsFixed(3)}:${phase.toStringAsFixed(3)}:$colorOffset';
}

class BalloonScenario {
  const BalloonScenario._({
    required this.level,
    required this.seed,
    required this.requiredCatches,
    required this.lives,
    required this.seconds,
    required this.basketWidth,
    required this.spawnInterval,
    required this.switchEvery,
    required this.targetColors,
    required this.windStrength,
    required this.spawns,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;

  static final Map<int, BalloonScenario> _campaign = <int, BalloonScenario>{};
  static final Map<int, BalloonScenario> _practice = <int, BalloonScenario>{};

  final int level;
  final int seed;
  final int requiredCatches;
  final int lives;
  final int seconds;
  final double basketWidth;
  final double spawnInterval;
  final int switchEvery;
  final List<int> targetColors;
  final double windStrength;
  final List<BalloonSpawnSpec> spawns;

  String get signature =>
      '$level|$requiredCatches|$seconds|${targetColors.join('.')}'
      '|${spawns.map((BalloonSpawnSpec spawn) => spawn.signature).join(';')}';

  static int _stage(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return level;
  }

  static BalloonScenario forLevel(int level) {
    _stage(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static BalloonScenario forPracticeRound(int index) {
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
    ..._campaign.values.map((BalloonScenario scenario) => scenario.signature),
    ..._practice.values.map((BalloonScenario scenario) => scenario.signature),
  };

  static BalloonScenario _build(int level, {required int replayIndex}) {
    final int stage = _stage(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 200; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'balloon_pop:$replayIndex',
        level: stage,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int goal = 5 + (stage - 1) ~/ 2;
      final int colorCount = switch (stage) {
        <= 2 => 1,
        <= 4 => 2,
        <= 7 => 3,
        _ => 4,
      };
      final List<int> colors = List<int>.generate(colorCount, (int i) => i);
      final int totalSpawns = goal + 7 + stage ~/ 2;
      final List<BalloonSpawnSpec> spawns = <BalloonSpawnSpec>[];
      for (int spawn = 0; spawn < totalSpawns; spawn++) {
        final BalloonObjectKind kind;
        if (spawn < goal + 4) {
          kind = BalloonObjectKind.target;
        } else {
          final double roll = random.nextDouble();
          final double stormChance = .08 + stage * .006;
          kind = roll < stormChance
              ? BalloonObjectKind.storm
              : roll < stormChance + .13
              ? BalloonObjectKind.star
              : BalloonObjectKind.decoy;
        }
        spawns.add(
          BalloonSpawnSpec(
            kind: kind,
            lane: spawn == 0 ? 3 : random.nextInt(7),
            speed: .20 + stage * .006 + random.nextDouble() * .055,
            sway: .012 + random.nextDouble() * (.018 + stage * .002),
            phase: random.nextDouble() * math.pi * 2,
            colorOffset: 1 + random.nextInt(3),
          ),
        );
      }
      final BalloonScenario candidate = BalloonScenario._(
        level: stage,
        seed: seed,
        requiredCatches: goal,
        lives: 3,
        seconds: 25 + stage * 2,
        basketWidth: (.29 - stage * .0045).clamp(.19, .29).toDouble(),
        spawnInterval: (.93 - stage * .012).clamp(.59, .93).toDouble(),
        switchEvery: stage <= 3
            ? goal + 4
            : stage <= 8
            ? 4
            : 3,
        targetColors: List<int>.unmodifiable(colors),
        windStrength: .008 + stage * .0025,
        spawns: List<BalloonSpawnSpec>.unmodifiable(spawns),
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError(
      'Could not generate distinct Balloon Catcher level $level.',
    );
  }

  static bool _isFair(BalloonScenario scenario) {
    final int targets = scenario.spawns
        .where(
          (BalloonSpawnSpec spawn) => spawn.kind == BalloonObjectKind.target,
        )
        .length;
    return targets >= scenario.requiredCatches + 3 &&
        scenario.seconds >= 18 &&
        scenario.basketWidth >= .19 &&
        scenario.targetColors.isNotEmpty &&
        scenario.spawns.first.lane == 3;
  }
}
