import 'dart:math' as math;

import '../shared/content_seed.dart';

class SkyscrapersSolveResult {
  const SkyscrapersSolveResult({
    required this.solutionCount,
    required this.firstSolution,
    required this.visitedNodes,
    required this.exceededNodeLimit,
  });

  final int solutionCount;
  final List<int>? firstSolution;
  final int visitedNodes;
  final bool exceededNodeLimit;
}

class SkyscrapersPuzzle {
  SkyscrapersPuzzle._({
    required this.level,
    required this.seed,
    required this.size,
    required List<int> solution,
    required List<int> top,
    required List<int> bottom,
    required List<int> left,
    required List<int> right,
  }) : solution = List<int>.unmodifiable(solution),
       top = List<int>.unmodifiable(top),
       bottom = List<int>.unmodifiable(bottom),
       left = List<int>.unmodifiable(left),
       right = List<int>.unmodifiable(right);

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static const int defaultNodeLimit = 500000;
  static const int generationNodeLimit = 50000;
  static final Map<int, SkyscrapersPuzzle> _campaign =
      <int, SkyscrapersPuzzle>{};
  static final Map<int, SkyscrapersPuzzle> _practice =
      <int, SkyscrapersPuzzle>{};

  final int level;
  final int seed;
  final int size;
  final List<int> solution;
  final List<int> top;
  final List<int> bottom;
  final List<int> left;
  final List<int> right;

