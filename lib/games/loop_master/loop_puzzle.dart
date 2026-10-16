import 'dart:math' as math;

import '../shared/content_seed.dart';

class LoopPoint {
  const LoopPoint(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is LoopPoint && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}

class LoopSolutionReport {
  const LoopSolutionReport({
    required this.solutionCount,
    required this.visitedNodes,
    this.firstSolution,
  });

  final int solutionCount;
  final int visitedNodes;
  final Set<int>? firstSolution;
}

/// A Slitherlink-style number-edge puzzle. Every accepted seed is backed by a
/// constraint search proving exactly one single, non-crossing loop.
class LoopPuzzle {
  const LoopPuzzle._({
    required this.level,
    required this.seed,
    required this.size,
    required this.clues,
    required this.solutionEdges,
    required this.solutionVertices,
    required this.proofNodes,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, LoopPuzzle> _campaign = <int, LoopPuzzle>{};
  static final Map<int, LoopPuzzle> _practice = <int, LoopPuzzle>{};

  final int level;
  final int seed;
  final int size;
  final List<int?> clues;
  final Set<int> solutionEdges;
  final List<int> solutionVertices;
  final int proofNodes;

  int get horizontalEdgeCount => (size + 1) * size;

  int get edgeCount => 2 * (size + 1) * size;

  String get signature =>
      '$size:${clues.map((int? clue) => clue ?? '.').join()}';

  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    <= 16 => 'EXPERT',
    _ => 'MASTER',
  };

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'seed': seed,
    'size': size,
    'proofNodes': proofNodes,
    'solutionVertices': solutionVertices,
    'clues': clues,
    'solutionEdges': solutionEdges.toList(),
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) throw FormatException('Invalid loop_master bank');
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practice[i + 1] = LoopPuzzle._(
        level: m['level'] as int,
        seed: m['seed'] as int,
        size: m['size'] as int,
        proofNodes: m['proofNodes'] as int,
        solutionVertices: List<int>.from(m['solutionVertices'] as List),
        clues: List<int?>.from(m['clues'] as List),
        solutionEdges: Set<int>.from(m['solutionEdges'] as List),
      );
    }
  }

  static LoopPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _campaign.putIfAbsent(level, () => _generate(level));
  }

  static LoopPuzzle forPracticeBoard(int index) {
    final cached = _practice[index];
    if (cached != null) return cached;
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _campaign.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      LoopPuzzle? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final LoopPuzzle candidate = _generate(
          level,
          contentCycle: 1000 + cycle,
        );
        if (<LoopPuzzle>[..._campaign.values, ..._practice.values].every(
          (LoopPuzzle previous) => previous.signature != candidate.signature,
        )) {
          accepted = candidate;
        }
      }
      _practice[next] = accepted;
    }
    return _practice[index]!;
  }

  int horizontalEdge(int row, int column) => row * size + column;

  int verticalEdge(int row, int column) =>
      horizontalEdgeCount + row * (size + 1) + column;

  LoopPoint point(int vertexId) =>
      LoopPoint(vertexId ~/ (size + 1), vertexId % (size + 1));

  int vertexId(int row, int column) => row * (size + 1) + column;

  (int, int) edgeEndpoints(int edgeId) {
    if (edgeId < horizontalEdgeCount) {
      final int row = edgeId ~/ size;
      final int column = edgeId % size;
      return (vertexId(row, column), vertexId(row, column + 1));
    }
    final int local = edgeId - horizontalEdgeCount;
    final int row = local ~/ (size + 1);
    final int column = local % (size + 1);
    return (vertexId(row, column), vertexId(row + 1, column));
  }

  List<int> cellEdges(int row, int column) => <int>[
    horizontalEdge(row, column),
    horizontalEdge(row + 1, column),
    verticalEdge(row, column),
    verticalEdge(row, column + 1),
  ];

  List<int> vertexEdges(int vertex) {
    final LoopPoint location = point(vertex);
    final List<int> result = <int>[];
    if (location.row > 0) {
      result.add(verticalEdge(location.row - 1, location.column));
    }
    if (location.row < size) {
      result.add(verticalEdge(location.row, location.column));
    }
    if (location.column > 0) {
      result.add(horizontalEdge(location.row, location.column - 1));
    }
    if (location.column < size) {
      result.add(horizontalEdge(location.row, location.column));
    }
    return result;
  }

  int adjacentCellCount(int edgeId) {
    if (edgeId < horizontalEdgeCount) {
      final int row = edgeId ~/ size;
      return row == 0 || row == size ? 1 : 2;
    }
    final int local = edgeId - horizontalEdgeCount;
    final int column = local % (size + 1);
    return column == 0 || column == size ? 1 : 2;
  }

  List<int> cellsForEdge(int edgeId) {
    if (edgeId < horizontalEdgeCount) {
      final int row = edgeId ~/ size;
      final int column = edgeId % size;
      final List<int> result = <int>[];
      if (row > 0) result.add((row - 1) * size + column);
      if (row < size) result.add(row * size + column);
      return result;
    }
    final int local = edgeId - horizontalEdgeCount;
    final int row = local ~/ (size + 1);
    final int column = local % (size + 1);
    final List<int> result = <int>[];
    if (column > 0) result.add(row * size + column - 1);
    if (column < size) result.add(row * size + column);
    return result;
  }

  bool canAddEdge(Set<int> selected, int edgeId) {
    if (edgeId < 0 || edgeId >= edgeCount || selected.contains(edgeId)) {
      return false;
    }
    final (int first, int second) = edgeEndpoints(edgeId);
    if (vertexEdges(first).where(selected.contains).length >= 2 ||
        vertexEdges(second).where(selected.contains).length >= 2) {
      return false;
    }
    for (final int cell in cellsForEdge(edgeId)) {
      final int? clue = clues[cell];
      if (clue == null) continue;
      final int already = cellEdges(
        cell ~/ size,
        cell % size,
      ).where(selected.contains).length;
      if (already + 1 > clue) return false;
    }
    return true;
  }

  bool isSolved(Set<int> selected) =>
      selected.length == solutionEdges.length &&
      selected.containsAll(solutionEdges) &&
      validateSingleLoop(selected);

  bool validateSingleLoop(Set<int> selected) {
    if (!formsSingleClosedLoop(selected)) return false;
    for (int row = 0; row < size; row++) {
      for (int column = 0; column < size; column++) {
        final int? clue = clues[row * size + column];
        if (clue == null) continue;
        final int count = cellEdges(
          row,
          column,
        ).where(selected.contains).length;
        if (count != clue) return false;
      }
    }
    return true;
  }

  bool formsSingleClosedLoop(Set<int> selected) {
    if (selected.isEmpty) return false;
    final Map<int, List<int>> adjacency = <int, List<int>>{};
    for (final int edge in selected) {
      final (int first, int second) = edgeEndpoints(edge);
      adjacency.putIfAbsent(first, () => <int>[]).add(second);
      adjacency.putIfAbsent(second, () => <int>[]).add(first);
    }
    if (adjacency.values.any((List<int> neighbors) => neighbors.length != 2)) {
      return false;
    }
    final Set<int> reached = <int>{};
    final List<int> pending = <int>[adjacency.keys.first];
    while (pending.isNotEmpty) {
      final int vertex = pending.removeLast();
      if (!reached.add(vertex)) continue;
      pending.addAll(adjacency[vertex]!);
    }
    if (reached.length != adjacency.length) return false;
    return true;
  }

  LoopSolutionReport solve({int limit = 2}) =>
      _LoopSolver(this).solve(limit: limit);

  static LoopPuzzle _generate(int level, {int contentCycle = 0}) {
    final int size = _sizeForLevel(level);
    final int targetCells = _shapeCellsForLevel(level);
    final int minimumNodes = _minimumProofNodes(level);
    for (int attempt = 0; attempt < 7000; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'loop_master:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final Set<int> cells = _growPolyomino(
        size: size,
        targetCount: targetCells,
        random: random,
      );
      if (cells.length != targetCells) continue;
      final Set<int> loop = _boundaryEdges(size: size, cells: cells);
      final List<int>? cycle = _orderCycle(size: size, edges: loop);
      if (cycle == null || loop.length < level + 7) continue;
      final List<int?> clues = _clues(size: size, cells: cells, loop: loop);
      _hideClues(clues, random: random, rate: _hiddenClueRate(level, attempt));
      final LoopPuzzle draft = LoopPuzzle._(
        level: level,
        seed: seed,
        size: size,
        clues: List<int?>.unmodifiable(clues),
        solutionEdges: Set<int>.unmodifiable(loop),
        solutionVertices: List<int>.unmodifiable(cycle),
        proofNodes: 0,
      );
      final LoopSolutionReport report = draft.solve();
      if (report.solutionCount != 1 || report.visitedNodes < minimumNodes) {
        continue;
      }
      if (report.firstSolution == null ||
          !draft.isSolved(report.firstSolution!)) {
        continue;
      }
      return LoopPuzzle._(
        level: level,
        seed: seed,
        size: size,
        clues: draft.clues,
        solutionEdges: draft.solutionEdges,
        solutionVertices: draft.solutionVertices,
        proofNodes: report.visitedNodes,
      );
    }
    throw StateError(
      'Could not certify a unique single loop for level $level.',
    );
  }

  static int _sizeForLevel(int level) => switch (level) {
    <= 3 => 5,
    <= 8 => 6,
    <= 16 => 7,
    _ => 8,
  };

  static int _shapeCellsForLevel(int level) => switch (level) {
    <= 3 => 5,
    <= 6 => 7,
    <= 8 => 9,
    <= 10 => 11,
    <= 13 => 12,
    <= 16 => 14,
    <= 18 => 16,
    _ => 18,
  };

  static int _minimumProofNodes(int level) => switch (level) {
    <= 6 => 1,
    7 || 8 => 3,
    9 || 10 => 5,
    <= 16 => 7,
    _ => 9,
  };

  static double _hiddenClueRate(int level, int attempt) {
    final double base = switch (level) {
      <= 6 => .00,
      7 || 8 => .08,
      9 || 10 => .13,
      <= 16 => .18,
      _ => .22,
    };
    return math.min(.34, base + ((attempt ~/ 80) % 5) * .025);
  }

  static Set<int> _growPolyomino({
    required int size,
    required int targetCount,
    required math.Random random,
  }) {
    final Set<int> cells = <int>{random.nextInt(size * size)};
    while (cells.length < targetCount) {
      final Set<int> frontier = <int>{};
      for (final int cell in cells) {
        final int row = cell ~/ size;
        final int column = cell % size;
        for (final (int dr, int dc) in const <(int, int)>[
          (1, 0),
          (-1, 0),
          (0, 1),
          (0, -1),
        ]) {
          final int nextRow = row + dr;
          final int nextColumn = column + dc;
          if (nextRow >= 0 &&
              nextRow < size &&
              nextColumn >= 0 &&
              nextColumn < size) {
            final int next = nextRow * size + nextColumn;
            if (!cells.contains(next)) frontier.add(next);
          }
        }
      }
      if (frontier.isEmpty) break;
      cells.add(frontier.elementAt(random.nextInt(frontier.length)));
    }
    return cells;
  }

  static Set<int> _boundaryEdges({required int size, required Set<int> cells}) {
    final int horizontalCount = (size + 1) * size;
    final Set<int> edges = <int>{};
    for (final int cell in cells) {
      final int row = cell ~/ size;
      final int column = cell % size;
      if (row == 0 || !cells.contains((row - 1) * size + column)) {
        edges.add(row * size + column);
      }
      if (row == size - 1 || !cells.contains((row + 1) * size + column)) {
        edges.add((row + 1) * size + column);
      }
      if (column == 0 || !cells.contains(row * size + column - 1)) {
        edges.add(horizontalCount + row * (size + 1) + column);
      }
      if (column == size - 1 || !cells.contains(row * size + column + 1)) {
        edges.add(horizontalCount + row * (size + 1) + column + 1);
      }
    }
    return edges;
  }

  static List<int>? _orderCycle({required int size, required Set<int> edges}) {
    final int horizontalCount = (size + 1) * size;
    int endpointA(int edge) {
      if (edge < horizontalCount) {
        final int row = edge ~/ size;
        final int column = edge % size;
        return row * (size + 1) + column;
      }
      final int local = edge - horizontalCount;
      return (local ~/ (size + 1)) * (size + 1) + local % (size + 1);
    }

    int endpointB(int edge) {
      if (edge < horizontalCount) return endpointA(edge) + 1;
      return endpointA(edge) + size + 1;
    }

    final Map<int, List<int>> adjacency = <int, List<int>>{};
    for (final int edge in edges) {
      final int first = endpointA(edge);
      final int second = endpointB(edge);
      adjacency.putIfAbsent(first, () => <int>[]).add(second);
      adjacency.putIfAbsent(second, () => <int>[]).add(first);
    }
    if (adjacency.values.any((List<int> neighbors) => neighbors.length != 2)) {
      return null;
    }
    final int start = adjacency.keys.reduce(math.min);
    final List<int> cycle = <int>[start];
    int previous = start;
    int current = adjacency[start]!.first;
    while (current != start && cycle.length <= adjacency.length) {
      cycle.add(current);
      final int next = adjacency[current]!.firstWhere(
        (int neighbor) => neighbor != previous,
      );
      previous = current;
      current = next;
    }
    return current == start && cycle.length == adjacency.length ? cycle : null;
  }

  static List<int?> _clues({
    required int size,
    required Set<int> cells,
    required Set<int> loop,
  }) {
    final int horizontalCount = (size + 1) * size;
    final List<int?> clues = List<int?>.filled(size * size, null);
    for (int row = 0; row < size; row++) {
      for (int column = 0; column < size; column++) {
        final int cell = row * size + column;
        final int top = row * size + column;
        final int bottom = (row + 1) * size + column;
        final int left = horizontalCount + row * (size + 1) + column;
        final int right = left + 1;
        clues[cell] = <int>[
          top,
          bottom,
          left,
          right,
        ].where(loop.contains).length;
      }
    }
    return clues;
  }

  static void _hideClues(
    List<int?> clues, {
    required math.Random random,
    required double rate,
  }) {
    final List<int> candidates = List<int>.generate(clues.length, (int i) => i)
      ..shuffle(random);
    final int count = (candidates.length * rate).floor();
    for (final int index in candidates.take(count)) {
      clues[index] = null;
    }
  }
}

