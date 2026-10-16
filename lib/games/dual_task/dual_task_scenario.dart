import 'dart:math' as math;

import '../shared/content_seed.dart';

enum DualTaskRuleMode { shape, shapeAndColor, exact }

class DualTaskRule {
  const DualTaskRule({
    required this.mode,
    required this.shape,
    required this.color,
    required this.marker,
  });

  final DualTaskRuleMode mode;
  final int shape;
  final int color;
  final int marker;

  String get signature => '${mode.name}:$shape:$color:$marker';

  bool matches(DualTaskSymbol symbol) => switch (mode) {
    DualTaskRuleMode.shape => symbol.shape == shape,
    DualTaskRuleMode.shapeAndColor =>
      symbol.shape == shape && symbol.color == color,
    DualTaskRuleMode.exact =>
      symbol.shape == shape && symbol.color == color && symbol.marker == marker,
  };
}

class DualTaskSymbol {
  const DualTaskSymbol({
    required this.shape,
    required this.color,
    required this.marker,
  });

  final int shape;
  final int color;
  final int marker;

  String get signature => '$shape:$color:$marker';
}

class DualTaskTrial {
  const DualTaskTrial({
    required this.symbol,
    required this.rule,
    required this.isTarget,
    required this.memoryDigit,
  });

  final DualTaskSymbol symbol;
  final DualTaskRule rule;
  final bool isTarget;
  final int? memoryDigit;

  bool get isMemoryCue => memoryDigit != null;

  String get signature =>
      '${symbol.signature}/${rule.signature}/${isTarget ? 1 : 0}/${memoryDigit ?? '-'}';
}

/// Two independent workstreams: fast visual rule decisions and delayed recall
/// of digits carried by occasional secondary-task cue cards.
class DualTaskScenario {
  const DualTaskScenario({
    required this.stage,
    required this.trials,
    required this.ruleChangeBeforeTrial,
    required this.memoryDigits,
    required this.memoryCueIndices,
    required this.reverseMemoryRecall,
    required this.isPractice,
    required this.round,
    required this.variant,
    required this.exposureMs,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static const int shapeCount = 6;
  static const int colorCount = 6;
  static const int markerCount = 4;
  static final List<DualTaskScenario> _practiceDeck = _buildPracticeDeck();

  final int stage;
  final List<DualTaskTrial> trials;
  final List<int> ruleChangeBeforeTrial;
  final List<int> memoryDigits;
  final List<int> memoryCueIndices;
  final bool reverseMemoryRecall;
  final bool isPractice;
  final int round;
  final int variant;
  final int exposureMs;

  int get trialCount => trials.length;
  int get primaryTargetCount =>
      trials.where((DualTaskTrial trial) => trial.isTarget).length;
  int get memoryLength => memoryDigits.length;
  int get ruleChangeCount => ruleChangeBeforeTrial.length;
  int get mistakeLimit => stage <= 3
      ? 4
      : stage <= 6
      ? 3
      : stage <= 10
      ? 2
      : 1;
  List<int> get recallAnswer => List<int>.unmodifiable(
    reverseMemoryRecall ? memoryDigits.reversed : memoryDigits,
  );

  String get signature => <String>[
    '$stage:$trialCount:$memoryLength:$reverseMemoryRecall:$exposureMs',
    'R:${ruleChangeBeforeTrial.join(',')}',
    for (final DualTaskTrial trial in trials) trial.signature,
    'M:${memoryDigits.join(',')}',
  ].join('|');

  static DualTaskScenario forCampaignLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      stage: level,
      isPractice: false,
      round: level,
      variant: 0,
      seed: ContentSeed.forLevel(gameId: 'dual_task:campaign', level: level),
    );
  }

