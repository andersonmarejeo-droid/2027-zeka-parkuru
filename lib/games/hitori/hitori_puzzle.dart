import 'dart:math' as math;

import '../shared/content_seed.dart';

class HitoriSolveResult {
  const HitoriSolveResult({
    required this.solutionCount,
    required this.firstSolution,
    this.alternativeSolution,
    required this.visitedNodes,
    required this.exceededNodeLimit,
  });

  final int solutionCount;
  final List<bool>? firstSolution;
  final List<bool>? alternativeSolution;
  final int visitedNodes;
  final bool exceededNodeLimit;
}

/// A Hitori board certified against the three standard rules:
/// no repeated unshaded values in a row or column, no orthogonal black
/// neighbors, and one orthogonally connected unshaded region.
class HitoriPuzzle {
  HitoriPuzzle._({
    required this.level,
    required this.seed,
    required this.size,
    required List<int> values,
    required List<bool> solution,
  }) : values = List<int>.unmodifiable(values),
       solution = List<bool>.unmodifiable(solution);

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static const int defaultNodeLimit = 250000;
  static const int generationNodeLimit = 18000;
  static const List<int> _templateValues = <int>[
    4,
    2,
    3,
    2,
    5,
    2,
    2,
    1,
    4,
    3,
    3,
    3,
    4,
    1,
    4,
    1,
    4,
    4,
    3,
    2,
    5,
    1,
    2,
    5,
    3,
  ];
  static const List<int> _templateBlackCells = <int>[3, 6, 10, 14, 17, 20, 24];
  static final Map<int, HitoriPuzzle> _campaign = <int, HitoriPuzzle>{};
  static final Map<int, HitoriPuzzle> _practice = <int, HitoriPuzzle>{};

  final int level;
  final int seed;
  final int size;
  final List<int> values;
  final List<bool> solution;

