import 'dart:math' as math;

import '../shared/content_seed.dart';

enum TableSurface { tournament, fast, soft, sideWind }

class TableTennisScenario {
  const TableTennisScenario._({
    required this.level,
    required this.seed,
    required this.pointsToWin,
    required this.ballSpeed,
    required this.opponentMoveSpeed,
    required this.opponentErrorChance,
    required this.reactionSeconds,
    required this.serveOffset,
    required this.surface,
    required this.spinSequence,
  });

  static const int campaignLevels = 20;
  static const int practiceRallies = 300;

  final int level;
  final int seed;
  final int pointsToWin;
  final double ballSpeed;
  final double opponentMoveSpeed;
  final double opponentErrorChance;
  final double reactionSeconds;
  final double serveOffset;
  final TableSurface surface;
  final List<int> spinSequence;

  String get signature => <String>[
    '$level:$seed',
    'target:$pointsToWin',
    'speed:${ballSpeed.toStringAsFixed(4)}',
    'move:${opponentMoveSpeed.toStringAsFixed(4)}',
    'error:${opponentErrorChance.toStringAsFixed(4)}',
    'reaction:${reactionSeconds.toStringAsFixed(4)}',
    'serve:${serveOffset.toStringAsFixed(4)}',
    'surface:${surface.name}',
    'spins:${spinSequence.join(',')}',
  ].join('|');

  static TableTennisScenario forLevel(int level) {
    _checkLevel(level);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'table_tennis_campaign', level: level),
    );
  }

  static TableTennisScenario forPracticeRally(int index) {
    if (index < 1 || index > practiceRallies) {
      throw RangeError.range(index, 1, practiceRallies, 'index');
    }
    final int level = 1 + ((index - 1) % campaignLevels);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'table_tennis_practice', level: index),
    );
  }

  static void _checkLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
  }

  static TableTennisScenario _build(int level, int seed) {
    final math.Random random = math.Random(seed);
    final List<int> spinSequence = List<int>.generate(
      8,
      (int index) => (random.nextInt(3) + index + level) % 3,
      growable: false,
    );
    final int surfaceRoll = random.nextInt(4);
    final TableSurface surface = switch (level) {
      <= 3 => TableSurface.tournament,
      _ => TableSurface.values[(surfaceRoll + (level ~/ 4)) % 4],
    };
    return TableTennisScenario._(
      level: level,
      seed: seed,
      pointsToWin: 3 + ((level - 1) ~/ 6),
      ballSpeed: (.48 + level * .013 + random.nextDouble() * .035)
          .clamp(.49, .79)
          .toDouble(),
      opponentMoveSpeed: (.48 + level * .027 + random.nextDouble() * .08)
          .clamp(.54, 1.12)
          .toDouble(),
      opponentErrorChance: (.285 - level * .009 + random.nextDouble() * .025)
          .clamp(.075, .30)
          .toDouble(),
      reactionSeconds: (.61 - level * .019 + random.nextDouble() * .035)
          .clamp(.19, .64)
          .toDouble(),
      serveOffset: (random.nextDouble() - .5) * (.08 + level * .0015),
      surface: surface,
      spinSequence: List<int>.unmodifiable(spinSequence),
    );
  }
}
