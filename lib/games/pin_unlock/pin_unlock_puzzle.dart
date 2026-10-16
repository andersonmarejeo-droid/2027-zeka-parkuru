import 'dart:math' as math;

import '../shared/content_seed.dart';

enum PinClueKind {
  pairSum,
  windowSum,
  totalSum,
  heightCount,
  oddPins,
  risingSteps,
  pairGap,
  relation,
  alternatingRemainder,
  peakCount,
  matchingNeighbors,
  range,
}

enum PinClueFamily { pair, aggregate, sequence }

class PinClue {
  const PinClue({
    required this.kind,
    this.first = -1,
    this.second = -1,
    this.value = 0,
  });

  final PinClueKind kind;
  final int first;
  final int second;
  final int value;

  PinClueFamily get family => switch (kind) {
    PinClueKind.pairSum ||
    PinClueKind.pairGap ||
    PinClueKind.relation => PinClueFamily.pair,
    PinClueKind.windowSum ||
    PinClueKind.totalSum ||
    PinClueKind.heightCount ||
    PinClueKind.oddPins => PinClueFamily.aggregate,
    _ => PinClueFamily.sequence,
  };

  bool matches(List<int> heights) {
    final int total = heights.fold<int>(
      0,
      (int sum, int height) => sum + height,
    );
    return switch (kind) {
      PinClueKind.pairSum => heights[first] + heights[second] == value,
      PinClueKind.windowSum =>
        heights
                .skip(first)
                .take(second)
                .fold<int>(0, (int sum, int height) => sum + height) ==
            value,
      PinClueKind.totalSum => total == value,
      PinClueKind.heightCount =>
        heights.where((int height) => height == first).length == value,
      PinClueKind.oddPins =>
        heights.where((int height) => height.isOdd).length == value,
      PinClueKind.risingSteps =>
        _count(heights, (int left, int right) => right > left) == value,
      PinClueKind.pairGap => (heights[first] - heights[second]).abs() == value,
      PinClueKind.relation => switch (value) {
        0 => heights[first] < heights[second],
        1 => heights[first] > heights[second],
        _ => heights[first] == heights[second],
      },
      PinClueKind.alternatingRemainder =>
        ((heights.indexed.fold<int>(
                          0,
                          (int sum, (int index, int height) item) =>
                              sum + (item.$1.isEven ? item.$2 : -item.$2),
                        ) %
                        5 +
                    5) %
                5) ==
            value,
      PinClueKind.peakCount => _peakCount(heights) == value,
      PinClueKind.matchingNeighbors =>
        _count(heights, (int left, int right) => left == right) == value,
      PinClueKind.range =>
        heights.reduce(math.max) - heights.reduce(math.min) == value,
    };
  }

  String text({required bool english}) {
    final String a = _pinName(first);
    final String b = _pinName(second);
    return switch (kind) {
      PinClueKind.pairSum =>
        english
            ? 'Pins $a and $b add up to $value.'
            : '$a ve $b pimlerinin toplamı $value eder.',
      PinClueKind.windowSum =>
        english
            ? 'Pins ${_pinName(first)}–${_pinName(first + second - 1)} total $value.'
            : '${_pinName(first)}–${_pinName(first + second - 1)} pimleri toplam $value eder.',
      PinClueKind.totalSum =>
        english
            ? 'All pin heights total $value.'
            : 'Tüm pim yüksekliklerinin toplamı $value eder.',
      PinClueKind.heightCount =>
        english
            ? 'Exactly $value pins are at notch $first.'
            : 'Tam $value pim $first. çentiktedir.',
      PinClueKind.oddPins =>
        english
            ? 'Exactly $value pins have an odd height.'
            : 'Tam $value pimin yüksekliği tek sayıdır.',
      PinClueKind.risingSteps =>
        english
            ? '$value neighboring pairs rise from left to right.'
            : 'Soldan sağa tam $value komşu çiftte yükseklik artar.',
      PinClueKind.pairGap =>
        english
            ? 'Pins $a and $b differ by $value notches.'
            : '$a ve $b pimleri arasında $value çentik fark vardır.',
      PinClueKind.relation =>
        english
            ? switch (value) {
                0 => 'Pin $a is lower than pin $b.',
                1 => 'Pin $a is higher than pin $b.',
                _ => 'Pins $a and $b are at the same height.',
              }
            : switch (value) {
                0 => '$a pimi, $b piminden aşağıdadır.',
                1 => '$a pimi, $b piminden yukarıdadır.',
                _ => '$a ve $b pimleri aynı yüksekliktedir.',
              },
      PinClueKind.alternatingRemainder =>
        english
            ? 'Alternating pin torque leaves remainder $value when divided by 5.'
            : 'Sıralı pim torkunun 5 ile bölümünden kalan $value olur.',
      PinClueKind.peakCount =>
        english
            ? 'The pin line contains $value local peak${value == 1 ? '' : 's'}.'
            : 'Pim dizisinde $value yerel tepe noktası vardır.',
      PinClueKind.matchingNeighbors =>
        english
            ? '$value neighboring pairs share a height.'
            : 'Tam $value komşu pim çifti aynı yüksekliktedir.',
      PinClueKind.range =>
        english
            ? 'The highest and lowest pins are $value notches apart.'
            : 'En yüksek ve en alçak pim arasında $value çentik vardır.',
    };
  }

