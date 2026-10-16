import 'dart:collection';
import 'dart:math' as math;

import '../shared/content_seed.dart';

class IslandSeaAnalysis {
  const IslandSeaAnalysis({
    required this.solutionCount,
    required this.solution,
    required this.searchNodes,
    required this.complete,
  });

  final int solutionCount;
  final List<int>? solution;
  final int searchNodes;
  final bool complete;
}

/// Nurikabe puzzle data and a capped exact island-placement solver.
class IslandSeaPuzzle {
  IslandSeaPuzzle._({
    required this.level,
    required this.seed,
    required this.size,
    required List<int> clues,
    required List<int> solution,
    required this.searchNodes,
    required this.islandCount,
  }) : clues = List<int>.unmodifiable(clues),
       solution = List<int>.unmodifiable(solution);

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static const int island = 1;
  static const int sea = 2;
  static const int unknown = 0;

  static final Map<int, IslandSeaPuzzle> _campaign = <int, IslandSeaPuzzle>{};
  static final Map<int, IslandSeaPuzzle> _practice = <int, IslandSeaPuzzle>{};

  final int level;
  final int seed;
  final int size;
  final List<int> clues;
  final List<int> solution;
  final int searchNodes;
  final int islandCount;

  int get cellCount => size * size;
  int get seaCount => solution.where((int cell) => cell == sea).length;
  int get landCount => cellCount - seaCount;
  int get localStage => ((level - 1) % 10) + 1;
  String get signature => '$size:${clues.join(',')}';

  String get difficultyTier => switch (localStage) {
    <= 3 => 'FOUNDATION',
    <= 6 => 'MASTERY',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    _ => 'MASTER NURIKABE',
  };