class _LoopSolver {
  _LoopSolver(this.puzzle)
    : _cellEdges = List<List<int>>.generate(
        puzzle.size * puzzle.size,
        (int cell) => puzzle.cellEdges(cell ~/ puzzle.size, cell % puzzle.size),
      ),
      _vertexEdges = List<List<int>>.generate(
        (puzzle.size + 1) * (puzzle.size + 1),
        puzzle.vertexEdges,
      ),
      _edgeCells = List<List<int>>.generate(
        puzzle.edgeCount,
        puzzle.cellsForEdge,
      ),
      _edgeVertices = List<(int, int)>.generate(
        puzzle.edgeCount,
        puzzle.edgeEndpoints,
      );

  final LoopPuzzle puzzle;
  final List<List<int>> _cellEdges;
  final List<List<int>> _vertexEdges;
  final List<List<int>> _edgeCells;
  final List<(int, int)> _edgeVertices;
  int _solutions = 0;
  int _visited = 0;
  Set<int>? _first;
  int _limit = 2;

  LoopSolutionReport solve({int limit = 2}) {
    _limit = math.max(1, limit);
    _search(List<int>.filled(puzzle.edgeCount, -1));
    return LoopSolutionReport(
      solutionCount: _solutions,
      visitedNodes: _visited,
      firstSolution: _first,
    );
  }

