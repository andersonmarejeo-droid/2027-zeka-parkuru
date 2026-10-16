import 'dart:math' as math;

import '../shared/content_seed.dart';
import '../shared/studio_game_contracts.dart';

enum KenKenOperation { add, multiply, subtract, divide }

class KenKenCage {
  const KenKenCage({
    required this.target,
    required this.operation,
    required this.cells,
  });

  final int target;
  final KenKenOperation? operation;
  final List<int> cells;

  String get operator => switch (operation) {
    KenKenOperation.add => '+',
    KenKenOperation.multiply => '×',
    KenKenOperation.subtract => '−',
    KenKenOperation.divide => '÷',
    null => '',
  };

  String get label => '$target$operator';
}

class KenKenAnalysis {
  const KenKenAnalysis({
    required this.solutionCount,
    required this.solution,
    required this.searchNodes,
  });

  final int solutionCount;
  final List<int>? solution;
  final int searchNodes;
}

class KenKenPuzzle {
  static const int maximumUniqueCases = GameContentPolicy.minimumUniqueRounds;
  static final Map<int, KenKenPuzzle> _cache = <int, KenKenPuzzle>{};

  const KenKenPuzzle({
    required this.level,
    required this.localStage,
    required this.size,
    required this.cages,
    required this.solution,
    required this.searchNodes,
  });

  final int level;
  final int localStage;
  final int size;
  final List<KenKenCage> cages;
  final List<int> solution;
  final int searchNodes;

  int get cellCount => size * size;
  int get singletonCount =>
      cages.where((KenKenCage cage) => cage.cells.length == 1).length;
  int get largestCage => cages.fold<int>(
    1,
    (int maxSize, KenKenCage cage) => math.max(maxSize, cage.cells.length),
  );
  int get advancedOperationCount => cages
      .where(
        (KenKenCage cage) =>
            cage.operation == KenKenOperation.subtract ||
            cage.operation == KenKenOperation.divide,
      )
      .length;

  String get difficultyTier => switch (localStage) {
    <= 2 => 'BAŞLANGIÇ',
    <= 6 => 'USTALAŞMA',
    <= 8 => 'İLERİ',
    _ => 'UZMAN',
  };