  static DualTaskScenario forPracticeRound(int round) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _practiceDeck[round - 1];
  }

  static List<DualTaskScenario> _buildPracticeDeck() {
    final Set<String> occupied = <String>{
      for (int level = 1; level <= campaignLevels; level++)
        forCampaignLevel(level).signature,
    };
    final List<DualTaskScenario> deck = <DualTaskScenario>[];
    for (int round = 1; round <= uniquePracticeRounds; round++) {
      final int stage = ((round - 1) % campaignLevels) + 1;
      DualTaskScenario? selected;
      for (int attempt = 0; attempt < 20000; attempt++) {
        final DualTaskScenario candidate = _build(
          stage: stage,
          isPractice: true,
          round: round,
          variant: attempt,
          seed: ContentSeed.forLevel(
            gameId: 'dual_task:practice:$attempt',
            level: round,
          ),
        );
        if (occupied.add(candidate.signature)) {
          selected = candidate;
          break;
        }
      }
      if (selected == null) {
        throw StateError('Could not generate unique dual-task round $round.');
      }
      deck.add(selected);
    }
    return List<DualTaskScenario>.unmodifiable(deck);
  }

  static DualTaskScenario _build({
    required int stage,
    required bool isPractice,
    required int round,
    required int variant,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final int count = switch (stage) {
      <= 2 => 8,
      <= 6 => 10,
      <= 10 => 12,
      <= 13 => 14,
      <= 16 => 16,
      <= 19 => 18,
      _ => 20,
    };
    final int memoryLength = switch (stage) {
      <= 3 => 2,
      <= 10 => 3,
      <= 16 => 4,
      <= 19 => 5,
      _ => 6,
    };
    final int segmentCount = stage <= 6
        ? 1
        : stage <= 10
        ? 2
        : stage <= 16
        ? 3
        : stage <= 19
        ? 3
        : 4;
    final List<int> changes = <int>[
      for (int segment = 1; segment < segmentCount; segment++)
        (count * segment) ~/ segmentCount,
    ];
    final int exposure = stage <= 3
        ? 1050
        : stage <= 6
        ? 900
        : stage <= 10
        ? 760
        : stage <= 13
        ? 680
        : stage <= 16
        ? 600
        : stage <= 19
        ? 520
        : 450;

    final List<int> cueIndices = _cuePositions(
      count: count,
      cueCount: memoryLength,
      random: random,
    );
    final List<int> memoryDigits = _uniqueDigits(memoryLength, random);
    final List<DualTaskTrial> trials = <DualTaskTrial>[];
    final List<DualTaskRule> rules = <DualTaskRule>[];
    int activeSegment = 0;
    for (int segment = 0; segment < segmentCount; segment++) {
      final DualTaskRuleMode mode = _modeFor(stage, segment);
      final DualTaskRule? previous = rules.isEmpty ? null : rules.last;
      rules.add(
        DualTaskRule(
          mode: mode,
          shape: _different(previous?.shape, shapeCount, random),
          color: _different(previous?.color, colorCount, random),
          marker: _different(previous?.marker, markerCount, random),
        ),
      );
    }
    for (int index = 0; index < count; index++) {
      while (activeSegment < changes.length &&
          index >= changes[activeSegment]) {
        activeSegment++;
      }
      final DualTaskRule rule = rules[activeSegment];
      final bool target = (index + variant) % 3 == 1;
      final DualTaskSymbol symbol = _fitSymbol(
        rule: rule,
        matches: target,
        random: random,
      );
      final int cue = cueIndices.indexOf(index);
      trials.add(
        DualTaskTrial(
          symbol: symbol,
          rule: rule,
          isTarget: rule.matches(symbol),
          memoryDigit: cue < 0 ? null : memoryDigits[cue],
        ),
      );
    }
    return DualTaskScenario(
      stage: stage,
      trials: List<DualTaskTrial>.unmodifiable(trials),
      ruleChangeBeforeTrial: List<int>.unmodifiable(changes),
      memoryDigits: List<int>.unmodifiable(memoryDigits),
      memoryCueIndices: List<int>.unmodifiable(cueIndices),
      reverseMemoryRecall: stage >= 19,
      isPractice: isPractice,
      round: round,
      variant: variant,
      exposureMs: exposure,
    );
  }

  static DualTaskRuleMode _modeFor(int stage, int segment) {
    if (stage <= 3) return DualTaskRuleMode.shape;
    if (stage <= 10) return DualTaskRuleMode.shapeAndColor;
    if (stage <= 16) {
      return segment == 1
          ? DualTaskRuleMode.exact
          : DualTaskRuleMode.shapeAndColor;
    }
    if (stage <= 19) {
      return switch (segment) {
        0 => DualTaskRuleMode.shape,
        1 => DualTaskRuleMode.shapeAndColor,
        _ => DualTaskRuleMode.exact,
      };
    }
    return switch (segment) {
      0 => DualTaskRuleMode.shape,
      1 => DualTaskRuleMode.shapeAndColor,
      2 => DualTaskRuleMode.exact,
      _ => DualTaskRuleMode.shapeAndColor,
    };
  }

  static List<int> _cuePositions({
    required int count,
    required int cueCount,
    required math.Random random,
  }) {
    final Set<int> selected = <int>{};
    for (int cue = 0; cue < cueCount; cue++) {
      final int center = ((cue + 1) * count) ~/ (cueCount + 1);
      int position = (center + random.nextInt(3) - 1).clamp(0, count - 1);
      for (
        int attempt = 0;
        selected.contains(position) ||
            selected.any((int existing) => (existing - position).abs() <= 1);
        attempt++
      ) {
        position = (center + attempt + cue) % count;
      }
      selected.add(position);
    }
    return selected.toList()..sort();
  }

  static List<int> _uniqueDigits(int count, math.Random random) {
    final List<int> digits = List<int>.generate(10, (int index) => index)
      ..shuffle(random);
    return digits.take(count).toList(growable: false);
  }

  static int _different(int? previous, int count, math.Random random) {
    final int candidate = random.nextInt(count);
    return previous == null || count <= 1
        ? candidate
        : candidate == previous
        ? (candidate + 1 + random.nextInt(count - 1)) % count
        : candidate;
  }

  static DualTaskSymbol _fitSymbol({
    required DualTaskRule rule,
    required bool matches,
    required math.Random random,
  }) {
    if (matches) {
      return DualTaskSymbol(
        shape: rule.shape,
        color: rule.color,
        marker: rule.marker,
      );
    }
    return switch (rule.mode) {
      DualTaskRuleMode.shape => DualTaskSymbol(
        shape: (rule.shape + 1 + random.nextInt(shapeCount - 1)) % shapeCount,
        color: random.nextInt(colorCount),
        marker: random.nextInt(markerCount),
      ),
      DualTaskRuleMode.shapeAndColor => DualTaskSymbol(
        shape: rule.shape,
        color: (rule.color + 1 + random.nextInt(colorCount - 1)) % colorCount,
        marker: random.nextInt(markerCount),
      ),
      DualTaskRuleMode.exact => DualTaskSymbol(
        shape: rule.shape,
        color: rule.color,
        marker:
            (rule.marker + 1 + random.nextInt(markerCount - 1)) % markerCount,
      ),
    };
  }
}
