import 'dart:math' as math;

import '../shared/content_seed.dart';

class ReactorPulseSpec {
  const ReactorPulseSpec({
    required this.spawnAt,
    required this.inputLane,
    required this.destination,
    required this.speed,
    required this.phase,
  });

  final double spawnAt;
  final int inputLane;
  final int destination;
  final double speed;
  final double phase;

  String get signature =>
      '${spawnAt.toStringAsFixed(3)}:$inputLane:$destination:'
      '${speed.toStringAsFixed(3)}:${phase.toStringAsFixed(3)}';
}

class ReactorScenario {
  const ReactorScenario._({
    required this.level,
    required this.seed,
    required this.channelCount,
    required this.requiredHits,
    required this.pulses,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, ReactorScenario> _campaign = <int, ReactorScenario>{};
  static final Map<int, ReactorScenario> _practice = <int, ReactorScenario>{};

  final int level;
  final int seed;
  final int channelCount;
  final int requiredHits;
  final List<ReactorPulseSpec> pulses;

  String get signature =>
      '$level|$channelCount|$requiredHits|'
      '${pulses.map((ReactorPulseSpec pulse) => pulse.signature).join(';')}';

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static ReactorScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static ReactorScenario forPracticeRound(int index) {
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
    ..._campaign.values.map((ReactorScenario scenario) => scenario.signature),
    ..._practice.values.map((ReactorScenario scenario) => scenario.signature),
  };

  static ReactorScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 200; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'color_match:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int channelCount = level == 1
          ? 1
          : level <= 3
          ? 2
          : 3;
      final int pulseCount = 7 + level;
      final double baseGap = (.98 - level * .018).clamp(.78, .96).toDouble();
      double spawnAt = .42;
      final List<ReactorPulseSpec> pulses = <ReactorPulseSpec>[];
      int previousDestination = 0;
      for (int index = 0; index < pulseCount; index++) {
        final int destination;
        if (index == 0 || level == 1) {
          destination = 0;
        } else if (level >= 4 && index < channelCount) {
          destination = index;
        } else {
          int next = random.nextInt(channelCount);
          if (level >= 7 && next == previousDestination) {
            next = (next + 1 + random.nextInt(channelCount - 1)) % channelCount;
          }
          destination = next;
        }
        pulses.add(
          ReactorPulseSpec(
            spawnAt: spawnAt,
            inputLane: random.nextInt(3),
            destination: destination,
            speed: .38 + level * .03 + random.nextDouble() * .015,
            phase: random.nextDouble() * math.pi * 2,
          ),
        );
        previousDestination = destination;
        spawnAt += baseGap + random.nextDouble() * .11;
      }
      final ReactorScenario candidate = ReactorScenario._(
        level: level,
        seed: seed,
        channelCount: channelCount,
        requiredHits:
            pulseCount -
            (level >= 9
                ? 2
                : level >= 5
                ? 1
                : 0),
        pulses: List<ReactorPulseSpec>.unmodifiable(pulses),
      );
      if (!used.contains(candidate.signature) && _isFair(candidate)) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique Reactor pulse sequence.');
  }

  static bool _isFair(ReactorScenario scenario) {
    if (scenario.pulses.length < 8 || scenario.requiredHits <= 0) return false;
    for (int index = 0; index < scenario.pulses.length; index++) {
      final ReactorPulseSpec pulse = scenario.pulses[index];
      if (pulse.destination < 0 || pulse.destination >= scenario.channelCount) {
        return false;
      }
      if (pulse.inputLane < 0 || pulse.inputLane > 2) return false;
      if (pulse.speed < .4 || pulse.speed > .72) return false;
      if (index > 0 &&
          pulse.spawnAt - scenario.pulses[index - 1].spawnAt < .50) {
        return false;
      }
    }
    return true;
  }
}