  String get boardSignature {
    final List<String> pieces =
        cages
            .map(
              (KenKenCage cage) =>
                  '${(List<int>.from(cage.cells)..sort()).join('.')}:${cage.label}',
            )
            .toList()
          ..sort();
    return '$size|${pieces.join('|')}';
  }

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static int sizeForStage(int stage) => stage <= 2
      ? 4
      : stage <= 5
      ? 5
      : 6;

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'localStage': localStage,
    'size': size,
    'searchNodes': searchNodes,
    'solution': solution,
    'cages': cages.map((c) => [c.target, c.operation?.index, c.cells]).toList(),
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) throw FormatException('Invalid kenken_cube bank');
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _cache[i + 1] = KenKenPuzzle(
        level: m['level'] as int,
        localStage: m['localStage'] as int,
        size: m['size'] as int,
        searchNodes: m['searchNodes'] as int,
        solution: List<int>.from(m['solution'] as List),
        cages: (m['cages'] as List)
            .map(
              (e) => KenKenCage(
                target: e[0] as int,
                operation: e[1] == null
                    ? null
                    : KenKenOperation.values[e[1] as int],
                cells: List<int>.from(e[2] as List),
              ),
            )
            .toList(),
      );
    }
  }

  static KenKenPuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    if (!_cache.containsKey(level)) {
      // A previously unlocked late level must not synchronously generate every
      // earlier board on app launch. Each level has its own deterministic seed;
      // signatures are additionally checked against every board materialized
      // in this session, while the release test proves all 20 campaign boards.
      _cache[level] = _generate(
        level,
        usedSignatures: _cache.values
            .map((KenKenPuzzle puzzle) => puzzle.boardSignature)
            .toSet(),
      );
    }
    return _cache[level]!;
  }

  KenKenAnalysis analyze({List<int>? board, int limit = 2}) => analyzeBoard(
    size,
    cages,
    board ?? List<int>.filled(cellCount, 0),
    limit: limit,
  );

  bool isSolved(List<int> board) {
    if (board.length != cellCount || board.any((int value) => value == 0)) {
      return false;
    }
    final KenKenAnalysis analysis = analyze(board: board, limit: 1);
    return analysis.solutionCount == 1 &&
        analysis.solution!.asMap().entries.every(
          (MapEntry<int, int> entry) => board[entry.key] == entry.value,
        );
  }

  int cageIndexAt(int cell) =>
      cages.indexWhere((KenKenCage cage) => cage.cells.contains(cell));

  static KenKenAnalysis analyzeBoard(
    int size,
    List<KenKenCage> cages,
    List<int> source, {
    int limit = 2,
  }) {
    final int count = size * size;
    if (size < 2 ||
        size > 6 ||
        source.length != count ||
        limit < 1 ||
        source.any((int value) => value < 0 || value > size) ||
        !_cagesFormPartition(size, cages)) {
      return const KenKenAnalysis(
        solutionCount: 0,
        solution: null,
        searchNodes: 0,
      );
    }
    final List<int> board = List<int>.from(source);
    final List<int> cageFor = List<int>.filled(count, -1);
    for (int cageIndex = 0; cageIndex < cages.length; cageIndex++) {
      for (final int cell in cages[cageIndex].cells) {
        cageFor[cell] = cageIndex;
      }
    }
    for (int cell = 0; cell < count; cell++) {
      final int value = board[cell];
      if (value == 0) continue;
      final int row = cell ~/ size;
      final int column = cell % size;
      for (int offset = 0; offset < size; offset++) {
        if (offset != column && board[row * size + offset] == value) {
          return const KenKenAnalysis(
            solutionCount: 0,
            solution: null,
            searchNodes: 0,
          );
        }
        if (offset != row && board[offset * size + column] == value) {
          return const KenKenAnalysis(
            solutionCount: 0,
            solution: null,
            searchNodes: 0,
          );
        }
      }
    }

    List<int>? firstSolution;
    int solutions = 0;
    int nodes = 0;
    bool cageCanStillWork(KenKenCage cage) {
      final List<int> values = cage.cells
          .map((int cell) => board[cell])
          .toList();
      final List<int> filled = values.where((int value) => value != 0).toList();
      final int remaining = values.length - filled.length;
      final KenKenOperation? operation = cage.operation;
      if (operation == null) {
        return filled.isEmpty || filled.single == cage.target;
      }
      switch (operation) {
        case KenKenOperation.add:
          final int sum = filled.fold<int>(0, (int a, int b) => a + b);
          return sum + remaining <= cage.target &&
              sum + remaining * size >= cage.target;
        case KenKenOperation.multiply:
          final int product = filled.fold<int>(1, (int a, int b) => a * b);
          return product <= cage.target && cage.target % product == 0;
        case KenKenOperation.subtract:
        case KenKenOperation.divide:
          if (values.length != 2) return false;
          if (remaining == 0) return _evaluate(cage, values);
          if (remaining == 2) {
            return operation == KenKenOperation.subtract
                ? cage.target >= 1 && cage.target < size
                : cage.target >= 1 && cage.target <= size;
          }
          final int fixed = filled.single;
          for (int candidate = 1; candidate <= size; candidate++) {
            final List<int> pair = values[0] == 0
                ? <int>[candidate, fixed]
                : <int>[fixed, candidate];
            if (_evaluate(cage, pair)) return true;
          }
          return false;
      }
    }

    Set<int> candidates(int cell) {
      final int row = cell ~/ size;
      final int column = cell % size;
      final Set<int> used = <int>{};
      for (int offset = 0; offset < size; offset++) {
        used.add(board[row * size + offset]);
        used.add(board[offset * size + column]);
      }
      return <int>{
        for (int value = 1; value <= size; value++)
          if (!used.contains(value)) value,
      };
    }

    void search() {
      if (solutions >= limit) return;
      nodes++;
      int selected = -1;
      Set<int>? best;
      for (int cell = 0; cell < count; cell++) {
        if (board[cell] != 0) continue;
        final Set<int> options = candidates(cell);
        if (options.isEmpty) return;
        if (best == null || options.length < best.length) {
          selected = cell;
          best = options;
          if (options.length == 1) break;
        }
      }
      if (selected == -1) {
        if (cages.every(
          (KenKenCage cage) => _evaluate(
            cage,
            cage.cells.map((int cell) => board[cell]).toList(),
          ),
        )) {
          solutions++;
          firstSolution ??= List<int>.unmodifiable(board);
        }
        return;
      }
      for (final int value in best!) {
        board[selected] = value;
        if (cageCanStillWork(cages[cageFor[selected]])) search();
        board[selected] = 0;
        if (solutions >= limit) return;
      }
    }

    for (final KenKenCage cage in cages) {
      if (!cageCanStillWork(cage)) {
        return const KenKenAnalysis(
          solutionCount: 0,
          solution: null,
          searchNodes: 0,
        );
      }
    }
    search();
    return KenKenAnalysis(
      solutionCount: solutions,
      solution: firstSolution,
      searchNodes: nodes,
    );
  }

  static bool _cagesFormPartition(int size, List<KenKenCage> cages) {
    if (cages.isEmpty) return false;
    final Set<int> cells = <int>{};
    for (final KenKenCage cage in cages) {
      if (cage.cells.isEmpty ||
          cage.cells.any((int cell) => cell < 0 || cell >= size * size)) {
        return false;
      }
      for (final int cell in cage.cells) {
        if (!cells.add(cell)) return false;
      }
      if (cage.cells.length == 1 && cage.operation != null) return false;
      if ((cage.operation == KenKenOperation.subtract ||
              cage.operation == KenKenOperation.divide) &&
          cage.cells.length != 2) {
        return false;
      }
    }
    return cells.length == size * size;
  }

  static bool _evaluate(KenKenCage cage, List<int> values) {
    final KenKenOperation? operation = cage.operation;
    if (operation == null) {
      return values.length == 1 && values.single == cage.target;
    }
    switch (operation) {
      case KenKenOperation.add:
        return values.fold<int>(0, (int a, int b) => a + b) == cage.target;
      case KenKenOperation.multiply:
        return values.fold<int>(1, (int a, int b) => a * b) == cage.target;
      case KenKenOperation.subtract:
        return values.length == 2 &&
            (values[0] - values[1]).abs() == cage.target;
      case KenKenOperation.divide:
        if (values.length != 2) return false;
        final int high = math.max(values[0], values[1]);
        final int low = math.min(values[0], values[1]);
        return high % low == 0 && high ~/ low == cage.target;
    }
  }

  static KenKenPuzzle _generate(
    int level, {
    required Set<String> usedSignatures,
  }) {
    final int stage = stageForLevel(level);
    final int size = sizeForStage(stage);
    for (int attempt = 0; attempt < 60000; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'kenken_cube',
        level: level,
        attempt: attempt,
      );
      final List<int> solved = _randomLatinSquare(size, random);
      final List<KenKenCage> cages = _partition(size, solved, stage, random);
      if (!_meetsDifficulty(cages, stage, size)) continue;
      final KenKenAnalysis analysis = analyzeBoard(
        size,
        cages,
        List<int>.filled(size * size, 0),
      );
      if (analysis.solutionCount != 1 || analysis.solution == null) continue;
      final KenKenPuzzle puzzle = KenKenPuzzle(
        level: level,
        localStage: stage,
        size: size,
        cages: List<KenKenCage>.unmodifiable(cages),
        solution: analysis.solution!,
        searchNodes: analysis.searchNodes,
      );
      if (usedSignatures.contains(puzzle.boardSignature)) continue;
      return puzzle;
    }
    throw StateError(
      'Could not generate a unique KenKen board for level $level.',
    );
  }

  static bool _meetsDifficulty(List<KenKenCage> cages, int stage, int size) {
    final int singletonCount = cages
        .where((KenKenCage cage) => cage.cells.length == 1)
        .length;
    final int multiCount = cages.length - singletonCount;
    final int largest = cages.fold<int>(
      1,
      (int m, KenKenCage c) => math.max(m, c.cells.length),
    );
    if (stage <= 2) return true;
    if (stage <= 5) return largest >= 2 && multiCount >= size;
    final int maxSingletons = switch (stage) {
      6 => 14,
      7 => 11,
      8 => 9,
      9 => 7,
      _ => 6,
    };
    final int minLargest = stage <= 7
        ? 3
        : stage <= 9
        ? 4
        : 5;
    final int minMulti = stage <= 7
        ? 9
        : stage <= 9
        ? 11
        : 12;
    return singletonCount <= maxSingletons &&
        largest >= minLargest &&
        multiCount >= minMulti;
  }

  static List<KenKenCage> _partition(
    int size,
    List<int> solution,
    int stage,
    math.Random random,
  ) {
    final int maximum = stage <= 2
        ? 2
        : stage <= 4
        ? 3
        : stage <= 7
        ? 4
        : 5;
    final Set<int> remaining = <int>{
      for (int cell = 0; cell < size * size; cell++) cell,
    };
    final List<int> starts = List<int>.generate(size * size, (int i) => i)
      ..shuffle(random);
    final List<KenKenCage> cages = <KenKenCage>[];
    for (final int start in starts) {
      if (!remaining.contains(start)) continue;
      final int requested = _pickCageSize(maximum, stage, random);
      final List<int> cells = <int>[start];
      remaining.remove(start);
      while (cells.length < requested) {
        final List<int> frontier = <int>{
          for (final int cell in cells)
            ..._neighbors(cell, size).where(remaining.contains),
        }.toList()..shuffle(random);
        if (frontier.isEmpty) break;
        cells.add(frontier.first);
        remaining.remove(frontier.first);
      }
      final List<int> values = cells.map((int cell) => solution[cell]).toList();
      final KenKenOperation? operation = _pickOperation(values, random);
      final int target = _target(values, operation);
      cages.add(
        KenKenCage(
          target: target,
          operation: operation,
          cells: List<int>.unmodifiable(cells),
        ),
      );
    }
    return cages;
  }

  static int _pickCageSize(int maximum, int stage, math.Random random) {
    final double roll = random.nextDouble();
    if (stage >= 8) {
      if (roll < .08) return 1;
      if (roll < .29) return 2;
      if (roll < .61) return 3;
      if (roll < .85) return 4;
      return maximum;
    }
    if (stage >= 6) {
      if (roll < .16) return 1;
      if (roll < .48) return 2;
      if (roll < .77) return 3;
      return maximum;
    }
    if (roll < .25) return 1;
    if (roll < .72) return 2;
    return maximum;
  }

  static Set<int> _neighbors(int cell, int size) {
    final int row = cell ~/ size;
    final int column = cell % size;
    return <int>{
      if (row > 0) cell - size,
      if (row < size - 1) cell + size,
      if (column > 0) cell - 1,
      if (column < size - 1) cell + 1,
    };
  }

  static KenKenOperation? _pickOperation(List<int> values, math.Random random) {
    if (values.length == 1) return null;
    if (values.length > 2) {
      return random.nextBool() ? KenKenOperation.add : KenKenOperation.multiply;
    }
    final int a = values[0];
    final int b = values[1];
    final List<KenKenOperation> available = <KenKenOperation>[
      KenKenOperation.add,
      KenKenOperation.multiply,
      if (a != b) KenKenOperation.subtract,
      if (math.max(a, b) % math.min(a, b) == 0) KenKenOperation.divide,
    ];
    return available[random.nextInt(available.length)];
  }

  static int _target(List<int> values, KenKenOperation? operation) {
    if (operation == null) return values.single;
    switch (operation) {
      case KenKenOperation.add:
        return values.fold<int>(0, (int a, int b) => a + b);
      case KenKenOperation.multiply:
        return values.fold<int>(1, (int a, int b) => a * b);
      case KenKenOperation.subtract:
        return (values[0] - values[1]).abs();
      case KenKenOperation.divide:
        return math.max(values[0], values[1]) ~/ math.min(values[0], values[1]);
    }
  }

  static List<int> _randomLatinSquare(int size, math.Random random) {
    final List<int> rows = List<int>.generate(size, (int i) => i)
      ..shuffle(random);
    final List<int> columns = List<int>.generate(size, (int i) => i)
      ..shuffle(random);
    final List<int> symbols = List<int>.generate(size, (int i) => i + 1)
      ..shuffle(random);
    return <int>[
      for (final int row in rows)
        for (final int column in columns) symbols[(row + column) % size],
    ];
  }
}
