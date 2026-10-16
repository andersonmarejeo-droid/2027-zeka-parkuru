import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../shared/content_seed.dart';

enum LighthouseEnemyKind { runner, armored, glider, brute, boss }

enum LighthouseTowerType { ballista, frost, mortar }

enum LighthouseTargetRule { first, last, strongest }

class LighthouseEnemySpec {
  const LighthouseEnemySpec({
    required this.kind,
    required this.health,
    required this.speed,
    required this.reward,
    required this.armor,
    required this.routeBranch,
  });

  final LighthouseEnemyKind kind;
  final int health;
  final double speed;
  final int reward;
  final int armor;
  final int routeBranch;

  String get signature =>
      '${kind.name}:$health:${speed.toStringAsFixed(4)}:$reward:$armor:$routeBranch';
}

class LighthouseWaveSpec {
  const LighthouseWaveSpec({
    required this.index,
    required this.interval,
    required this.enemies,
  });

  final int index;
  final double interval;
  final List<LighthouseEnemySpec> enemies;

  String get signature =>
      '$index:${interval.toStringAsFixed(3)}:${enemies.map((LighthouseEnemySpec enemy) => enemy.signature).join(';')}';
}

class LighthouseScenario {
  const LighthouseScenario._({
    required this.level,
    required this.seed,
    required this.path,
    required this.alternatePath,
    required this.pads,
    required this.waves,
    required this.startingCoins,
    required this.startingLives,
    required this.pulseCharges,
  });

  static const int campaignLevels = 20;
  static const int practiceMaps = 300;

  final int level;
  final int seed;
  final List<Offset> path;
  final List<Offset> alternatePath;
  final List<Offset> pads;
  final List<LighthouseWaveSpec> waves;
  final int startingCoins;
  final int startingLives;
  final int pulseCharges;

  String get signature => <String>[
    '$level:$seed:$startingCoins:$startingLives:$pulseCharges',
    'p:${path.map(_point).join(';')}',
    'q:${alternatePath.map(_point).join(';')}',
    'b:${pads.map(_point).join(';')}',
    waves.map((LighthouseWaveSpec wave) => wave.signature).join('|'),
  ].join('::');

  static LighthouseScenario forLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
    return _create(
      level,
      ContentSeed.forLevel(gameId: 'lighthouse_defense_campaign', level: level),
    );
  }

  static LighthouseScenario forPracticeMap(int index) {
    if (index < 1 || index > practiceMaps) {
      throw RangeError.range(index, 1, practiceMaps, 'index');
    }
    return _create(
      1 + ((index - 1) % campaignLevels),
      ContentSeed.forLevel(gameId: 'lighthouse_defense_practice', level: index),
    );
  }

  static LighthouseScenario _create(int level, int seed) {
    final math.Random random = math.Random(seed);
    final double highLane = .25 + random.nextDouble() * .075;
    final double lowLane = .675 + random.nextDouble() * .075;
    final double bend = (random.nextDouble() - .5) * .09;
    final bool flip = random.nextBool();
    final double first = flip ? lowLane : highLane;
    final double second = flip ? highLane : lowLane;
    final List<Offset> path = _route(first, bend);
    final List<Offset> alternatePath = _route(second, -bend);
    const List<Offset> pads = <Offset>[
      Offset(.095, .27),
      Offset(.30, .11),
      Offset(.30, .90),
      Offset(.52, .11),
      Offset(.52, .90),
      Offset(.84, .27),
    ];
    final int waveCount = 4 + level ~/ 5;
    final List<LighthouseWaveSpec> waves = <LighthouseWaveSpec>[
      for (int wave = 0; wave < waveCount; wave++)
        _buildWave(level: level, index: wave, random: random),
    ];
    return LighthouseScenario._(
      level: level,
      seed: seed,
      path: List<Offset>.unmodifiable(path),
      alternatePath: List<Offset>.unmodifiable(alternatePath),
      pads: pads,
      waves: List<LighthouseWaveSpec>.unmodifiable(waves),
      startingCoins: 230 + level * 15,
      startingLives: (14 - level ~/ 4).clamp(8, 14),
      pulseCharges: level < 7
          ? 2
          : level < 15
          ? 2
          : 1,
    );
  }

  static LighthouseWaveSpec _buildWave({
    required int level,
    required int index,
    required math.Random random,
  }) {
    final bool finalWave = index == 3 + level ~/ 5;
    final bool bossWave = finalWave && level >= 8;
    final int count = (4 + index + level ~/ 4 + (bossWave ? 1 : 0)).clamp(
      4,
      15,
    );
    final List<LighthouseEnemySpec> enemies = <LighthouseEnemySpec>[];
    for (int enemy = 0; enemy < count; enemy++) {
      final bool boss = bossWave && enemy == count - 1;
      final LighthouseEnemyKind kind = boss
          ? LighthouseEnemyKind.boss
          : _enemyKind(level: level, index: enemy, random: random);
      final (int health, double speed, int reward, int armor) stats =
          switch (kind) {
            LighthouseEnemyKind.runner => (
              2 + level ~/ 8,
              .055 + level * .0016 + index * .001,
              15,
              0,
            ),
            LighthouseEnemyKind.armored => (
              5 + level ~/ 3,
              .034 + level * .001,
              22,
              1 + level ~/ 12,
            ),
            LighthouseEnemyKind.glider => (
              3 + level ~/ 5,
              .050 + level * .0015,
              19,
              0,
            ),
            LighthouseEnemyKind.brute => (
              8 + level ~/ 2,
              .027 + level * .001,
              28,
              1 + level ~/ 10,
            ),
            LighthouseEnemyKind.boss => (
              24 + level * 3,
              .021 + level * .0006,
              100,
              2 + level ~/ 8,
            ),
          };
      enemies.add(
        LighthouseEnemySpec(
          kind: kind,
          health: stats.$1,
          speed: stats.$2,
          reward: stats.$3,
          armor: stats.$4,
          routeBranch: (enemy + random.nextInt(2)) % 2,
        ),
      );
    }
    return LighthouseWaveSpec(
      index: index,
      interval: (.90 - level * .018 - index * .025).clamp(.34, .86).toDouble(),
      enemies: List<LighthouseEnemySpec>.unmodifiable(enemies),
    );
  }

  static LighthouseEnemyKind _enemyKind({
    required int level,
    required int index,
    required math.Random random,
  }) {
    if (level < 3) return LighthouseEnemyKind.runner;
    final List<LighthouseEnemyKind> pool = <LighthouseEnemyKind>[
      LighthouseEnemyKind.runner,
      LighthouseEnemyKind.armored,
      if (level >= 6) LighthouseEnemyKind.glider,
      if (level >= 10) LighthouseEnemyKind.brute,
    ];
    final int offset = (index + random.nextInt(pool.length)) % pool.length;
    return pool[offset];
  }

  static List<Offset> _route(double lane, double bend) => <Offset>[
    const Offset(.035, .51),
    Offset(.18, .51 + bend * .2),
    Offset(.18, lane),
    Offset(.39, lane),
    Offset(.47, lane + bend),
    Offset(.66, lane),
    Offset(.66, .51 - bend * .2),
    const Offset(.91, .51),
  ];

  static String _point(Offset point) =>
      '${point.dx.toStringAsFixed(3)},${point.dy.toStringAsFixed(3)}';
}