  String get signature => '$kind:$first:$second:$value';

  static String _pinName(int index) {
    if (index < 0) return '';
    return String.fromCharCode(65 + index);
  }

  static int _count(
    List<int> heights,
    bool Function(int left, int right) predicate,
  ) {
    int count = 0;
    for (int index = 0; index < heights.length - 1; index++) {
      if (predicate(heights[index], heights[index + 1])) count++;
    }
    return count;
  }

  static int _peakCount(List<int> heights) {
    int count = 0;
    for (int index = 1; index < heights.length - 1; index++) {
      if (heights[index] > heights[index - 1] &&
          heights[index] > heights[index + 1]) {
        count++;
      }
    }
    return count;
  }
}

class PinUnlockPuzzle {
  static const int maximumUniqueCases = 300;
  static const int heightCount = 4;
  static final Map<int, PinUnlockPuzzle> _cache = <int, PinUnlockPuzzle>{};

  const PinUnlockPuzzle({
    required this.level,
    required this.pinCount,
    required this.solution,
    required this.clues,
    required this.localStage,
  });

  final int level;
  final int pinCount;
  final List<int> solution;
  final List<PinClue> clues;
  final int localStage;

  String get boardSignature =>
      '$pinCount:${solution.join()}:${clues.map((PinClue clue) => clue.signature).join('|')}';

  String get difficultyTier => switch (localStage) {
    <= 6 => 'MASTERY',
    <= 8 => 'ADVANCED',
    _ => 'EXPERT',
  };

  static int pinCountForLevel(int level) => switch (level) {
    < 61 => 5,
    < 131 => 6,
    < 221 => 7,
    _ => 8,
  };

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static int extraCluesForStage(int stage) => 10 - stage;

  static PinUnlockPuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  bool get hasUniqueSolution => solve(clues).length == 1;

  bool isSolved(List<int> submittedHeights) {
    if (submittedHeights.length != pinCount ||
        submittedHeights.any(
          (int height) => height < 1 || height > heightCount,
        )) {
      return false;
    }
    return clues.every((PinClue clue) => clue.matches(submittedHeights));
  }

  List<List<int>> solve(List<PinClue> constraints, {int limit = 2}) {
    final int combinations = math.pow(heightCount, pinCount).toInt();
    final List<List<int>> results = <List<int>>[];
    for (int code = 0; code < combinations; code++) {
      int remainder = code;
      final List<int> heights = List<int>.generate(pinCount, (int index) {
        final int height = remainder % heightCount + 1;
        remainder ~/= heightCount;
        return height;
      }, growable: false);
      if (constraints.every((PinClue clue) => clue.matches(heights))) {
        results.add(heights);
        if (results.length >= limit) return results;
      }
    }
    return results;
  }

