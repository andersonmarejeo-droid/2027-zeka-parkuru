import 'dart:math' as math;

import '../shared/content_seed.dart';

class TowerPieceSpec {
  const TowerPieceSpec({
    required this.width,
    required this.height,
    required this.mass,
    required this.massBias,
    required this.material,
  });

  final double width;
  final double height;
  final double mass;

  /// Offset of the piece's center of mass as a fraction of its width.
  final double massBias;

  /// 0 timber, 1 ceramic, 2 stone, 3 brass.
  final int material;

  String get signature =>
      '${width.toStringAsFixed(3)}:${height.toStringAsFixed(3)}:'
      '${mass.toStringAsFixed(2)}:${massBias.toStringAsFixed(3)}:$material';
}

class TowerBalanceScenario {
  const TowerBalanceScenario._({
    required this.level,
    required this.seed,
    required this.placementCount,
    required this.tiltAmplitude,
    required this.windStrength,
    required this.windFrequency,
    required this.phaseOffset,
    required this.balanceMargin,
    required this.minimumOverlap,
    required this.mistakeLimit,
    required this.supportPins,
    required this.pieces,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, TowerBalanceScenario> _campaign =
      <int, TowerBalanceScenario>{};
  static final Map<int, TowerBalanceScenario> _practice =
      <int, TowerBalanceScenario>{};

  final int level;
  final int seed;
  final int placementCount;
  final double tiltAmplitude;
  final double windStrength;
  final double windFrequency;
  final double phaseOffset;
  final double balanceMargin;
  final double minimumOverlap;
  final int mistakeLimit;
  final int supportPins;
  final List<TowerPieceSpec> pieces;

  String get signature =>
      '$level|$placementCount|${tiltAmplitude.toStringAsFixed(3)}|'
      '${windStrength.toStringAsFixed(3)}|${windFrequency.toStringAsFixed(3)}|'
      '${phaseOffset.toStringAsFixed(3)}|$balanceMargin|$minimumOverlap|'
      '${pieces.map((TowerPieceSpec piece) => piece.signature).join(';')}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static TowerBalanceScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static TowerBalanceScenario forPracticeRound(int index) {
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
    ..._campaign.values.map(
      (TowerBalanceScenario scenario) => scenario.signature,
    ),
    ..._practice.values.map(
      (TowerBalanceScenario scenario) => scenario.signature,
    ),
  };

  static TowerBalanceScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 250; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'tower_balance:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int placementCount = 5 + level;
      final double tiltAmplitude = .014 + level * .0096;
      final double windStrength = level <= 3 ? .04 : (level - 2) * .067;
      final double windFrequency = .72 + level * .038;
      final double phaseOffset = random.nextDouble() * math.pi * 2;
      final double balanceMargin = .23 - level * .009;
      final double minimumOverlap = .42 + level * .025;
      final int mistakeLimit = level >= 9 ? 2 : 3;
      final int supportPins = level == 10 ? 1 : 0;
      final List<TowerPieceSpec> pieces = List<TowerPieceSpec>.generate(
        placementCount,
        (int index) {
          final double width =
              (.22 + random.nextDouble() * .12 - (level * .002))
                  .clamp(.14, .36)
                  .toDouble();
          final double height = .072 + random.nextDouble() * .048;
          final double massBase = switch (random.nextInt(4)) {
            0 => .68 + random.nextDouble() * .38,
            1 => 1.05 + random.nextDouble() * .55,
            2 => 1.65 + random.nextDouble() * .65,
            _ => 2.1 + random.nextDouble() * .62,
          };
          final int material = random.nextInt(4);
          final double materialDensity = switch (material) {
            0 => .82,
            1 => 1.12,
            2 => 1.42,
            _ => 1.68,
          };
          return TowerPieceSpec(
            width: width,
            height: height,
            mass: massBase * materialDensity,
            massBias: (random.nextDouble() - .5) * (level >= 5 ? .34 : .24),
            material: material,
          );
        },
        growable: false,
      );
      final TowerBalanceScenario candidate = TowerBalanceScenario._(
        level: level,
        seed: seed,
        placementCount: placementCount,
        tiltAmplitude: tiltAmplitude,
        windStrength: windStrength,
        windFrequency: windFrequency,
        phaseOffset: phaseOffset,
        balanceMargin: balanceMargin,
        minimumOverlap: minimumOverlap,
        mistakeLimit: mistakeLimit,
        supportPins: supportPins,
        pieces: pieces,
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Tower Balance layout.');
  }

  static bool _isFair(TowerBalanceScenario scenario) {
    if (scenario.pieces.length != scenario.placementCount ||
        scenario.placementCount < 6 ||
        scenario.balanceMargin <= .1 ||
        scenario.minimumOverlap >= .75 ||
        scenario.mistakeLimit < 2) {
      return false;
    }
    return scenario.pieces.every(
      (TowerPieceSpec piece) =>
          piece.width >= .14 &&
          piece.width <= .36 &&
          piece.height > .06 &&
          piece.mass > .5 &&
          piece.massBias.abs() <= .18 &&
          piece.material >= 0 &&
          piece.material <= 3,
    );
  }
}
