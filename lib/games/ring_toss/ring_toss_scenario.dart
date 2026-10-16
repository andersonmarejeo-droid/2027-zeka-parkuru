import 'dart:math' as math;

import '../shared/content_seed.dart';

class RingPoint {
  const RingPoint(this.x, this.y);

  final double x;
  final double y;

  String get signature => '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}';
}

class RingTarget {
  const RingTarget({
    required this.x,
    required this.y,
    required this.motionX,
    required this.motionY,
    required this.frequency,
    required this.phase,
    required this.radius,
    required this.captureSpeed,
  });

  final double x;
  final double y;
  final double motionX;
  final double motionY;
  final double frequency;
  final double phase;
  final double radius;
  final double captureSpeed;

  RingPoint at(double elapsedSeconds) => RingPoint(
    (x + motionX * math.sin(elapsedSeconds * frequency + phase))
        .clamp(.12, .88)
        .toDouble(),
    (y + motionY * math.cos(elapsedSeconds * frequency * .83 + phase))
        .clamp(.15, .72)
        .toDouble(),
  );

  String get signature =>
      '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}:'
      '${motionX.toStringAsFixed(3)}:${motionY.toStringAsFixed(3)}:'
      '${frequency.toStringAsFixed(3)}:${phase.toStringAsFixed(3)}:'
      '${radius.toStringAsFixed(3)}:${captureSpeed.toStringAsFixed(3)}';
}

class RingBumper {
  const RingBumper({required this.x, required this.y, required this.radius});

  final double x;
  final double y;
  final double radius;

  String get signature =>
      '${x.toStringAsFixed(3)}:${y.toStringAsFixed(3)}:'
      '${radius.toStringAsFixed(3)}';
}

class RingTossScenario {
  const RingTossScenario._({
    required this.level,
    required this.seed,
    required this.targets,
    required this.bumpers,
    required this.gravity,
    required this.windX,
    required this.windY,
    required this.windGust,
    required this.windFrequency,
    required this.windPhase,
    required this.missLimit,
    required this.goldTimeSeconds,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, RingTossScenario> _campaign = <int, RingTossScenario>{};
  static final Map<int, RingTossScenario> _practice = <int, RingTossScenario>{};

  final int level;
  final int seed;
  final List<RingTarget> targets;
  final List<RingBumper> bumpers;
  final double gravity;
  final double windX;
  final double windY;
  final double windGust;
  final double windFrequency;
  final double windPhase;
  final int missLimit;
  final double goldTimeSeconds;

  int get targetCount => targets.length;

  RingPoint windAt(double elapsedSeconds) => RingPoint(
    windX + windGust * math.sin(elapsedSeconds * windFrequency + windPhase),
    windY +
        windGust *
            .35 *
            math.cos(elapsedSeconds * windFrequency * .73 + windPhase),
  );

  RingPoint targetAt(int index, double elapsedSeconds) {
    if (index < 0 || index >= targets.length) {
      throw RangeError.index(index, targets, 'index');
    }
    return targets[index].at(elapsedSeconds);
  }

  String get signature =>
      '$level|${targets.map((RingTarget target) => target.signature).join(';')}|'
      '${bumpers.map((RingBumper bumper) => bumper.signature).join(';')}|'
      '${gravity.toStringAsFixed(3)}:${windX.toStringAsFixed(3)}:'
      '${windY.toStringAsFixed(3)}:${windGust.toStringAsFixed(3)}:'
      '${windFrequency.toStringAsFixed(3)}:${windPhase.toStringAsFixed(3)}:'
      '$missLimit';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static RingTossScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static RingTossScenario forPracticeRound(int index) {
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
    ..._campaign.values.map((RingTossScenario scenario) => scenario.signature),
    ..._practice.values.map((RingTossScenario scenario) => scenario.signature),
  };

  static RingTossScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'ring_toss:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final double radius = (.073 - level * .0038).clamp(.034, .069).toDouble();
      final int count = 5 + level;
      final List<RingTarget> targets = List<RingTarget>.generate(count, (
        int index,
      ) {
        final double x = .25 + random.nextDouble() * .50;
        final double y = .29 + random.nextDouble() * .28;
        final double motion = level <= 2 ? 0 : .014 + level * .0052;
        return RingTarget(
          x: x,
          y: y,
          motionX: (random.nextDouble() - .5) * motion * 2,
          motionY: level < 6 ? 0 : (random.nextDouble() - .5) * motion * .65,
          frequency: .42 + level * .095 + random.nextDouble() * .12,
          phase: random.nextDouble() * math.pi * 2,
          radius: radius,
          captureSpeed: (.86 - level * .032).clamp(.40, .82).toDouble(),
        );
      }, growable: false);

      final List<RingBumper> bumpers = <RingBumper>[];
      final int bumperCount = level < 5 ? 0 : math.min(3, (level - 3) ~/ 2);
      for (int index = 0; index < bumperCount; index++) {
        for (int attempt = 0; attempt < 60; attempt++) {
          final RingBumper candidate = RingBumper(
            x: .20 + random.nextDouble() * .60,
            y: .40 + random.nextDouble() * .30,
            radius: .027 + random.nextDouble() * .015,
          );
          final bool clearOfStart =
              math.pow(candidate.x - .5, 2) + math.pow(candidate.y - .84, 2) >
              math.pow(candidate.radius + .10, 2);
          final bool clearOfTargets = targets.every(
            (RingTarget target) =>
                math.sqrt(
                  math.pow(candidate.x - target.x, 2) +
                      math.pow(candidate.y - target.y, 2),
                ) >
                candidate.radius + target.radius * 1.5,
          );
          final bool clearOfBumpers = bumpers.every(
            (RingBumper other) =>
                math.sqrt(
                  math.pow(candidate.x - other.x, 2) +
                      math.pow(candidate.y - other.y, 2),
                ) >
                candidate.radius + other.radius + .08,
          );
          if (clearOfStart && clearOfTargets && clearOfBumpers) {
            bumpers.add(candidate);
            break;
          }
        }
      }

      final double windMagnitude = level <= 2 ? 0 : (level - 2) * .009;
      final double windAngle = random.nextDouble() * math.pi * 2;
      final RingTossScenario candidate = RingTossScenario._(
        level: level,
        seed: seed,
        targets: List<RingTarget>.unmodifiable(targets),
        bumpers: List<RingBumper>.unmodifiable(bumpers),
        gravity: .45 + level * .038,
        windX: math.cos(windAngle) * windMagnitude,
        windY: math.sin(windAngle) * windMagnitude * .32,
        windGust: level <= 3 ? 0 : .006 + level * .003,
        windFrequency: .8 + level * .085,
        windPhase: random.nextDouble() * math.pi * 2,
        missLimit: level <= 3
            ? 4
            : level <= 6
            ? 3
            : level <= 8
            ? 2
            : 1,
        goldTimeSeconds: math.max(24, 55 - level * 2.1),
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Halka At course.');
  }

  static bool _isFair(RingTossScenario scenario) =>
      scenario.targets.length >= 6 &&
      scenario.targets.every(
        (RingTarget target) =>
            target.x >= .25 &&
            target.x <= .75 &&
            target.y >= .29 &&
            target.y <= .57 &&
            target.radius >= .034 &&
            target.captureSpeed >= .40,
      ) &&
      scenario.missLimit >= 1 &&
      scenario.bumpers.every((RingBumper bumper) => bumper.y > .38);
}
