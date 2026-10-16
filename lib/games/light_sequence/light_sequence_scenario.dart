import 'dart:math' as math;

import '../shared/content_seed.dart';

class LightSequenceFlash {
  const LightSequenceFlash({required this.cell, required this.isDecoy});

  final int cell;
  final bool isDecoy;
}

/// A spatial sequence with interleaved false flashes and optional reverse recall.
class LightSequenceScenario {
  const LightSequenceScenario({
    required this.stage,
    required this.gridSize,
    required this.sequence,
    required this.flashes,
    required this.reverseRecall,
    required this.mistakeLimit,
    required this.flashIntervalMs,
    required this.isPractice,
    required this.round,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  final int stage;
  final int gridSize;
  final List<int> sequence;
  final List<LightSequenceFlash> flashes;
  final bool reverseRecall;
  final int mistakeLimit;
  final int flashIntervalMs;
  final bool isPractice;
  final int round;

  int get boardLength => gridSize * gridSize;
  int get decoyCount =>
      flashes.where((LightSequenceFlash flash) => flash.isDecoy).length;
  List<int> get answer =>
      List<int>.unmodifiable(reverseRecall ? sequence.reversed : sequence);

  String get boardSignature {
    final String signal = sequence.join(',');
    final List<int> decoys =
        flashes
            .where((LightSequenceFlash flash) => flash.isDecoy)
            .map((LightSequenceFlash flash) => flash.cell)
            .toList()
          ..sort();
    return '$gridSize|$signal|${decoys.join(',')}|${reverseRecall ? 'reverse' : 'forward'}';
  }

  bool accepts(List<int> input) {
    if (input.length != answer.length) return false;
    for (int index = 0; index < answer.length; index++) {
      if (input[index] != answer[index]) return false;
    }
    return true;
  }

  static LightSequenceScenario forCampaignLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    final int size = 5;
    final List<int> coprimeSteps = <int>[
      1,
      2,
      3,
      4,
      6,
      7,
      8,
      9,
      11,
      12,
      13,
      14,
      16,
      17,
      18,
      19,
      21,
      22,
      23,
      24,
    ];
    final int length = switch (level) {
      <= 2 => 3,
      <= 4 => 4,
      <= 6 => 5,
      <= 10 => 6,
      <= 13 => 7,
      <= 16 => 8,
      <= 18 => 9,
      19 => 10,
      _ => 11,
    };
    final int start = level - 1;
    final int step = coprimeSteps[level - 1];
    final List<int> sequence = List<int>.generate(
      length,
      (int index) => (start + step * index) % (size * size),
      growable: false,
    );
    return _build(
      stage: level,
      gridSize: size,
      sequence: sequence,
      seed: ContentSeed.forLevel(
        gameId: 'light_sequence:campaign',
        level: level,
      ),
      isPractice: false,
      round: level,
    );
  }

  static LightSequenceScenario forPracticeRound(int round) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    final int index = round - 1;
    final int stage = (index % campaignLevels) + 1;
    final int cycle = index ~/ 128;
    final int sequenceLength = 3 + ((stage - 1) % 8) + cycle;
    final int start = index % 16;
    final int step = 1 + 2 * ((index ~/ 16) % 8);
    final List<int> sequence = List<int>.generate(
      sequenceLength,
      (int position) => (start + step * position) % 16,
      growable: false,
    );
    return _build(
      stage: stage,
      gridSize: 4,
      sequence: sequence,
      seed: ContentSeed.forLevel(
        gameId: 'light_sequence:practice',
        level: round,
      ),
      isPractice: true,
      round: round,
    );
  }

  static LightSequenceScenario _build({
    required int stage,
    required int gridSize,
    required List<int> sequence,
    required int seed,
    required bool isPractice,
    required int round,
  }) {
    final int decoyCount = stage < 7
        ? 0
        : stage < 11
        ? 2
        : stage < 17
        ? 3
        : 4;
    final Set<int> sequenceSet = sequence.toSet();
    final List<int> decoyCells =
        List<int>.generate(
            gridSize * gridSize,
            (int i) => i,
          ).where((int cell) => !sequenceSet.contains(cell)).toList()
          ..shuffle(math.Random(seed));
    final List<LightSequenceFlash> flashes = <LightSequenceFlash>[
      for (int index = 0; index < sequence.length; index++)
        LightSequenceFlash(cell: sequence[index], isDecoy: false),
    ];
    for (int index = 0; index < decoyCount; index++) {
      final int insertion = math.Random(seed ^ (index + 1) * 0x45d9f3b)
          .nextInt(flashes.length + 1);
      flashes.insert(
        insertion,
        LightSequenceFlash(cell: decoyCells[index], isDecoy: true),
      );
    }
    return LightSequenceScenario(
      stage: stage,
      gridSize: gridSize,
      sequence: List<int>.unmodifiable(sequence),
      flashes: List<LightSequenceFlash>.unmodifiable(flashes),
      reverseRecall: stage >= 11,
      mistakeLimit: stage <= 3
          ? 5
          : stage <= 6
          ? 4
          : stage <= 10
          ? 3
          : stage <= 16
          ? 2
          : 1,
      flashIntervalMs: math.max(240, 640 - stage * 18),
      isPractice: isPractice,
      round: round,
    );
  }
}
