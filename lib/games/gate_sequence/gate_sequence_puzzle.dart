import 'dart:math' as math;

import '../shared/content_seed.dart';

enum GateClueKind {
  atPosition,
  notPosition,
  before,
  adjacent,
  notAdjacent,
  separation,
  between,
  oddPosition,
  evenPosition,
}

enum GateClueFamily { placement, order, pattern }

class GateClue {
  const GateClue({
    required this.kind,
    required this.first,
    this.second = -1,
    this.third = -1,
    this.value = -1,
  });

  final GateClueKind kind;
  final int first;
  final int second;
  final int third;
  final int value;

  GateClueFamily get family => switch (kind) {
    GateClueKind.atPosition ||
    GateClueKind.notPosition => GateClueFamily.placement,
    GateClueKind.oddPosition ||
    GateClueKind.evenPosition => GateClueFamily.pattern,
    _ => GateClueFamily.order,
  };

  bool matches(List<int> order) {
    final int firstPosition = order.indexOf(first);
    final int secondPosition = order.indexOf(second);
    final int thirdPosition = order.indexOf(third);
    return switch (kind) {
      GateClueKind.atPosition => firstPosition == value,
      GateClueKind.notPosition => firstPosition != value,
      GateClueKind.before => firstPosition < secondPosition,
      GateClueKind.adjacent => (firstPosition - secondPosition).abs() == 1,
      GateClueKind.notAdjacent => (firstPosition - secondPosition).abs() != 1,
      GateClueKind.separation =>
        (firstPosition - secondPosition).abs() == value,
      GateClueKind.between =>
        (secondPosition < firstPosition && firstPosition < thirdPosition) ||
            (thirdPosition < firstPosition && firstPosition < secondPosition),
      GateClueKind.oddPosition => (firstPosition + 1).isOdd,
      GateClueKind.evenPosition => (firstPosition + 1).isEven,
    };
  }

  String text({required bool english}) {
    final String gate = _name(first, english);
    final String other = _name(second, english);
    final String thirdGate = _name(third, english);
    final int position = value + 1;
    return switch (kind) {
      GateClueKind.atPosition =>
        english
            ? '$gate opens in position $position.'
            : '$gate kapısı $position. sırada açılır.',
      GateClueKind.notPosition =>
        english
            ? '$gate is not in position $position.'
            : '$gate kapısı $position. sırada değildir.',
      GateClueKind.before =>
        english
            ? '$gate opens before $other.'
            : '$gate kapısı $other kapısından önce açılır.',
      GateClueKind.adjacent =>
        english
            ? '$gate and $other open consecutively.'
            : '$gate ile $other kapıları ardışık açılır.',
      GateClueKind.notAdjacent =>
        english
            ? '$gate is not next to $other.'
            : '$gate ile $other kapıları yan yana değildir.',
      GateClueKind.separation =>
        english
            ? '$gate and $other are exactly $value positions apart.'
            : '$gate ile $other arasında tam $value sıra farkı vardır.',
      GateClueKind.between =>
        english
            ? '$gate opens between $other and $thirdGate.'
            : '$gate kapısı, $other ve $thirdGate kapılarının arasındadır.',
      GateClueKind.oddPosition =>
        english
            ? '$gate is in an odd-numbered position.'
            : '$gate tek numaralı bir sıradadır.',
      GateClueKind.evenPosition =>
        english
            ? '$gate is in an even-numbered position.'
            : '$gate çift numaralı bir sıradadır.',
    };
  }

  static String _name(int index, bool english) {
    if (index < 0) return '';
    return english
        ? GateSequencePuzzle.gateNamesEn[index]
        : GateSequencePuzzle.gateNames[index];
  }

  String get signature => '$kind:$first:$second:$third:$value';
}

class GateSequencePuzzle {
  static const int maximumUniqueCases = 300;
  static const List<String> gateNames = <String>[
    'Kehribar',
    'Kobalt',
    'Fildişi',
    'Yeşim',
    'Gül',
    'Gölge',
    'Mercan',
    'Gümüş',
  ];
  static const List<String> gateNamesEn = <String>[
    'Amber',
    'Cobalt',
    'Ivory',
    'Jade',
    'Rose',
    'Shadow',
    'Coral',
    'Silver',
  ];
  static final Map<int, GateSequencePuzzle> _cache =
      <int, GateSequencePuzzle>{};
  static final Map<int, List<List<int>>> _permutationCache =
      <int, List<List<int>>>{};

  const GateSequencePuzzle({
    required this.level,
    required this.gateCount,
    required this.solution,
    required this.clues,
  });

  final int level;
  final int gateCount;
  final List<int> solution;
  final List<GateClue> clues;

  String get boardSignature =>
      '$gateCount:${solution.join(',')}:${clues.map((GateClue clue) => clue.signature).join('|')}';

  static int gateCountForLevel(int level) => switch (level) {
    < 61 => 5,
    < 131 => 6,
    < 221 => 7,
    _ => 8,
  };

  static int _stageStart(int level) => switch (level) {
    < 61 => 1,
    < 131 => 61,
    < 221 => 131,
    _ => 221,
  };

  static GateSequencePuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  bool get hasUniqueSolution => solve(clues).length == 1;

  bool isSolved(List<int> submittedOrder) {
    if (submittedOrder.length != gateCount ||
        submittedOrder.toSet().length != gateCount ||
        !submittedOrder.toSet().containsAll(
          List<int>.generate(gateCount, (int index) => index),
        )) {
      return false;
    }
    for (int index = 0; index < gateCount; index++) {
      if (submittedOrder[index] != solution[index]) return false;
    }
    return clues.every((GateClue clue) => clue.matches(submittedOrder));
  }

