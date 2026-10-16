import 'dart:math' as math;

import '../shared/content_seed.dart';

class FishPlan {
  const FishPlan({
    required this.species,
    required this.preferredBait,
    required this.preferredDepth,
    required this.strength,
    required this.stamina,
    required this.pullFrequency,
    required this.phase,
    required this.finSpeed,
  });

  final int species;
  final int preferredBait;
  final int preferredDepth;
  final double strength;
  final double stamina;
  final double pullFrequency;
  final double phase;
  final double finSpeed;

  String get signature =>
      '$species:$preferredBait:$preferredDepth:'
      '${strength.toStringAsFixed(3)}:${stamina.toStringAsFixed(3)}:'
      '${pullFrequency.toStringAsFixed(3)}:${phase.toStringAsFixed(3)}:'
      '${finSpeed.toStringAsFixed(3)}';
}

class FishingCurrent {
  const FishingCurrent({required this.x, required this.y});

  final double x;
  final double y;

  String get signature => '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}';
}

class LittleFisherScenario {
  const LittleFisherScenario._({
    required this.level,
    required this.seed,
    required this.fish,
    required this.currentX,
    required this.currentY,
    required this.currentGust,
    required this.currentFrequency,
    required this.currentPhase,
    required this.missLimit,
    required this.goldTimeSeconds,
    required this.maxLineSeconds,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, LittleFisherScenario> _campaign =
      <int, LittleFisherScenario>{};
  static final Map<int, LittleFisherScenario> _practice =
      <int, LittleFisherScenario>{};

  final int level;
  final int seed;
  final List<FishPlan> fish;
  final double currentX;
  final double currentY;
  final double currentGust;
  final double currentFrequency;
  final double currentPhase;
  final int missLimit;
  final double goldTimeSeconds;
  final double maxLineSeconds;

  int get fishCount => fish.length;

  FishingCurrent currentAt(double elapsedSeconds, int depth) {
    final double depthFactor = switch (depth) {
      0 => .55,
      2 => 1.14,
      _ => .82,
    };
    final double wave = math.sin(
      elapsedSeconds * currentFrequency + currentPhase,
    );
    final double cross = math.cos(
      elapsedSeconds * currentFrequency * .73 + currentPhase,
    );
    return FishingCurrent(
      x: (currentX + currentGust * wave) * depthFactor,
      y: (currentY + currentGust * .35 * cross) * depthFactor,
    );
  }

  String get signature =>
      '$level|${fish.map((FishPlan plan) => plan.signature).join(';')}|'
      '${currentX.toStringAsFixed(3)}:${currentY.toStringAsFixed(3)}:'
      '${currentGust.toStringAsFixed(3)}:${currentFrequency.toStringAsFixed(3)}:'
      '${currentPhase.toStringAsFixed(3)}:$missLimit:$maxLineSeconds';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static LittleFisherScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static LittleFisherScenario forPracticeRound(int index) {
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
      (LittleFisherScenario scenario) => scenario.signature,
    ),
    ..._practice.values.map(
      (LittleFisherScenario scenario) => scenario.signature,
    ),
  };

  static LittleFisherScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'little_fisher:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int count = 4 + level;
      final List<FishPlan> fish = List<FishPlan>.generate(count, (int index) {
        return FishPlan(
          species: random.nextInt(4),
          preferredBait: random.nextInt(3),
          preferredDepth: random.nextInt(3),
          strength: .20 + level * .052 + random.nextDouble() * .13,
          stamina: 2.4 + level * .48 + random.nextDouble() * .9,
          pullFrequency: .56 + level * .085 + random.nextDouble() * .25,
          phase: random.nextDouble() * math.pi * 2,
          finSpeed: .34 + random.nextDouble() * .32,
        );
      }, growable: false);
      // Stable first catch gives the player one readable bait/depth lesson;
      // later schools stay seed-driven and use all four fish silhouettes.
      fish[0] = FishPlan(
        species: fish[0].species,
        preferredBait: 0,
        preferredDepth: 1,
        strength: fish[0].strength,
        stamina: fish[0].stamina,
        pullFrequency: fish[0].pullFrequency,
        phase: fish[0].phase,
        finSpeed: fish[0].finSpeed,
      );
      final double magnitude = level <= 2 ? 0 : (level - 2) * .010;
      final double angle = random.nextDouble() * math.pi * 2;
      final LittleFisherScenario candidate = LittleFisherScenario._(
        level: level,
        seed: seed,
        fish: List<FishPlan>.unmodifiable(fish),
        currentX: math.cos(angle) * magnitude,
        currentY: math.sin(angle) * magnitude * .58,
        currentGust: level <= 3 ? 0 : .005 + level * .0025,
        currentFrequency: .5 + level * .075,
        currentPhase: random.nextDouble() * math.pi * 2,
        missLimit: level <= 3
            ? 4
            : level <= 6
            ? 3
            : level <= 8
            ? 2
            : 1,
        goldTimeSeconds: math.max(32, 82 - level * 4.4),
        maxLineSeconds: math.max(10, 24 - level * .72),
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Küçük Balıkçı school.');
  }

  static bool _isFair(LittleFisherScenario scenario) =>
      scenario.fish.length >= 5 &&
      scenario.fish.every(
        (FishPlan fish) =>
            fish.species >= 0 &&
            fish.species < 4 &&
            fish.preferredBait >= 0 &&
            fish.preferredBait < 3 &&
            fish.preferredDepth >= 0 &&
            fish.preferredDepth < 3 &&
            fish.strength >= .25 &&
            fish.stamina >= 2.8,
      ) &&
      scenario.fish.first.preferredBait == 0 &&
      scenario.fish.first.preferredDepth == 1 &&
      scenario.maxLineSeconds >= 10;
}