  String get signature => '$size|${values.join(',')}';
  int get blackCount => solution.where((bool black) => black).length;
  int get duplicateGroupCount => _duplicateGroups(size, values).length;
  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP READING',
    _ => 'MASTER HITORI',
  };

  static int sizeForLevel(int level) => switch (level) {
    >= 1 && <= 3 => 5,
    >= 4 && <= 6 => 6,
    >= 7 && <= 10 => 7,
    >= 11 && <= maximumLevels => 8,
    _ => throw RangeError.range(level, 1, maximumLevels, 'level'),
  };

  static int minimumBlackCellsForLevel(int level) {
    sizeForLevel(level);
    return switch (level) {
      <= 3 => 7,
      <= 6 => 8,
      7 || 8 => 9,
      9 || 10 => 10,
      <= 14 => 10,
      <= 16 => 11,
      17 || 18 => 12,
      _ => 13,
    };
  }

  bool get hasUniqueCertifiedSolution {
    final HitoriSolveResult result = countSolutions(size: size, values: values);
    return result.solutionCount == 1 &&
        !result.exceededNodeLimit &&
        _sameMask(result.firstSolution, solution);
  }

  bool isSolved(List<bool> blackCells) =>
      blackCells.length == size * size &&
      _isValidSolution(size, values, blackCells);

  static Set<String> get _usedSignatures => <String>{
    ..._campaign.values.map((HitoriPuzzle puzzle) => puzzle.signature),
    ..._practice.values.map((HitoriPuzzle puzzle) => puzzle.signature),
  };

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'seed': seed,
    'size': size,
    'values': values,
    'solution': solution,
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) throw FormatException('Invalid hitori bank');
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practice[i + 1] = HitoriPuzzle._(
        level: m['level'] as int,
        seed: m['seed'] as int,
        size: m['size'] as int,
        values: List<int>.from(m['values'] as List),
        solution: List<bool>.from(m['solution'] as List),
      );
    }
  }

  static HitoriPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    for (int next = 1; next <= level; next++) {
      if (_campaign.containsKey(next)) continue;
      _campaign[next] = _generate(next, cycle: 0, used: _usedSignatures);
    }
    return _campaign[level]!;
  }

  static HitoriPuzzle forPracticeBoard(int index) {
    final cached = _practice[index];
    if (cached != null) return cached;
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      forLevel(level);
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      _practice[next] = _generate(level, cycle: next, used: _usedSignatures);
    }
    return _practice[index]!;
  }

  static HitoriPuzzle _generate(
    int level, {
    required int cycle,
    required Set<String> used,
  }) {
    final int size = sizeForLevel(level);
    final int requiredBlack = minimumBlackCellsForLevel(level);
    int zeroSolutions = 0;
    int multipleSolutions = 0;
    int limitedSolutions = 0;
    int tooFewBlack = 0;
    for (int attempt = 0; attempt < 720; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'hitori:$cycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final int transform = random.nextInt(8);
      final List<int> symbols = List<int>.generate(5, (int index) => index + 1)
        ..shuffle(random);
      final List<int> values = List<int>.filled(size * size, 0);
      final List<bool> solution = List<bool>.filled(size * size, false);
      for (int row = 0; row < 5; row++) {
        for (int column = 0; column < 5; column++) {
          final (int transformedRow, int transformedColumn) =
              _transformCoordinate(row, column, transform);
          final int source = row * 5 + column;
          final int target = transformedRow * size + transformedColumn;
          values[target] = symbols[_templateValues[source] - 1];
          solution[target] = _templateBlackCells.contains(source);
        }
      }
      final List<int> extensionSymbols = List<int>.generate(
        size * size - size,
        (int index) => size + index + 1,
      )..shuffle(random);
      int extensionIndex = 0;
      for (int cell = 0; cell < values.length; cell++) {
        if (values[cell] == 0) {
          values[cell] = extensionSymbols[extensionIndex++];
        }
      }
      int blackCount = _templateBlackCells.length;
      for (int extra = blackCount; extra < requiredBlack; extra++) {
        final List<(int, int)> candidates = _forcedBlackCandidates(
          size,
          solution,
        )..shuffle(random);
        bool added = false;
        for (final (int cell, int source) in candidates) {
          final List<int> trialValues = List<int>.of(values)
            ..[cell] = values[source];
          final List<bool> trialSolution = List<bool>.of(solution)
            ..[cell] = true;
          if (!_isValidSolution(size, trialValues, trialSolution)) continue;
          final HitoriSolveResult trial = countSolutions(
            size: size,
            values: trialValues,
            nodeLimit: generationNodeLimit,
          );
          if (trial.solutionCount == 1 &&
              !trial.exceededNodeLimit &&
              _sameMask(trial.firstSolution, trialSolution)) {
            values.setAll(0, trialValues);
            solution.setAll(0, trialSolution);
            blackCount++;
            added = true;
            break;
          }
        }
        if (!added) break;
      }
      final String signature = '$size|${values.join(',')}';
      if (used.contains(signature) || blackCount < requiredBlack) {
        continue;
      }
      final HitoriSolveResult result = countSolutions(
        size: size,
        values: values,
        nodeLimit: generationNodeLimit,
      );
      if (result.exceededNodeLimit) {
        limitedSolutions++;
        continue;
      }
      if (result.solutionCount == 0) {
        zeroSolutions++;
        continue;
      }
      if (result.solutionCount > 1) {
        multipleSolutions++;
        continue;
      }
      if (result.firstSolution == null ||
          !_sameMask(result.firstSolution, solution)) {
        tooFewBlack++;
        continue;
      }
      if (!_isValidSolution(size, values, result.firstSolution!)) {
        continue;
      }
      return HitoriPuzzle._(
        level: level,
        seed: seed,
        size: size,
        values: values,
        solution: result.firstSolution!,
      );
    }
    throw StateError(
      'Could not certify a distinct, unique Hitori board for level $level '
      '(zero: $zeroSolutions, multiple: $multipleSolutions, '
      'limited: $limitedSolutions, sparse: $tooFewBlack).',
    );
  }

  static (int, int) _transformCoordinate(int row, int column, int transform) {
    int nextRow = row;
    int nextColumn = transform >= 4 ? 4 - column : column;
    for (int rotation = 0; rotation < transform % 4; rotation++) {
      final int previousRow = nextRow;
      nextRow = nextColumn;
      nextColumn = 4 - previousRow;
    }
    return (nextRow, nextColumn);
  }

  static List<(int, int)> _forcedBlackCandidates(
    int size,
    List<bool> solution,
  ) {
    final List<(int, int)> candidates = <(int, int)>[];
    for (int cell = 0; cell < solution.length; cell++) {
      if (solution[cell] || _touchesBlack(size, solution, cell)) continue;
      final int row = cell ~/ size;
      final int column = cell % size;
      for (int source = 0; source < solution.length; source++) {
        if (solution[source] ||
            (source ~/ size != row && source % size != column) ||
            !_touchesBlack(size, solution, source)) {
          continue;
        }
        candidates.add((cell, source));
      }
    }
    return candidates;
  }

  static bool _touchesBlack(int size, List<bool> solution, int cell) {
    final int row = cell ~/ size;
    final int column = cell % size;
    return (row > 0 && solution[cell - size]) ||
        (row + 1 < size && solution[cell + size]) ||
        (column > 0 && solution[cell - 1]) ||
        (column + 1 < size && solution[cell + 1]);
  }

  static HitoriSolveResult countSolutions({
    required int size,
    required List<int> values,
    int solutionLimit = 2,
    int nodeLimit = defaultNodeLimit,
  }) {
    if (size < 4 ||
        size > 9 ||
        values.length != size * size ||
        values.any((int value) => value < 1) ||
        solutionLimit < 1 ||
        nodeLimit < 1) {
      throw ArgumentError('Invalid Hitori dimensions, values or limits.');
    }
    final List<List<int>> groups = _duplicateGroups(size, values);
    final List<List<int>> groupsByCell = List<List<int>>.generate(
      size * size,
      (_) => <int>[],
      growable: false,
    );
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (final int cell in groups[groupIndex]) {
        groupsByCell[cell].add(groupIndex);
      }
    }
    final List<List<int>> neighbors = List<List<int>>.generate(size * size, (
      int index,
    ) {
      final int row = index ~/ size;
      final int column = index % size;
      return <int>[
        if (row > 0) index - size,
        if (row + 1 < size) index + size,
        if (column > 0) index - 1,
        if (column + 1 < size) index + 1,
      ];
    }, growable: false);
    final List<int> initial = List<int>.filled(size * size, 0);
    for (int cell = 0; cell < initial.length; cell++) {
      if (groupsByCell[cell].isEmpty) initial[cell] = 1;
    }
    int visitedNodes = 0;
    bool exceededNodeLimit = false;
    final List<List<bool>> firstSolutions = <List<bool>>[];

    void search(List<int> source) {
      if (firstSolutions.length >= solutionLimit || exceededNodeLimit) return;
      if (++visitedNodes > nodeLimit) {
        exceededNodeLimit = true;
        return;
      }
      final List<int> state = List<int>.of(source);
      if (!_propagate(state, groups, neighbors) ||
          !_canStillConnect(size, state, neighbors)) {
        return;
      }
      int selected = -1;
      int selectedScore = -1;
      for (int cell = 0; cell < state.length; cell++) {
        if (state[cell] != 0) continue;
        final int score =
            groupsByCell[cell].length * 10 +
            neighbors[cell].where((int next) => state[next] == 2).length * 3 +
            neighbors[cell].where((int next) => state[next] == 0).length;
        if (score > selectedScore) {
          selected = cell;
          selectedScore = score;
        }
      }
      if (selected < 0) {
        final List<bool> black = state.map((int value) => value == 2).toList();
        if (_isValidSolution(size, values, black)) firstSolutions.add(black);
        return;
      }
      for (final int choice in <int>[1, 2]) {
        final List<int> branch = List<int>.of(state)..[selected] = choice;
        search(branch);
        if (firstSolutions.length >= solutionLimit || exceededNodeLimit) return;
      }
    }

    search(initial);
    return HitoriSolveResult(
      solutionCount: firstSolutions.length,
      firstSolution: firstSolutions.isEmpty ? null : firstSolutions.first,
      alternativeSolution: firstSolutions.length < 2 ? null : firstSolutions[1],
      visitedNodes: visitedNodes,
      exceededNodeLimit: exceededNodeLimit,
    );
  }

  static bool _propagate(
    List<int> state,
    List<List<int>> groups,
    List<List<int>> neighbors,
  ) {
    bool changed;
    do {
      changed = false;
      for (int cell = 0; cell < state.length; cell++) {
        if (state[cell] != 2) continue;
        for (final int next in neighbors[cell]) {
          if (state[next] == 2) return false;
          if (state[next] == 0) {
            state[next] = 1;
            changed = true;
          }
        }
      }
      for (final List<int> group in groups) {
        final int whiteCount = group
            .where((int cell) => state[cell] == 1)
            .length;
        if (whiteCount > 1) return false;
        if (whiteCount == 1) {
          for (final int cell in group) {
            if (state[cell] == 0) {
              state[cell] = 2;
              changed = true;
            }
          }
        }
      }
    } while (changed);
    return true;
  }

  static bool _canStillConnect(
    int size,
    List<int> state,
    List<List<int>> neighbors,
  ) {
    final int start = state.indexWhere((int value) => value == 1);
    if (start < 0) return state.any((int value) => value != 2);
    final Set<int> reached = <int>{start};
    final List<int> queue = <int>[start];
    for (int cursor = 0; cursor < queue.length; cursor++) {
      for (final int next in neighbors[queue[cursor]]) {
        if (state[next] != 2 && reached.add(next)) queue.add(next);
      }
    }
    for (int cell = 0; cell < state.length; cell++) {
      if (state[cell] == 1 && !reached.contains(cell)) return false;
    }
    return true;
  }

  static List<List<int>> _duplicateGroups(int size, List<int> values) {
    final List<List<int>> groups = <List<int>>[];
    for (int row = 0; row < size; row++) {
      final Map<int, List<int>> positions = <int, List<int>>{};
      for (int column = 0; column < size; column++) {
        final int cell = row * size + column;
        positions.putIfAbsent(values[cell], () => <int>[]).add(cell);
      }
      groups.addAll(
        positions.values.where((List<int> cells) => cells.length > 1),
      );
    }
    for (int column = 0; column < size; column++) {
      final Map<int, List<int>> positions = <int, List<int>>{};
      for (int row = 0; row < size; row++) {
        final int cell = row * size + column;
        positions.putIfAbsent(values[cell], () => <int>[]).add(cell);
      }
      groups.addAll(
        positions.values.where((List<int> cells) => cells.length > 1),
      );
    }
    return groups;
  }

  static bool _isValidSolution(int size, List<int> values, List<bool> black) {
    if (black.length != size * size || black.every((bool cell) => cell)) {
      return false;
    }
    for (int row = 0; row < size; row++) {
      final Set<int> visible = <int>{};
      for (int column = 0; column < size; column++) {
        final int cell = row * size + column;
        if (black[cell]) continue;
        if (!visible.add(values[cell])) return false;
      }
    }
    for (int column = 0; column < size; column++) {
      final Set<int> visible = <int>{};
      for (int row = 0; row < size; row++) {
        final int cell = row * size + column;
        if (black[cell]) continue;
        if (!visible.add(values[cell])) return false;
      }
    }
    for (int row = 0; row < size; row++) {
      for (int column = 0; column < size; column++) {
        final int cell = row * size + column;
        if (!black[cell]) continue;
        if (row + 1 < size && black[cell + size]) return false;
        if (column + 1 < size && black[cell + 1]) return false;
      }
    }
    final List<List<int>> neighbors = List<List<int>>.generate(size * size, (
      int index,
    ) {
      final int row = index ~/ size;
      final int column = index % size;
      return <int>[
        if (row > 0) index - size,
        if (row + 1 < size) index + size,
        if (column > 0) index - 1,
        if (column + 1 < size) index + 1,
      ];
    }, growable: false);
    final int start = black.indexWhere((bool cell) => !cell);
    final Set<int> reached = <int>{start};
    final List<int> queue = <int>[start];
    for (int cursor = 0; cursor < queue.length; cursor++) {
      for (final int next in neighbors[queue[cursor]]) {
        if (!black[next] && reached.add(next)) queue.add(next);
      }
    }
    return reached.length == black.where((bool cell) => !cell).length;
  }

  static bool _sameMask(List<bool>? left, List<bool> right) =>
      left != null &&
      left.length == right.length &&
      List<int>.generate(
        left.length,
        (int i) => left[i] == right[i] ? 0 : 1,
      ).every((int difference) => difference == 0);
}