  void _search(List<int> values) {
    if (_solutions >= _limit) return;
    _visited++;
    if (!_propagate(values)) return;
    final int branch = _chooseEdge(values);
    if (branch < 0) {
      final Set<int> selected = <int>{
        for (int edge = 0; edge < values.length; edge++)
          if (values[edge] == 1) edge,
      };
      if (puzzle.validateSingleLoop(selected)) {
        _solutions++;
        _first ??= Set<int>.unmodifiable(selected);
      }
      return;
    }
    for (final int value in const <int>[0, 1]) {
      final List<int> next = List<int>.from(values);
      next[branch] = value;
      _search(next);
      if (_solutions >= _limit) return;
    }
  }

  bool _propagate(List<int> values) {
    bool changed = true;
    while (changed) {
      changed = false;
      for (int cell = 0; cell < _cellEdges.length; cell++) {
        final int? clue = puzzle.clues[cell];
        if (clue == null) continue;
        final List<int> edges = _cellEdges[cell];
        final int selected = edges
            .where((int edge) => values[edge] == 1)
            .length;
        final List<int> unknown = edges
            .where((int edge) => values[edge] < 0)
            .toList();
        if (selected > clue || selected + unknown.length < clue) return false;
        final int? forced = selected == clue
            ? 0
            : selected + unknown.length == clue
            ? 1
            : null;
        if (forced != null) {
          for (final int edge in unknown) {
            values[edge] = forced;
            changed = true;
          }
        }
      }
      for (final List<int> edges in _vertexEdges) {
        final int selected = edges
            .where((int edge) => values[edge] == 1)
            .length;
        final List<int> unknown = edges
            .where((int edge) => values[edge] < 0)
            .toList();
        if (selected > 2 || (selected == 1 && unknown.isEmpty)) return false;
        int? forced;
        if (selected == 2 || (selected == 0 && unknown.length == 1)) {
          forced = 0;
        } else if (selected == 1 && unknown.length == 1) {
          forced = 1;
        }
        if (forced != null) {
          for (final int edge in unknown) {
            values[edge] = forced;
            changed = true;
          }
        }
      }
    }
    return true;
  }

  int _chooseEdge(List<int> values) {
    int bestEdge = -1;
    int bestScore = -1;
    for (int edge = 0; edge < values.length; edge++) {
      if (values[edge] >= 0) continue;
      int score =
          _edgeCells[edge]
              .where((int cell) => puzzle.clues[cell] != null)
              .length *
          3;
      final (int first, int second) = _edgeVertices[edge];
      score +=
          _vertexEdges[first].where((int item) => values[item] == 1).length * 2;
      score +=
          _vertexEdges[second].where((int item) => values[item] == 1).length *
          2;
      if (score > bestScore) {
        bestEdge = edge;
        bestScore = score;
      }
    }
    return bestEdge;
  }
}
