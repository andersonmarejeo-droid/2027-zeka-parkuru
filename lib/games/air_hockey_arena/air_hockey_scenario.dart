import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../shared/content_seed.dart';

enum AirHockeySurface { polished, grippy, slick, rebound }

class AirHockeyScenario {
  const AirHockeyScenario._({
    required this.level,
    required this.seed,
    required this.goalsToWin,
    required this.puckSpeed,
    required this.paddleSpeed,
    required this.opponentSpeed,
    required this.opponentErrorChance,
    required this.goalWidth,
    required this.friction,
    required this.surface,
    required this.bumpers,
    required this.serveOffsets,
  });

  static const int campaignLevels = 20;
  static const int practiceArenas = 300;

  final int level;
  final int seed;
  final int goalsToWin;
  final double puckSpeed;
  final double paddleSpeed;
  final double opponentSpeed;
  final double opponentErrorChance;
  final double goalWidth;
  final double friction;
  final AirHockeySurface surface;
  final List<Offset> bumpers;
  final List<double> serveOffsets;

  String get signature => <String>[
    '$level:$seed',
    'score:$goalsToWin',
    'speed:${puckSpeed.toStringAsFixed(4)}',
    'paddles:${paddleSpeed.toStringAsFixed(4)}:${opponentSpeed.toStringAsFixed(4)}',
    'error:${opponentErrorChance.toStringAsFixed(4)}',
    'goal:${goalWidth.toStringAsFixed(4)}',
    'friction:${friction.toStringAsFixed(4)}:${surface.name}',
    'bumpers:${bumpers.map((Offset p) => '${p.dx.toStringAsFixed(3)},${p.dy.toStringAsFixed(3)}').join(';')}',
    'serves:${serveOffsets.map((double x) => x.toStringAsFixed(3)).join(',')}',
  ].join('|');

  static AirHockeyScenario forLevel(int level) {
    _checkLevel(level);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'air_hockey_campaign', level: level),
    );
  }

  static AirHockeyScenario forPracticeArena(int index) {
    if (index < 1 || index > practiceArenas) {
      throw RangeError.range(index, 1, practiceArenas, 'index');
    }
    final int level = 1 + ((index - 1) % campaignLevels);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'air_hockey_practice', level: index),
    );
  }

  static void _checkLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
  }

  static AirHockeyScenario _build(int level, int seed) {
    final math.Random random = math.Random(seed);
    final List<Offset> candidates = <Offset>[
      const Offset(.24, .34),
      const Offset(.76, .34),
      const Offset(.24, .66),
      const Offset(.76, .66),
      const Offset(.34, .48),
      const Offset(.66, .52),
      const Offset(.50, .36),
      const Offset(.50, .64),
    ]..shuffle(random);
    final int bumperCount = level < 4
        ? 0
        : level < 9
        ? 1
        : level < 15
        ? 2
        : 3;
    final List<double> serves = List<double>.generate(
      10,
      (int index) =>
          (random.nextDouble() - .5) * (.12 + level * .003) +
          math.sin(index * 1.7 + seed % 11) * .025,
      growable: false,
    );
    final List<AirHockeySurface> surfaces = level < 4
        ? <AirHockeySurface>[AirHockeySurface.polished]
        : AirHockeySurface.values;
    return AirHockeyScenario._(
      level: level,
      seed: seed,
      goalsToWin: 3 + ((level - 1) ~/ 6),
      puckSpeed: (.49 + level * .021 + random.nextDouble() * .045)
          .clamp(.50, .95)
          .toDouble(),
      paddleSpeed: (.82 - level * .004 + random.nextDouble() * .09)
          .clamp(.66, .91)
          .toDouble(),
      opponentSpeed: (.47 + level * .028 + random.nextDouble() * .075)
          .clamp(.50, 1.15)
          .toDouble(),
      opponentErrorChance: (.30 - level * .009 + random.nextDouble() * .02)
          .clamp(.085, .31)
          .toDouble(),
      goalWidth: (.41 - level * .006).clamp(.27, .404).toDouble(),
      friction: .105 + random.nextDouble() * .07 + (level > 14 ? .035 : 0),
      surface: surfaces[random.nextInt(surfaces.length)],
      bumpers: List<Offset>.unmodifiable(candidates.take(bumperCount)),
      serveOffsets: List<double>.unmodifiable(serves),
    );
  }
}