  List<List<int>> solve(List<GateClue> constraints, {int limit = 2}) {
    final List<List<int>> possible = _permutationCache.putIfAbsent(
      gateCount,
      () => _makePermutations(gateCount),
    );
    return possible
        .where(
          (List<int> candidate) =>
              constraints.every((GateClue clue) => clue.matches(candidate)),
        )
        .take(limit)
        .toList(growable: false);
  }

  static GateSequencePuzzle _generate(int level) {
    final int gateCount = gateCountForLevel(level);
    final int rank = level - _stageStart(level);
    final List<int> solution = _permutationAt(gateCount, rank);
    final List<GateClue> candidates = _clueCandidates(solution);
    _shuffle(
      candidates,
      ContentSeed.forLevel(gameId: 'gate_sequence', level: level),
    );

    final List<GateClue> selected = <GateClue>[];
    for (final GateClueFamily family in GateClueFamily.values) {
      selected.add(
        candidates.firstWhere((GateClue clue) => clue.family == family),
      );
    }
    List<List<int>> possible = _possibleFor(gateCount, selected);
    for (final GateClue clue in candidates) {
      if (selected.any(
        (GateClue current) => current.signature == clue.signature,
      )) {
        continue;
      }
      selected.add(clue);
      possible = _possibleFor(gateCount, selected);
      if (selected.length >= 5 && possible.length == 1) break;
    }
    if (possible.length != 1 || selected.length < 5) {
      throw StateError('Could not generate a unique gate sequence for $level.');
    }
    return GateSequencePuzzle(
      level: level,
      gateCount: gateCount,
      solution: List<int>.unmodifiable(solution),
      clues: List<GateClue>.unmodifiable(selected),
    );
  }

  static List<GateClue> _clueCandidates(List<int> solution) {
    final int gateCount = solution.length;
    final List<GateClue> clues = <GateClue>[];
    for (int gate = 0; gate < gateCount; gate++) {
      final int position = solution.indexOf(gate);
      clues.add(
        GateClue(kind: GateClueKind.atPosition, first: gate, value: position),
      );
      for (int otherPosition = 0; otherPosition < gateCount; otherPosition++) {
        if (otherPosition != position) {
          clues.add(
            GateClue(
              kind: GateClueKind.notPosition,
              first: gate,
              value: otherPosition,
            ),
          );
        }
      }
      clues.add(
        GateClue(
          kind: position.isEven
              ? GateClueKind.oddPosition
              : GateClueKind.evenPosition,
          first: gate,
        ),
      );
      for (int other = gate + 1; other < gateCount; other++) {
        final int otherIndex = solution.indexOf(other);
        final bool adjacent = (position - otherIndex).abs() == 1;
        clues.add(
          GateClue(
            kind: GateClueKind.before,
            first: position < otherIndex ? gate : other,
            second: position < otherIndex ? other : gate,
          ),
        );
        clues.add(
          GateClue(
            kind: adjacent ? GateClueKind.adjacent : GateClueKind.notAdjacent,
            first: gate,
            second: other,
          ),
        );
        final int distance = (position - otherIndex).abs();
        if (distance > 1) {
          clues.add(
            GateClue(
              kind: GateClueKind.separation,
              first: gate,
              second: other,
              value: distance,
            ),
          );
        }
      }
    }
    for (int middle = 0; middle < gateCount; middle++) {
      for (int left = 0; left < gateCount; left++) {
        for (int right = left + 1; right < gateCount; right++) {
          if (middle == left || middle == right) continue;
          final int pMiddle = solution.indexOf(middle);
          final int pLeft = solution.indexOf(left);
          final int pRight = solution.indexOf(right);
          if ((pLeft < pMiddle && pMiddle < pRight) ||
              (pRight < pMiddle && pMiddle < pLeft)) {
            clues.add(
              GateClue(
                kind: GateClueKind.between,
                first: middle,
                second: left,
                third: right,
              ),
            );
          }
        }
      }
    }
    return clues;
  }

  static List<List<int>> _possibleFor(int gateCount, List<GateClue> clues) {
    return _permutationCache
        .putIfAbsent(gateCount, () => _makePermutations(gateCount))
        .where(
          (List<int> order) =>
              clues.every((GateClue clue) => clue.matches(order)),
        )
        .take(2)
        .toList(growable: false);
  }

  static List<int> _permutationAt(int size, int rank) {
    final List<int> remaining = List<int>.generate(size, (int index) => index);
    final List<int> order = <int>[];
    int remainder = rank;
    for (int length = size; length > 0; length--) {
      final int block = _factorial(length - 1);
      final int choice = remainder ~/ block;
      remainder %= block;
      order.add(remaining.removeAt(choice));
    }
    return List<int>.unmodifiable(order);
  }

  static int _factorial(int value) {
    int result = 1;
    for (int factor = 2; factor <= value; factor++) {
      result *= factor;
    }
    return result;
  }

  static List<List<int>> _makePermutations(int size) {
    final List<List<int>> result = <List<int>>[];
    void visit(List<int> prefix, List<int> remaining) {
      if (remaining.isEmpty) {
        result.add(List<int>.unmodifiable(prefix));
        return;
      }
      for (final int value in remaining) {
        visit(
          <int>[...prefix, value],
          remaining.where((int item) => item != value).toList(growable: false),
        );
      }
    }

    visit(<int>[], List<int>.generate(size, (int index) => index));
    return List<List<int>>.unmodifiable(result);
  }

  static void _shuffle<T>(List<T> values, int seed) {
    final math.Random random = math.Random(seed);
    for (int index = values.length - 1; index > 0; index--) {
      final int other = random.nextInt(index + 1);
      final T held = values[index];
      values[index] = values[other];
      values[other] = held;
    }
  }
}
