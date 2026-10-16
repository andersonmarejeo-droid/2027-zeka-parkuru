import 'dart:math' as math;

import '../shared/content_seed.dart';

enum PenaltyLane { left, center, right }

class PenaltyBodyCue {
  const PenaltyBodyCue({
    required this.shoulder,
    required this.hip,
    required this.plantFoot,
  });

  final PenaltyLane shoulder;
  final PenaltyLane hip;
  final PenaltyLane plantFoot;

  PenaltyLane get majority {
    if (shoulder == hip || shoulder == plantFoot) return shoulder;
    if (hip == plantFoot) return hip;
    return shoulder;
  }

  String get signature => '${shoulder.name}:${hip.name}:${plantFoot.name}';
}

class PenaltyScenario {
  const PenaltyScenario._({
    required this.level,
    required this.seed,
    required this.roundCount,
    required this.kickLanes,
    required this.keeperReads,
    required this.bodyCues,
    required this.shotPowerTargets,
    required this.shotSpeed,
    required this.keeperSkill,
    required this.runUpSeconds,
    required this.diveTimingWindow,
    required this.maxOvertimeRounds,
  });

  static const int campaignLevels = 20;
  static const int practiceShootouts = 300;

  final int level;
  final int seed;
  final int roundCount;
  final List<PenaltyLane> kickLanes;
  final List<PenaltyLane> keeperReads;
  final List<PenaltyBodyCue> bodyCues;
  final List<double> shotPowerTargets;
  final double shotSpeed;
  final double keeperSkill;
  final double runUpSeconds;
  final double diveTimingWindow;
  final int maxOvertimeRounds;

  String get signature => <String>[
    '$level:$seed',
    'rounds:$roundCount:$maxOvertimeRounds',
    'kicks:${kickLanes.map((PenaltyLane lane) => lane.name).join(',')}',
    'reads:${keeperReads.map((PenaltyLane lane) => lane.name).join(',')}',
    'cues:${bodyCues.map((PenaltyBodyCue cue) => cue.signature).join(';')}',
    'power:${shotPowerTargets.map((double value) => value.toStringAsFixed(3)).join(',')}',
    'speed:${shotSpeed.toStringAsFixed(3)}:keeper:${keeperSkill.toStringAsFixed(3)}',
    'timing:${runUpSeconds.toStringAsFixed(3)}:${diveTimingWindow.toStringAsFixed(3)}',
  ].join('|');

  PenaltyLane kickAt(int index) => kickLanes[index % kickLanes.length];
  PenaltyLane keeperReadAt(int index) =>
      keeperReads[index % keeperReads.length];
  PenaltyBodyCue cueAt(int index) => bodyCues[index % bodyCues.length];
  double powerAt(int index) =>
      shotPowerTargets[index % shotPowerTargets.length];

  static PenaltyScenario forLevel(int level) {
    _checkLevel(level);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'penalty_mindgame_campaign', level: level),
    );
  }

  static PenaltyScenario forPracticeShootout(int index) {
    if (index < 1 || index > practiceShootouts) {
      throw RangeError.range(index, 1, practiceShootouts, 'index');
    }
    final int level = 1 + ((index - 1) % campaignLevels);
    return _build(
      level,
      ContentSeed.forLevel(gameId: 'penalty_mindgame_practice', level: index),
    );
  }

  static void _checkLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels, 'level');
    }
  }

  static PenaltyScenario _build(int level, int seed) {
    final math.Random random = math.Random(seed);
    final int rounds = 3 + (level - 1) ~/ 8;
    final int maximumRounds = rounds + 2;
    final List<PenaltyLane> kicks = <PenaltyLane>[];
    final List<PenaltyLane> keeperReads = <PenaltyLane>[];
    final List<PenaltyBodyCue> cues = <PenaltyBodyCue>[];
    final List<double> powers = <double>[];

    for (int index = 0; index < maximumRounds; index++) {
      final PenaltyLane actual = PenaltyLane.values[random.nextInt(3)];
      kicks.add(actual);
      keeperReads.add(PenaltyLane.values[random.nextInt(3)]);
      final int fakeCue = level < 5 ? -1 : random.nextInt(3);
      final List<PenaltyLane> signals = <PenaltyLane>[actual, actual, actual];
      if (fakeCue >= 0) {
        final List<PenaltyLane> alternatives = PenaltyLane.values
            .where((PenaltyLane lane) => lane != actual)
            .toList(growable: false);
        signals[fakeCue] = alternatives[random.nextInt(alternatives.length)];
      }
      cues.add(
        PenaltyBodyCue(
          shoulder: signals[0],
          hip: signals[1],
          plantFoot: signals[2],
        ),
      );
      powers.add(.60 + random.nextDouble() * .16);
    }

    return PenaltyScenario._(
      level: level,
      seed: seed,
      roundCount: rounds,
      kickLanes: List<PenaltyLane>.unmodifiable(kicks),
      keeperReads: List<PenaltyLane>.unmodifiable(keeperReads),
      bodyCues: List<PenaltyBodyCue>.unmodifiable(cues),
      shotPowerTargets: List<double>.unmodifiable(powers),
      shotSpeed: (.48 + level * .024 + random.nextDouble() * .055)
          .clamp(.50, 1.02)
          .toDouble(),
      keeperSkill: (.22 + level * .031 + random.nextDouble() * .06)
          .clamp(.25, .93)
          .toDouble(),
      runUpSeconds: (1.42 - level * .025 + random.nextDouble() * .08)
          .clamp(.78, 1.48)
          .toDouble(),
      diveTimingWindow: (.29 - level * .009 + random.nextDouble() * .018)
          .clamp(.085, .30)
          .toDouble(),
      maxOvertimeRounds: 2,
    );
  }
}