  static PinUnlockPuzzle _generate(int level) {
    final int pinCount = pinCountForLevel(level);
    final int bandStart = switch (level) {
      < 61 => 1,
      < 131 => 61,
      < 221 => 131,
      _ => 221,
    };
    final int rank = level - bandStart;
    final int combinations = math.pow(heightCount, pinCount).toInt();
    // 733 is coprime to every power of four, so each rank maps to a
    // deterministic, non-repeating pin arrangement within its size band.
    final int code = (rank * 733 + 271) % combinations;
    int remainder = code;
    final List<int> solution = List<int>.generate(pinCount, (int index) {
      final int height = remainder % heightCount + 1;
      remainder ~/= heightCount;
      return height;
    }, growable: false);

    final int localStage = stageForLevel(level);
    final List<PinClue> clues = _anchorClues(solution);
    final List<PinClue> extras = _extraClues(solution);
    _shuffle(extras, ContentSeed.forLevel(gameId: 'pin_unlock', level: level));
    final int extraCount = extraCluesForStage(localStage);
    final List<PinClue> selectedExtras = <PinClue>[];
    if (localStage >= 7 && extraCount > 0) {
      selectedExtras.add(
        extras.firstWhere(
          (PinClue clue) => clue.family == PinClueFamily.sequence,
        ),
      );
      if (extraCount > 1) {
        selectedExtras.add(
          extras.firstWhere(
            (PinClue clue) =>
                clue.family == PinClueFamily.aggregate &&
                !selectedExtras.contains(clue),
          ),
        );
      }
    } else if (extraCount > 0) {
      for (final PinClueFamily family in PinClueFamily.values) {
        if (selectedExtras.length >= extraCount) break;
        selectedExtras.add(
          extras.firstWhere(
            (PinClue clue) =>
                clue.family == family && !selectedExtras.contains(clue),
          ),
        );
      }
    }
    for (final PinClue clue in extras) {
      if (selectedExtras.length >= extraCount) break;
      if (!selectedExtras.contains(clue)) selectedExtras.add(clue);
    }
    clues.addAll(selectedExtras);
    _shuffle(
      clues,
      ContentSeed.forLevel(gameId: 'pin_unlock_order', level: level),
    );

    final PinUnlockPuzzle puzzle = PinUnlockPuzzle(
      level: level,
      pinCount: pinCount,
      solution: List<int>.unmodifiable(solution),
      clues: List<PinClue>.unmodifiable(clues),
      localStage: localStage,
    );
    if (!puzzle.hasUniqueSolution || !puzzle.isSolved(solution)) {
      throw StateError(
        'Could not generate a unique pin lock for level $level.',
      );
    }
    return puzzle;
  }

  static List<PinClue> _anchorClues(List<int> solution) {
    // Pair sums on a star plus one triangle edge form a full-rank system:
    // players must combine equations to recover every pin, never read a pin
    // height directly from a single clue.
    final List<PinClue> clues = <PinClue>[
      for (int pin = 1; pin < solution.length; pin++)
        PinClue(
          kind: PinClueKind.pairSum,
          first: 0,
          second: pin,
          value: solution[0] + solution[pin],
        ),
      PinClue(
        kind: PinClueKind.pairSum,
        first: 1,
        second: 2,
        value: solution[1] + solution[2],
      ),
    ];
    return clues;
  }

  static List<PinClue> _extraClues(List<int> solution) {
    final int pinCount = solution.length;
    final List<PinClue> clues = <PinClue>[
      PinClue(
        kind: PinClueKind.totalSum,
        value: solution.fold<int>(0, (int sum, int height) => sum + height),
      ),
      PinClue(
        kind: PinClueKind.oddPins,
        value: solution.where((int height) => height.isOdd).length,
      ),
      PinClue(
        kind: PinClueKind.risingSteps,
        value: PinClue._count(solution, (int a, int b) => b > a),
      ),
      PinClue(
        kind: PinClueKind.alternatingRemainder,
        value:
            ((solution.indexed.fold<int>(
                      0,
                      (int sum, (int index, int height) item) =>
                          sum + (item.$1.isEven ? item.$2 : -item.$2),
                    ) %
                    5 +
                5) %
            5),
      ),
      PinClue(kind: PinClueKind.peakCount, value: PinClue._peakCount(solution)),
      PinClue(
        kind: PinClueKind.matchingNeighbors,
        value: PinClue._count(solution, (int a, int b) => a == b),
      ),
      PinClue(
        kind: PinClueKind.range,
        value: solution.reduce(math.max) - solution.reduce(math.min),
      ),
      for (int height = 1; height <= heightCount; height++)
        PinClue(
          kind: PinClueKind.heightCount,
          first: height,
          value: solution.where((int item) => item == height).length,
        ),
      for (int start = 0; start < pinCount - 2; start++)
        PinClue(
          kind: PinClueKind.windowSum,
          first: start,
          second: 3,
          value: solution
              .skip(start)
              .take(3)
              .fold<int>(0, (int sum, int height) => sum + height),
        ),
    ];
    for (int first = 0; first < pinCount; first++) {
      for (int second = first + 1; second < pinCount; second++) {
        final int a = solution[first];
        final int b = solution[second];
        clues.add(
          PinClue(
            kind: PinClueKind.pairGap,
            first: first,
            second: second,
            value: (a - b).abs(),
          ),
        );
        clues.add(
          PinClue(
            kind: PinClueKind.relation,
            first: first,
            second: second,
            value: a < b
                ? 0
                : a > b
                ? 1
                : 2,
          ),
        );
      }
    }
    return clues;
  }

  static void _shuffle<T>(List<T> values, int seed) {
    final math.Random random = math.Random(seed);
    for (int index = values.length - 1; index > 0; index--) {
      final int swap = random.nextInt(index + 1);
      final T value = values[index];
      values[index] = values[swap];
      values[swap] = value;
    }
  }
}