  String get signature =>
      '$size|${top.join()}|${bottom.join()}|${left.join()}|${right.join()}';
  int get clueCount => <int>[
    ...top,
    ...bottom,
    ...left,
    ...right,
  ].where((int clue) => clue > 0).length;
  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP READING',
    _ => 'MASTER SKYLINE',
  };

  static int sizeForLevel(int level) => switch (level) {
    >= 1 && <= 3 => 4,
    >= 4 && <= 6 => 5,
    >= 7 && <= 10 => 6,
    >= 11 && <= maximumLevels => 7,
    _ => throw RangeError.range(level, 1, maximumLevels, 'level'),
  };

  static int minimumClueCountForLevel(int level) {
    final int size = sizeForLevel(level);
    final int omitted = switch (level) {
      <= 3 => 0,
      <= 6 => 1,
      <= 8 => 2,
      <= 10 => 3,
      <= 13 => 4,
      <= 16 => 5,
      <= 18 => 6,
      _ => 7,
    };
    return size * 4 - omitted;
  }

  bool get hasUniqueCertifiedSolution {
    final SkyscrapersSolveResult result = countSolutions(
      size: size,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
    );
    return result.solutionCount == 1 &&
        !result.exceededNodeLimit &&
        _sameGrid(result.firstSolution, solution);
  }

  bool isSolved(List<int> values) =>
      values.length == size * size &&
      values.every((int height) => height >= 1 && height <= size) &&
      _isLatinSquare(values, size) &&
      _matchesAllClues(values, size, top, bottom, left, right);

  static Set<String> get _usedSignatures => <String>{
    ..._campaign.values.map((SkyscrapersPuzzle puzzle) => puzzle.signature),
    ..._practice.values.map((SkyscrapersPuzzle puzzle) => puzzle.signature),
  };

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'seed': seed,
    'size': size,
    'solution': solution,
    'top': top,
    'bottom': bottom,
    'left': left,
    'right': right,
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) throw FormatException('Invalid skyscrapers bank');
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practice[i + 1] = SkyscrapersPuzzle._(
        level: m['level'] as int,
        seed: m['seed'] as int,
        size: m['size'] as int,
        solution: List<int>.from(m['solution'] as List),
        top: List<int>.from(m['top'] as List),
        bottom: List<int>.from(m['bottom'] as List),
        left: List<int>.from(m['left'] as List),
        right: List<int>.from(m['right'] as List),
      );
    }
  }

  static SkyscrapersPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    for (int next = 1; next <= level; next++) {
      if (_campaign.containsKey(next)) continue;
      _campaign[next] = _generate(next, cycle: 0, used: _usedSignatures);
    }
    return _campaign[level]!;
  }

  static SkyscrapersPuzzle forPracticeBoard(int index) {
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

  static SkyscrapersPuzzle _generate(
    int level, {
    required int cycle,
    required Set<String> used,
  }) {
    final int size = sizeForLevel(level);
    final int minimumClues = minimumClueCountForLevel(level);
    for (int attempt = 0; attempt < 128; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'skyscrapers:$cycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final List<int> solution = _latinSquare(size, random);
      final _ClueSet full = _cluesFor(solution, size);
      final SkyscrapersSolveResult fullCertification = countSolutions(
        size: size,
        top: full.top,
        bottom: full.bottom,
        left: full.left,
        right: full.right,
        nodeLimit: generationNodeLimit,
      );
      if (fullCertification.solutionCount != 1 ||
          fullCertification.exceededNodeLimit ||
          !_sameGrid(fullCertification.firstSolution, solution)) {
        continue;
      }
      final List<(int, int)> clueSlots = <(int, int)>[
        for (int index = 0; index < size; index++) ...<(int, int)>[
          (0, index),
          (1, index),
          (2, index),
          (3, index),
        ],
      ]..shuffle(random);
      _ClueSet clues = full;
      for (final (int edge, int index) in clueSlots) {
        if (clues.count <= minimumClues) break;
        final _ClueSet candidate = clues.without(edge, index);
        final SkyscrapersSolveResult result = countSolutions(
          size: size,
          top: candidate.top,
          bottom: candidate.bottom,
          left: candidate.left,
          right: candidate.right,
          nodeLimit: 10000,
        );
        if (result.solutionCount == 1 && !result.exceededNodeLimit) {
          clues = candidate;
        }
      }
      if (clues.count < minimumClues) continue;
      final SkyscrapersPuzzle puzzle = SkyscrapersPuzzle._(
        level: level,
        seed: seed,
        size: size,
        solution: solution,
        top: clues.top,
        bottom: clues.bottom,
        left: clues.left,
        right: clues.right,
      );
      if (!used.contains(puzzle.signature) &&
          puzzle.hasUniqueCertifiedSolution) {
        return puzzle;
      }
    }
    throw StateError(
      'Could not certify a distinct, unique skyline for level $level.',
    );
  }

  static SkyscrapersSolveResult countSolutions({
    required int size,
    required List<int> top,
    required List<int> bottom,
    required List<int> left,
    required List<int> right,
    int solutionLimit = 2,
    int nodeLimit = defaultNodeLimit,
  }) {
    if (size < 4 ||
        size > 8 ||
        <List<int>>[top, bottom, left, right].any(
          (List<int> clues) =>
              clues.length != size ||
              clues.any((int clue) => clue < 0 || clue > size),
        ) ||
        solutionLimit < 1 ||
        nodeLimit < 1) {
      throw ArgumentError('Invalid Skyscrapers solver dimensions or limits.');
    }
    final List<List<List<int>>> rows = <List<List<int>>>[
      for (int row = 0; row < size; row++)
        _rowOptions(size, left[row], right[row]),
    ];
    if (rows.any((List<List<int>> options) => options.isEmpty)) {
      return const SkyscrapersSolveResult(
        solutionCount: 0,
        firstSolution: null,
        visitedNodes: 0,
        exceededNodeLimit: false,
      );
    }

    final List<List<Set<int>>> columnPrefixes = <List<Set<int>>>[
      for (int column = 0; column < size; column++)
        _columnPrefixes(size, top[column], bottom[column]),
    ];
    if (columnPrefixes.any((List<Set<int>> prefixes) => prefixes[1].isEmpty)) {
      return const SkyscrapersSolveResult(
        solutionCount: 0,
        firstSolution: null,
        visitedNodes: 0,
        exceededNodeLimit: false,
      );
    }
    final List<int> values = List<int>.filled(size * size, 0);
    final List<int> columnCodes = List<int>.filled(size, 0);
    int solutionCount = 0;
    int visitedNodes = 0;
    bool exceededNodeLimit = false;
    List<int>? firstSolution;

    void search(int row) {
      if (solutionCount >= solutionLimit || exceededNodeLimit) return;
      if (row == size) {
        solutionCount++;
        firstSolution ??= List<int>.of(values);
        return;
      }

      for (final List<int> option in rows[row]) {
        if (visitedNodes >= nodeLimit) {
          exceededNodeLimit = true;
          return;
        }
        visitedNodes++;
        final List<int> previousCodes = List<int>.of(columnCodes);
        bool columnsAllow = true;
        for (int column = 0; column < size; column++) {
          final int code = columnCodes[column] * (size + 1) + option[column];
          if (!columnPrefixes[column][row + 1].contains(code)) {
            columnsAllow = false;
            break;
          }
          columnCodes[column] = code;
          values[row * size + column] = option[column];
        }
        if (columnsAllow) search(row + 1);

        for (int column = 0; column < size; column++) {
          values[row * size + column] = 0;
          columnCodes[column] = previousCodes[column];
        }
        if (solutionCount >= solutionLimit || exceededNodeLimit) return;
      }
    }

    search(0);
    return SkyscrapersSolveResult(
      solutionCount: solutionCount,
      firstSolution: firstSolution == null
          ? null
          : List<int>.unmodifiable(firstSolution!),
      visitedNodes: visitedNodes,
      exceededNodeLimit: exceededNodeLimit,
    );
  }

  static List<List<int>> _rowOptions(int size, int fromLeft, int fromRight) =>
      _rowOptionCache.putIfAbsent((size, fromLeft, fromRight), () {
        final List<List<int>> options = _permutationsFor(size)
            .where(
              (List<int> row) =>
                  (fromLeft == 0 || _visible(row) == fromLeft) &&
                  (fromRight == 0 ||
                      _visible(row.reversed.toList()) == fromRight),
            )
            .toList(growable: false);
        return List<List<int>>.unmodifiable(options);
      });

  static final Map<(int, int, int), List<List<int>>> _rowOptionCache =
      <(int, int, int), List<List<int>>>{};
  static final Map<(int, int, int), List<Set<int>>> _columnPrefixCache =
      <(int, int, int), List<Set<int>>>{};
  static final Map<int, List<List<int>>> _permutationCache =
      <int, List<List<int>>>{};

  static List<Set<int>> _columnPrefixes(
    int size,
    int fromTop,
    int fromBottom,
  ) => _columnPrefixCache.putIfAbsent((size, fromTop, fromBottom), () {
    final List<Set<int>> prefixes = List<Set<int>>.generate(
      size + 1,
      (_) => <int>{},
      growable: false,
    );
    for (final List<int> column in _permutationsFor(size)) {
      if ((fromTop > 0 && _visible(column) != fromTop) ||
          (fromBottom > 0 &&
              _visible(column.reversed.toList()) != fromBottom)) {
        continue;
      }
      int code = 0;
      for (int depth = 1; depth <= size; depth++) {
        code = code * (size + 1) + column[depth - 1];
        prefixes[depth].add(code);
      }
    }
    return List<Set<int>>.unmodifiable(
      prefixes.map((Set<int> prefix) => Set<int>.unmodifiable(prefix)),
    );
  });

  static List<List<int>> _permutationsFor(int size) =>
      _permutationCache.putIfAbsent(size, () {
        final List<List<int>> output = <List<int>>[];
        final List<int> prefix = <int>[];
        final List<bool> used = List<bool>.filled(size + 1, false);
        void build() {
          if (prefix.length == size) {
            output.add(List<int>.unmodifiable(prefix));
            return;
          }
          for (int height = 1; height <= size; height++) {
            if (used[height]) continue;
            used[height] = true;
            prefix.add(height);
            build();
            prefix.removeLast();
            used[height] = false;
          }
        }

        build();
        return List<List<int>>.unmodifiable(output);
      });

  static List<int> _latinSquare(int size, math.Random random) {
    if (size >= 7) {
      final int rotation = random.nextInt(4);
      final bool mirror = random.nextBool();
      return <int>[
        for (int row = 0; row < size; row++)
          for (int column = 0; column < size; column++)
            _cyclicHeight(row, column, size, rotation, mirror),
      ];
    }
    final List<int> rows = List<int>.generate(size, (int index) => index)
      ..shuffle(random);
    final List<int> columns = List<int>.generate(size, (int index) => index)
      ..shuffle(random);
    final List<int> symbols = List<int>.generate(size, (int index) => index + 1)
      ..shuffle(random);
    return <int>[
      for (final int row in rows)
        for (final int column in columns) symbols[(row + column) % size],
    ];
  }

  static int _cyclicHeight(
    int row,
    int column,
    int size,
    int rotation,
    bool mirror,
  ) {
    int sourceRow = row;
    int sourceColumn = mirror ? size - 1 - column : column;
    for (int turn = 0; turn < rotation; turn++) {
      final int previousRow = sourceRow;
      sourceRow = sourceColumn;
      sourceColumn = size - 1 - previousRow;
    }
    return (sourceRow + sourceColumn) % size + 1;
  }

  static _ClueSet _cluesFor(List<int> grid, int size) {
    final List<int> top = List<int>.filled(size, 0);
    final List<int> bottom = List<int>.filled(size, 0);
    final List<int> left = List<int>.filled(size, 0);
    final List<int> right = List<int>.filled(size, 0);
    for (int index = 0; index < size; index++) {
      top[index] = _visible(<int>[
        for (int row = 0; row < size; row++) grid[row * size + index],
      ]);
      bottom[index] = _visible(<int>[
        for (int row = size - 1; row >= 0; row--) grid[row * size + index],
      ]);
      left[index] = _visible(grid.skip(index * size).take(size).toList());
      right[index] = _visible(
        grid.skip(index * size).take(size).toList().reversed.toList(),
      );
    }
    return _ClueSet(top: top, bottom: bottom, left: left, right: right);
  }

  static int _visible(Iterable<int> line) {
    int maximum = 0;
    int count = 0;
    for (final int height in line) {
      if (height <= maximum) continue;
      maximum = height;
      count++;
    }
    return count;
  }

  static bool _isLatinSquare(List<int> grid, int size) {
    if (grid.length != size * size) return false;
    final int expected = (1 << (size + 1)) - 2;
    for (int row = 0; row < size; row++) {
      int rowMask = 0;
      int columnMask = 0;
      for (int index = 0; index < size; index++) {
        rowMask |= 1 << grid[row * size + index];
        columnMask |= 1 << grid[index * size + row];
      }
      if (rowMask != expected || columnMask != expected) return false;
    }
    return true;
  }

  static bool _matchesAllClues(
    List<int> grid,
    int size,
    List<int> top,
    List<int> bottom,
    List<int> left,
    List<int> right,
  ) {
    for (int index = 0; index < size; index++) {
      final List<int> row = grid.skip(index * size).take(size).toList();
      final List<int> column = <int>[
        for (int rowIndex = 0; rowIndex < size; rowIndex++)
          grid[rowIndex * size + index],
      ];
      if ((left[index] > 0 && _visible(row) != left[index]) ||
          (right[index] > 0 && _visible(row.reversed) != right[index]) ||
          (top[index] > 0 && _visible(column) != top[index]) ||
          (bottom[index] > 0 && _visible(column.reversed) != bottom[index])) {
        return false;
      }
    }
    return true;
  }

  static bool _sameGrid(List<int>? first, List<int> second) =>
      first != null &&
      first.length == second.length &&
      List<bool>.generate(
        first.length,
        (int index) => first[index] == second[index],
      ).every((bool same) => same);
}

class _ClueSet {
  _ClueSet({
    required List<int> top,
    required List<int> bottom,
    required List<int> left,
    required List<int> right,
  }) : top = List<int>.unmodifiable(top),
       bottom = List<int>.unmodifiable(bottom),
       left = List<int>.unmodifiable(left),
       right = List<int>.unmodifiable(right);

  final List<int> top;
  final List<int> bottom;
  final List<int> left;
  final List<int> right;
  int get count => <int>[
    ...top,
    ...bottom,
    ...left,
    ...right,
  ].where((int clue) => clue > 0).length;

  _ClueSet without(int edge, int index) {
    final List<List<int>> values = <List<int>>[
      List<int>.of(top),
      List<int>.of(bottom),
      List<int>.of(left),
      List<int>.of(right),
    ];
    values[edge][index] = 0;
    return _ClueSet(
      top: values[0],
      bottom: values[1],
      left: values[2],
      right: values[3],
    );
  }
}