  static int boardSizeForLevel(int level) => switch (level) {
    <= 4 => 5,
    <= 8 => 6,
    <= 12 => 7,
    _ => 8,
  };

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'seed': seed,
    'size': size,
    'searchNodes': searchNodes,
    'islandCount': islandCount,
    'clues': clues,
    'solution': solution,
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) throw FormatException('Invalid island_sea bank');
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practice[i + 1] = IslandSeaPuzzle._(
        level: m['level'] as int,
        seed: m['seed'] as int,
        size: m['size'] as int,
        searchNodes: m['searchNodes'] as int,
        islandCount: m['islandCount'] as int,
        clues: List<int>.from(m['clues'] as List),
        solution: List<int>.from(m['solution'] as List),
      );
    }
  }

  static IslandSeaPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    for (int nextLevel = 1; nextLevel <= level; nextLevel++) {
      if (_campaign.containsKey(nextLevel)) continue;
      _campaign[nextLevel] = _generate(
        nextLevel,
        contentCycle: 0,
        usedSignatures: _usedSignatures,
      );
    }
    return _campaign[level]!;
  }

  static IslandSeaPuzzle forPracticeBoard(int index) {
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
      _practice[next] = _generate(
        level,
        contentCycle: next,
        usedSignatures: _usedSignatures,
      );
    }
    return _practice[index]!;
  }

  static Set<String> get _usedSignatures => <String>{
    ..._campaign.values.map((IslandSeaPuzzle puzzle) => puzzle.signature),
    ..._practice.values.map((IslandSeaPuzzle puzzle) => puzzle.signature),
  };

  bool isSolved(List<int> board) {
    if (board.length != cellCount || board.contains(unknown)) return false;
    for (int cell = 0; cell < cellCount; cell++) {
      if (clues[cell] != 0 && board[cell] != island) return false;
    }
    return isCorrect(board);
  }

  bool isCorrect(List<int> board) =>
      board.length == cellCount &&
      board.every((int value) => value == island || value == sea) &&
      _sameBoard(board, solution) &&
      _obeysBoardRules(size, board);

  List<int>? hintCell(List<int> board) {
    if (board.length != cellCount) return null;
    for (int index = 0; index < cellCount; index++) {
      if (clues[index] == 0 && board[index] != solution[index]) {
        return <int>[index, solution[index]];
      }
    }
    return null;
  }

  IslandSeaAnalysis analyze({int limit = 2, int nodeBudget = 50000}) =>
      analyzePuzzle(
        size: size,
        clues: clues,
        limit: limit,
        nodeBudget: nodeBudget,
      );

  static IslandSeaAnalysis analyzePuzzle({
    required int size,
    required List<int> clues,
    int limit = 2,
    int nodeBudget = 50000,
  }) {
    if (size < 3 || clues.length != size * size || limit < 1) {
      return const IslandSeaAnalysis(
        solutionCount: 0,
        solution: null,
        searchNodes: 0,
        complete: true,
      );
    }
    final List<int> clueCells = <int>[
      for (int cell = 0; cell < clues.length; cell++)
        if (clues[cell] > 0) cell,
    ];
    if (clueCells.isEmpty || clues.any((int clue) => clue < 0 || clue > 16)) {
      return const IslandSeaAnalysis(
        solutionCount: 0,
        solution: null,
        searchNodes: 0,
        complete: true,
      );
    }
    for (final int clueCell in clueCells) {
      if (clues[clueCell] < 1 || clues[clueCell] > size * size) {
        return const IslandSeaAnalysis(
          solutionCount: 0,
          solution: null,
          searchNodes: 0,
          complete: true,
        );
      }
      for (final int neighbor in _neighbors8(size, clueCell)) {
        if (neighbor != clueCell && clues[neighbor] > 0) {
          return const IslandSeaAnalysis(
            solutionCount: 0,
            solution: null,
            searchNodes: 0,
            complete: true,
          );
        }
      }
    }

    final List<_IslandClue> islands = <_IslandClue>[
      for (final int cell in clueCells)
        _IslandClue(cell: cell, size: clues[cell]),
    ];
    for (final _IslandClue clue in islands) {
      clue.placements = _islandPlacements(
        size: size,
        clueCell: clue.cell,
        islandSize: clue.size,
        clueCells: clueCells.toSet(),
      );
      if (clue.placements.isEmpty) {
        return const IslandSeaAnalysis(
          solutionCount: 0,
          solution: null,
          searchNodes: 0,
          complete: true,
        );
      }
    }
    islands.sort(
      (_IslandClue a, _IslandClue b) =>
          a.placements.length.compareTo(b.placements.length),
    );

    int solutions = 0;
    int nodes = 0;
    bool complete = true;
    List<int>? firstSolution;
    final List<Set<int>> chosen = <Set<int>>[];
    final Set<int> occupied = <int>{};
    final Set<int> blocked = <int>{};

    void visit(int index) {
      if (solutions >= limit) return;
      if (nodes >= nodeBudget) {
        complete = false;
        return;
      }
      nodes++;
      if (index == islands.length) {
        final List<int> board = List<int>.generate(
          size * size,
          (int cell) => occupied.contains(cell) ? island : sea,
          growable: false,
        );
        if (_obeysBoardRules(size, board)) {
          solutions++;
          firstSolution ??= board;
        }
        return;
      }
      final _IslandClue clue = islands[index];
      for (final Set<int> placement in clue.placements) {
        if (placement.any(blocked.contains)) continue;
        final Set<int> halo = <int>{
          for (final int cell in placement) ..._neighbors8(size, cell),
          ...placement,
        };
        if (halo.any(occupied.contains)) continue;
        occupied.addAll(placement);
        blocked.addAll(halo);
        chosen.add(placement);
        visit(index + 1);
        chosen.removeLast();
        occupied.removeAll(placement);
        blocked.clear();
        for (final Set<int> selected in chosen) {
          blocked.addAll(selected);
          for (final int cell in selected) {
            blocked.addAll(_neighbors8(size, cell));
          }
        }
        if (solutions >= limit || !complete) return;
      }
    }

    visit(0);
    return IslandSeaAnalysis(
      solutionCount: solutions,
      solution: firstSolution,
      searchNodes: nodes,
      complete: complete,
    );
  }

  static IslandSeaPuzzle _generate(
    int level, {
    required int contentCycle,
    required Set<String> usedSignatures,
  }) {
    final int size = boardSizeForLevel(level);
    final int stage = stageForLevel(level);
    int legalLayouts = 0;
    int zeroSolution = 0;
    int multipleSolutions = 0;
    int proofTimeout = 0;
    for (int attempt = 0; attempt < 3000; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'island_sea:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final ({List<int> clues, List<int> board, int islands})? layout =
          _stripeLayout(size: size, stage: stage, random: random);
      if (layout == null || !_obeysBoardRules(size, layout.board)) continue;
      legalLayouts++;
      final List<int> clues = layout.clues;
      final String signature = '$size:${clues.join(',')}';
      if (usedSignatures.contains(signature)) continue;
      final IslandSeaAnalysis proof = analyzePuzzle(
        size: size,
        clues: clues,
        limit: 2,
        nodeBudget: 14000,
      );
      if (!proof.complete) proofTimeout++;
      if (proof.complete && proof.solutionCount == 0) zeroSolution++;
      if (proof.complete && proof.solutionCount > 1) multipleSolutions++;
      if (!proof.complete ||
          proof.solutionCount != 1 ||
          proof.solution == null) {
        continue;
      }
      return IslandSeaPuzzle._(
        level: level,
        seed: seed,
        size: size,
        clues: clues,
        solution: proof.solution!,
        searchNodes: proof.searchNodes,
        islandCount: layout.islands,
      );
    }
    throw StateError(
      'Could not certify a unique island/sea puzzle at $level '
      '(legal layouts: $legalLayouts; no solution: $zeroSolution; '
      'multiple: $multipleSolutions; timeout: $proofTimeout).',
    );
  }

  static ({List<int> clues, List<int> board, int islands})? _stripeLayout({
    required int size,
    required int stage,
    required math.Random random,
  }) {
    final bool vertical = random.nextBool();
    final List<int> board = List<int>.filled(size * size, sea);
    final List<int> clues = List<int>.filled(size * size, 0);
    final int minGaps = size >= 7 || stage >= 7 ? 2 : 1;
    final int maxGaps = math.min((size + 1) ~/ 2, switch (stage) {
      <= 3 => minGaps,
      <= 6 => math.max(2, minGaps),
      <= 8 => math.max(3, minGaps),
      _ => math.max(4, minGaps),
    });
    int islandCount = 0;

    for (int lane = 0; lane < size; lane += 2) {
      final int gapCount = minGaps + random.nextInt(maxGaps - minGaps + 1);
      final List<int> positions = List<int>.generate(size, (int i) => i)
        ..shuffle(random);
      final Set<int> gaps = <int>{};
      for (final int candidate in positions) {
        if (gaps.any((int gap) => (gap - candidate).abs() == 1)) continue;
        gaps.add(candidate);
        if (gaps.length == gapCount) break;
      }
      if (gaps.length != gapCount) return null;

      int cursor = 0;
      while (cursor < size) {
        if (gaps.contains(cursor)) {
          cursor++;
          continue;
        }
        final int start = cursor;
        while (cursor < size && !gaps.contains(cursor)) {
          final int cell = vertical
              ? cursor * size + lane
              : lane * size + cursor;
          board[cell] = island;
          cursor++;
        }
        final int clueCell = vertical
            ? start * size + lane
            : lane * size + start;
        clues[clueCell] = cursor - start;
        islandCount++;
      }
    }
    return (clues: clues, board: board, islands: islandCount);
  }

  static List<Set<int>> _islandPlacements({
    required int size,
    required int clueCell,
    required int islandSize,
    required Set<int> clueCells,
  }) {
    final Set<int> forbiddenClueHalo = <int>{
      for (final int other in clueCells)
        if (other != clueCell) ...<int>{other, ..._neighbors8(size, other)},
    };
    final Set<String> seen = <String>{};
    final List<Set<String>> seenAtSize = <Set<String>>[
      for (int index = 0; index <= islandSize; index++) <String>{},
    ];
    final List<Set<int>> placements = <Set<int>>[];
    final Set<int> shape = <int>{clueCell};

    void grow() {
      final List<int> orderedShape = shape.toList()..sort();
      if (!seenAtSize[shape.length].add(orderedShape.join(','))) return;
      if (shape.length == islandSize) {
        final String signature = orderedShape.join(',');
        if (seen.add(signature)) placements.add(Set<int>.of(shape));
        return;
      }
      final Set<int> frontier = <int>{
        for (final int cell in shape) ..._neighbors4(size, cell),
      }..removeAll(shape);
      frontier.removeAll(forbiddenClueHalo);
      final List<int> ordered = frontier.toList()..sort();
      for (final int next in ordered) {
        shape.add(next);
        grow();
        shape.remove(next);
      }
    }

    if (!forbiddenClueHalo.contains(clueCell)) grow();
    return placements;
  }

  static bool _obeysBoardRules(int size, List<int> board) {
    if (board.length != size * size ||
        board.any((int cell) => cell != island && cell != sea)) {
      return false;
    }
    final Set<int> visited = <int>{};
    final Queue<int> queue = Queue<int>();
    final int firstSea = board.indexOf(sea);
    if (firstSea < 0) return false;
    visited.add(firstSea);
    queue.add(firstSea);
    while (queue.isNotEmpty) {
      for (final int neighbor in _neighbors4(size, queue.removeFirst())) {
        if (board[neighbor] == sea && visited.add(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    if (visited.length != board.where((int cell) => cell == sea).length) {
      return false;
    }
    for (int row = 0; row < size - 1; row++) {
      for (int column = 0; column < size - 1; column++) {
        final List<int> square = <int>[
          row * size + column,
          row * size + column + 1,
          (row + 1) * size + column,
          (row + 1) * size + column + 1,
        ];
        if (square.every((int cell) => board[cell] == sea)) return false;
      }
    }
    return true;
  }

  static List<int> _neighbors4(int size, int cell) {
    final int row = cell ~/ size;
    final int column = cell % size;
    return <int>[
      if (row > 0) cell - size,
      if (column > 0) cell - 1,
      if (column + 1 < size) cell + 1,
      if (row + 1 < size) cell + size,
    ];
  }

  static List<int> _neighbors8(int size, int cell) {
    final int row = cell ~/ size;
    final int column = cell % size;
    return <int>[
      for (int nextRow = row - 1; nextRow <= row + 1; nextRow++)
        for (
          int nextColumn = column - 1;
          nextColumn <= column + 1;
          nextColumn++
        )
          if (nextRow >= 0 &&
              nextRow < size &&
              nextColumn >= 0 &&
              nextColumn < size &&
              (nextRow != row || nextColumn != column))
            nextRow * size + nextColumn,
    ];
  }

  static bool _sameBoard(List<int> left, List<int> right) {
    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class _IslandClue {
  _IslandClue({required this.cell, required this.size});

  final int cell;
  final int size;
  List<Set<int>> placements = <Set<int>>[];
}
