import 'dart:math' as math;

import '../shared/content_seed.dart';

/// Lane-coded order wave for the confectionery line. Lane 0 is the top belt,
/// lane 1 the centre belt, and lane 2 the lower belt.
class SlideSweetsScenario {
  const SlideSweetsScenario._({
    required this.level,
    required this.seed,
    required this.orders,
    required this.beltSpeed,
    required this.spawnInterval,
    required this.bufferCapacity,
    required this.missLimit,
    required this.goldTimeSeconds,
    required this.surgeEvery,
    this.gateCount = 2,
  });

  static const int maximumLevels = 20;
  static const int maximumPracticeRounds = 300;
  static final Map<int, SlideSweetsScenario> _campaign =
      <int, SlideSweetsScenario>{};
  static final Map<int, SlideSweetsScenario> _practice =
      <int, SlideSweetsScenario>{};

  final int level;
  final int seed;
  final List<int> orders;
  final double beltSpeed;
  final double spawnInterval;
  final int bufferCapacity;
  final int missLimit;
  final double goldTimeSeconds;
  final int surgeEvery;
  final int gateCount;

  int get orderCount => orders.length;

  String get signature =>
      '$level|${orders.join()}|${beltSpeed.toStringAsFixed(4)}|'
      '${spawnInterval.toStringAsFixed(4)}|$bufferCapacity|$missLimit|'
      '$surgeEvery|$gateCount';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static SlideSweetsScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static SlideSweetsScenario forPracticeRound(int index) {
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
      (SlideSweetsScenario scenario) => scenario.signature,
    ),
    ..._practice.values.map(
      (SlideSweetsScenario scenario) => scenario.signature,
    ),
  };

  static SlideSweetsScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    final int gateCount = level <= 10 ? 1 : 2;
    for (int attempt = 0; attempt < 600; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'slide_sweets:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int count = 7 + level;
      final List<int> orders = <int>[];
      for (int index = 0; index < count; index++) {
        int lane = random.nextInt(3);
        if (orders.length >= 2 &&
            orders[orders.length - 1] == lane &&
            orders[orders.length - 2] == lane) {
          lane = (lane + 1 + random.nextInt(2)) % 3;
        }
        orders.add(lane);
      }
      // The first delivery teaches the top, centre and lower exits in a
      // predictable cadence; the rest of the order wave stays seed-driven.
      orders[0] = 0;
      orders[1] = 1;
      orders[2] = 2;
      final double speed = level <= 10
          ? .34 + level * .022
          : .42 + (level - 10) * .025;
      final double interval = level <= 10
          ? math.max(1.30, 2.70 - level * .12)
          : math.max(1.02, 2.10 - (level - 10) * .10);
      final SlideSweetsScenario candidate = SlideSweetsScenario._(
        level: level,
        seed: seed,
        orders: List<int>.unmodifiable(orders),
        beltSpeed: speed,
        spawnInterval: interval,
        bufferCapacity: math.max(1, 4 - ((level - 1) ~/ 4)),
        missLimit: level <= 5
            ? 3
            : level <= 12
            ? 2
            : 1,
        goldTimeSeconds: math.max(22, 50 - level * 1.35),
        surgeEvery: level < 5
            ? 0
            : level < 10
            ? 6
            : level < 15
            ? 5
            : 3,
        gateCount: gateCount,
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Şeker Konveyörü wave.');
  }

  static bool _isFair(SlideSweetsScenario scenario) =>
      scenario.orders.length >= 8 &&
      scenario.orders.every((int lane) => lane >= 0 && lane < 3) &&
      scenario.orders.take(3).toSet().length == 3 &&
      scenario.spawnInterval >= 1 &&
      scenario.beltSpeed >= .35 &&
      scenario.bufferCapacity >= 1 &&
      scenario.missLimit >= 1;
}
