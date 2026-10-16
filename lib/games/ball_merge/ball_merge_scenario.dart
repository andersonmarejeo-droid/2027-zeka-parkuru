import 'dart:math' as math;

import '../shared/content_seed.dart';

/// Immutable wave configuration for the physics-driven merge chamber.
///
/// The visible queue is part of the challenge: later levels add higher-value
/// orbs, stronger gravity and more lateral flux while leaving the next move
/// readable to the player.
class BallMergeScenario {
  const BallMergeScenario._({
    required this.level,
    required this.seed,
    required this.dropLimit,
    required this.mergeGoal,
    required this.maxTier,
    required this.gravity,
    required this.flux,
    required this.queue,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, BallMergeScenario> _campaign =
      <int, BallMergeScenario>{};
  static final Map<int, BallMergeScenario> _practice =
      <int, BallMergeScenario>{};

  final int level;
  final int seed;
  final int dropLimit;
  final int mergeGoal;
  final int maxTier;
  final double gravity;
  final double flux;
  final List<int> queue;

  String get signature =>
      '$level|$dropLimit|$mergeGoal|$maxTier|'
      '${gravity.toStringAsFixed(2)}|${flux.toStringAsFixed(2)}|'
      '${queue.join(',')}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static BallMergeScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static BallMergeScenario forPracticeRound(int index) {
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
    ..._campaign.values.map((BallMergeScenario scenario) => scenario.signature),
    ..._practice.values.map((BallMergeScenario scenario) => scenario.signature),
  };

  static BallMergeScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 200; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'ball_merge:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int dropLimit = 18 + level * 2;
      final int mergeGoal = 2 + level;
      final int maxTier = 2 + level ~/ 2;
      final double gravity = 2.45 + level * .235;
      final double flux = level <= 3 ? 0 : (level - 3) * .115;

      // The queue always offers at least two examples of every available
      // opening tier. Remaining values are mixed and then shuffled so the
      // player must read the preview and plan placements rather than repeat
      // one fixed left/right pattern.
      final int openingTierCount = level >= 7
          ? maxTier + 1
          : math.min(3, maxTier + 1);
      final List<int> queue = <int>[];
      for (int tier = 0; tier < openingTierCount; tier++) {
        queue
          ..add(tier)
          ..add(tier);
      }
      while (queue.length < dropLimit) {
        final double roll = random.nextDouble();
        final int tier;
        if (roll < .52) {
          tier = 0;
        } else if (roll < .80) {
          tier = 1;
        } else if (roll < .94) {
          tier = math.min(2, maxTier);
        } else {
          tier = random.nextInt(maxTier + 1);
        }
        queue.add(tier);
      }
      for (int index = queue.length - 1; index > 0; index--) {
        final int swapIndex = random.nextInt(index + 1);
        final int value = queue[index];
        queue[index] = queue[swapIndex];
        queue[swapIndex] = value;
      }
      // Prevent a long, visually repetitive run from undermining the preview.
      for (int index = 2; index < queue.length; index++) {
        if (queue[index] == queue[index - 1] &&
            queue[index] == queue[index - 2]) {
          final int swapIndex =
              (index + 1 + random.nextInt(queue.length - 1)) % queue.length;
          final int value = queue[index];
          queue[index] = queue[swapIndex];
          queue[swapIndex] = value;
        }
      }
      final BallMergeScenario candidate = BallMergeScenario._(
        level: level,
        seed: seed,
        dropLimit: dropLimit,
        mergeGoal: mergeGoal,
        maxTier: maxTier,
        gravity: gravity,
        flux: flux,
        queue: List<int>.unmodifiable(queue),
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Ball Merge sequence.');
  }

  static bool _isFair(BallMergeScenario scenario) {
    if (scenario.queue.length != scenario.dropLimit ||
        scenario.mergeGoal < 3 ||
        scenario.maxTier < 2 ||
        scenario.gravity <= 0 ||
        scenario.flux < 0) {
      return false;
    }
    final int guaranteedTier = scenario.level >= 7
        ? scenario.maxTier
        : math.min(2, scenario.maxTier);
    for (int tier = 0; tier <= guaranteedTier; tier++) {
      if (scenario.queue.where((int value) => value == tier).length < 2) {
        return false;
      }
    }
    return scenario.queue.every(
      (int tier) => tier >= 0 && tier <= scenario.maxTier,
    );
  }
}
