import 'dart:math' as math;

import '../shared/content_seed.dart';

class BridgePoint {
  const BridgePoint({required this.row, required this.column});

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is BridgePoint && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}

class BridgeIsland {
  const BridgeIsland({required this.point, required this.target});

  final BridgePoint point;
  final int target;
}

class BridgeLink {
  const BridgeLink({required this.first, required this.second});

  final int first;
  final int second;

  String get key => first < second ? '$first:$second' : '$second:$first';
}

/// Hashi-style network puzzle: exact island degrees, no bridge crossings,
/// one connected network, and a maximum of two bridges per route.
class BridgeBuilderPuzzle {
  static const int maximumUniqueCases = 300;
  static const int boardSize = 17;
  static final Map<int, BridgeBuilderPuzzle> _cache =
      <int, BridgeBuilderPuzzle>{};
  // Fixed seed jumps resolve content-signature collisions found by the 300-case
  // regression. The final board remains deterministic on every platform run.
  static const Map<int, int> _seedJumps = <int, int>{10: 1000, 45: 2000};

  const BridgeBuilderPuzzle({
    required this.level,
    required this.islands,
    required this.links,
    required this.solution,
  });

  final int level;
  final List<BridgeIsland> islands;
  final List<BridgeLink> links;
  final List<int> solution;

  String get boardSignature => <String>[
    for (final BridgeIsland island in islands)
      '${island.point.row},${island.point.column}:${island.target}',
    '|',
    for (final BridgeLink link in links) link.key,
  ].join(';');

  static int cyclesForLevel(int level) => switch (level) {
    < 61 => 2,
    < 131 => 3,
    < 221 => 4,
    _ => 5,
  };

  static BridgeBuilderPuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  bool get hasUniqueSolution => countSolutions() == 1;

  int countSolutions({int limit = 2}) => _search(this, limit: limit).count;

  bool crosses(int firstLink, int secondLink) =>
      _crosses(this, links[firstLink], links[secondLink]);

  bool wouldCross(int linkIndex, List<int> values) {
    for (int other = 0; other < links.length; other++) {
      if (other != linkIndex &&
          values[other] > 0 &&
          crosses(linkIndex, other)) {
        return true;
      }
    }
    return false;
  }

  bool isSolved(List<int> values) {
    if (values.length != links.length ||
        values.any((int value) => value < 0 || value > 2)) {
      return false;
    }
    return hasCorrectIslandTotals(values) &&
        !hasCrossingBridge(values) &&
        isNetworkConnected(values);
  }

  bool hasCrossingBridge(List<int> values) {
    if (values.length != links.length) return true;
    for (int edge = 0; edge < links.length; edge++) {
      if (values[edge] == 0) continue;
      for (int other = edge + 1; other < links.length; other++) {
        if (values[other] > 0 && _crosses(this, links[edge], links[other])) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasCorrectIslandTotals(List<int> values) {
    if (values.length != links.length ||
        values.any((int value) => value < 0 || value > 2)) {
      return false;
    }
    final List<int> totals = List<int>.filled(islands.length, 0);
    for (int edge = 0; edge < links.length; edge++) {
      final BridgeLink link = links[edge];
      totals[link.first] += values[edge];
      totals[link.second] += values[edge];
    }
    return totals.asMap().entries.every(
      (MapEntry<int, int> entry) => entry.value == islands[entry.key].target,
    );
  }

  bool isNetworkConnected(List<int> values) =>
      values.length == links.length && _isConnected(this, values);

  static BridgeBuilderPuzzle _generate(int level) {
    final int desiredCycles = cyclesForLevel(level);
    for (int attempt = 0; attempt < 240; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'bridge_builder',
        level: level,
        attempt: (_seedJumps[level] ?? 0) + attempt,
      );
      final List<Set<BridgePoint>> loops = _makeLoops(
        random,
        desiredCycles,
        level,
      );
      if (loops.length != desiredCycles) continue;

      final Set<BridgePoint> points = <BridgePoint>{
        for (final Set<BridgePoint> loop in loops) ...loop,
      };
      final Map<String, int> solutionWeights = <String, int>{};
      final Map<BridgePoint, int> targetByPoint = <BridgePoint, int>{};
      for (final Set<BridgePoint> loop in loops) {
        final bool canDouble = loop.every(
          (BridgePoint point) => (targetByPoint[point] ?? 0) + 4 <= 8,
        );
        final int weight = canDouble && random.nextInt(3) == 0 ? 2 : 1;
        for (final BridgePoint point in loop) {
          targetByPoint[point] = (targetByPoint[point] ?? 0) + 2 * weight;
        }
        for (final String edge in _loopEdges(loop)) {
          solutionWeights[edge] = weight;
        }
      }
      final List<BridgePoint> orderedPoints = points.toList()
        ..sort((BridgePoint a, BridgePoint b) {
          final int rowOrder = a.row.compareTo(b.row);
          return rowOrder != 0 ? rowOrder : a.column.compareTo(b.column);
        });
      final Map<BridgePoint, int> pointIndex = <BridgePoint, int>{
        for (int index = 0; index < orderedPoints.length; index++)
          orderedPoints[index]: index,
      };
      final List<BridgeLink> links = _candidateLinks(orderedPoints, pointIndex);
      if (links.length < solutionWeights.length || links.length > 22) continue;

      final List<int> solution = List<int>.generate(
        links.length,
        (int index) =>
            solutionWeights[_pointEdgeKey(
              orderedPoints[links[index].first],
              orderedPoints[links[index].second],
            )] ??
            0,
        growable: false,
      );
      final List<int> targets = List<int>.filled(orderedPoints.length, 0);
      for (int index = 0; index < links.length; index++) {
        if (solution[index] == 0) continue;
        targets[links[index].first] += solution[index];
        targets[links[index].second] += solution[index];
      }
      if (targets.any((int target) => target == 0 || target > 8)) continue;

      final BridgeBuilderPuzzle puzzle = BridgeBuilderPuzzle(
        level: level,
        islands: List<BridgeIsland>.unmodifiable(<BridgeIsland>[
          for (int index = 0; index < orderedPoints.length; index++)
            BridgeIsland(point: orderedPoints[index], target: targets[index]),
        ]),
        links: List<BridgeLink>.unmodifiable(links),
        solution: List<int>.unmodifiable(solution),
      );
      if (!_isConnected(puzzle, solution) ||
          !_isPlanar(puzzle, solution) ||
          puzzle.countSolutions() != 1) {
        continue;
      }
      return puzzle;
    }
    throw StateError('Could not generate a unique bridge case for $level.');
  }

  static List<Set<BridgePoint>> _makeLoops(
    math.Random random,
    int count,
    int level,
  ) {
    final int largestSide = level < 61
        ? 2
        : level < 131
        ? 3
        : 4;
    const int smallestSide = 2;
    final List<Set<BridgePoint>> loops = <Set<BridgePoint>>[];
    final Set<BridgePoint> occupied = <BridgePoint>{};
    final Map<BridgePoint, int> degree = <BridgePoint, int>{};
    final Set<String> occupiedEdges = <String>{};

    for (int loopIndex = 0; loopIndex < count; loopIndex++) {
      final List<Set<BridgePoint>> candidates = <Set<BridgePoint>>[];
      if (loopIndex == 0) {
        final int originRange = boardSize - 6;
        final int row = 3 + random.nextInt(originRange);
        final int column = 3 + random.nextInt(originRange);
        for (int side = smallestSide; side <= largestSide; side++) {
          for (int rowDirection in const <int>[-1, 1]) {
            for (int columnDirection in const <int>[-1, 1]) {
              final Set<BridgePoint> loop = _square(
                BridgePoint(row: row, column: column),
                rowDirection,
                columnDirection,
                side,
              );
              if (_withinBoard(loop) &&
                  loop.length == 4 &&
                  loop.every(
                    (BridgePoint point) => !occupied.contains(point),
                  )) {
                candidates.add(loop);
              }
            }
          }
        }
      } else {
        for (final BridgePoint anchor in occupied) {
          if ((degree[anchor] ?? 0) > 6) continue;
          for (int side = smallestSide; side <= largestSide; side++) {
            for (int rowDirection in const <int>[-1, 1]) {
              for (int columnDirection in const <int>[-1, 1]) {
                final Set<BridgePoint> loop = _square(
                  anchor,
                  rowDirection,
                  columnDirection,
                  side,
                );
                final List<String> keys = _loopEdges(loop).toList();
                if (_withinBoard(loop) &&
                    loop.length == 4 &&
                    loop
                        .where((BridgePoint point) => point != anchor)
                        .every(
                          (BridgePoint point) => !occupied.contains(point),
                        ) &&
                    keys.every((String key) => !occupiedEdges.contains(key))) {
                  candidates.add(loop);
                }
              }
            }
          }
        }
      }
      if (candidates.isEmpty) return loops;
      candidates.shuffle(random);
      final Set<BridgePoint> selected = candidates.first;
      final List<String> edges = _loopEdges(selected).toList();
      loops.add(selected);
      for (final BridgePoint point in selected) {
        if (!occupied.add(point)) degree[point] = (degree[point] ?? 0) + 2;
      }
      occupiedEdges.addAll(edges);
    }
    return loops;
  }

  static Set<BridgePoint> _square(
    BridgePoint anchor,
    int rowDirection,
    int columnDirection,
    int side,
  ) => <BridgePoint>{
    anchor,
    BridgePoint(row: anchor.row + rowDirection * side, column: anchor.column),
    BridgePoint(
      row: anchor.row,
      column: anchor.column + columnDirection * side,
    ),
    BridgePoint(
      row: anchor.row + rowDirection * side,
      column: anchor.column + columnDirection * side,
    ),
  };

  static bool _withinBoard(Iterable<BridgePoint> points) => points.every(
    (BridgePoint point) =>
        point.row >= 0 &&
        point.row < boardSize &&
        point.column >= 0 &&
        point.column < boardSize,
  );

  static Set<String> _loopEdges(Set<BridgePoint> loop) {
    final List<BridgePoint> points = loop.toList();
    final Set<String> edges = <String>{};
    for (int first = 0; first < points.length; first++) {
      for (int second = first + 1; second < points.length; second++) {
        final BridgePoint a = points[first];
        final BridgePoint b = points[second];
        if (a.row == b.row || a.column == b.column) {
          edges.add(_pointEdgeKey(a, b));
        }
      }
    }
    return edges;
  }

  static String _pointEdgeKey(BridgePoint a, BridgePoint b) {
    final String first = '${a.row},${a.column}';
    final String second = '${b.row},${b.column}';
    return first.compareTo(second) < 0 ? '$first|$second' : '$second|$first';
  }

  static List<BridgeLink> _candidateLinks(
    List<BridgePoint> points,
    Map<BridgePoint, int> pointIndex,
  ) {
    final Set<String> keys = <String>{};
    for (int index = 0; index < points.length; index++) {
      final BridgePoint point = points[index];
      for (final BridgePoint other in points) {
        if (point.row != other.row && point.column != other.column) continue;
        final int otherIndex = pointIndex[other]!;
        if (index == otherIndex) continue;
        final bool hasBetween = points.any((BridgePoint middle) {
          if (middle == point || middle == other) return false;
          if (point.row == other.row) {
            return middle.row == point.row &&
                middle.column > math.min(point.column, other.column) &&
                middle.column < math.max(point.column, other.column);
          }
          return middle.column == point.column &&
              middle.row > math.min(point.row, other.row) &&
              middle.row < math.max(point.row, other.row);
        });
        if (!hasBetween) {
          final int low = math.min(index, otherIndex);
          final int high = math.max(index, otherIndex);
          keys.add('$low:$high');
        }
      }
    }
    final List<String> sorted = keys.toList()..sort();
    return <BridgeLink>[
      for (final String key in sorted)
        BridgeLink(
          first: int.parse(key.split(':')[0]),
          second: int.parse(key.split(':')[1]),
        ),
    ];
  }

  static bool _crosses(BridgeBuilderPuzzle puzzle, BridgeLink a, BridgeLink b) {
    final BridgePoint a1 = puzzle.islands[a.first].point;
    final BridgePoint a2 = puzzle.islands[a.second].point;
    final BridgePoint b1 = puzzle.islands[b.first].point;
    final BridgePoint b2 = puzzle.islands[b.second].point;
    if (a1.row == a2.row && b1.column == b2.column) {
      return b1.column > math.min(a1.column, a2.column) &&
          b1.column < math.max(a1.column, a2.column) &&
          a1.row > math.min(b1.row, b2.row) &&
          a1.row < math.max(b1.row, b2.row);
    }
    if (a1.column == a2.column && b1.row == b2.row) {
      return _crosses(puzzle, b, a);
    }
    return false;
  }

  static bool _isPlanar(BridgeBuilderPuzzle puzzle, List<int> values) {
    for (int first = 0; first < puzzle.links.length; first++) {
      if (values[first] == 0) continue;
      for (int second = first + 1; second < puzzle.links.length; second++) {
        if (values[second] > 0 &&
            _crosses(puzzle, puzzle.links[first], puzzle.links[second])) {
          return false;
        }
      }
    }
    return true;
  }

  static bool _isConnected(BridgeBuilderPuzzle puzzle, List<int> values) {
    if (puzzle.islands.isEmpty) return false;
    final List<Set<int>> adjacency = List<Set<int>>.generate(
      puzzle.islands.length,
      (_) => <int>{},
    );
    for (int index = 0; index < puzzle.links.length; index++) {
      if (values[index] == 0) continue;
      final BridgeLink link = puzzle.links[index];
      adjacency[link.first].add(link.second);
      adjacency[link.second].add(link.first);
    }
    final Set<int> visited = <int>{0};
    final List<int> pending = <int>[0];
    while (pending.isNotEmpty) {
      for (final int next in adjacency[pending.removeLast()]) {
        if (visited.add(next)) pending.add(next);
      }
    }
    return visited.length == puzzle.islands.length;
  }

  static _BridgeSearchResult _search(
    BridgeBuilderPuzzle puzzle, {
    required int limit,
  }) {
    final List<int> values = List<int>.filled(puzzle.links.length, -1);
    final List<int> sums = List<int>.filled(puzzle.islands.length, 0);
    int solutions = 0;
    List<int>? firstSolution;

    void visit(int assigned) {
      if (solutions >= limit) return;
      int selected = -1;
      List<int> selectedOptions = const <int>[];
      int bestOptionCount = 4;
      for (int edge = 0; edge < puzzle.links.length; edge++) {
        if (values[edge] >= 0) continue;
        final BridgeLink link = puzzle.links[edge];
        final int residualFirst =
            puzzle.islands[link.first].target - sums[link.first];
        final int residualSecond =
            puzzle.islands[link.second].target - sums[link.second];
        if (residualFirst < 0 || residualSecond < 0) return;
        int maximum = math.min(2, math.min(residualFirst, residualSecond));
        for (int other = 0; other < puzzle.links.length; other++) {
          if (values[other] > 0 &&
              _crosses(puzzle, link, puzzle.links[other])) {
            maximum = 0;
            break;
          }
        }
        final List<int> options = <int>[for (int n = 0; n <= maximum; n++) n];
        if (options.length < bestOptionCount) {
          selected = edge;
          selectedOptions = options;
          bestOptionCount = options.length;
          if (bestOptionCount == 1) break;
        }
      }
      if (assigned == puzzle.links.length) {
        if (sums.asMap().entries.every(
              (MapEntry<int, int> entry) =>
                  entry.value == puzzle.islands[entry.key].target,
            ) &&
            _isConnected(puzzle, values)) {
          solutions++;
          firstSolution ??= List<int>.from(values);
        }
        return;
      }
      if (selected < 0) return;

      final BridgeLink link = puzzle.links[selected];
      for (final int option in selectedOptions) {
        values[selected] = option;
        sums[link.first] += option;
        sums[link.second] += option;
        if (_remainingCapacityIsEnough(puzzle, values, sums)) {
          visit(assigned + 1);
        }
        sums[link.first] -= option;
        sums[link.second] -= option;
        values[selected] = -1;
        if (solutions >= limit) return;
      }
    }

    visit(0);
    return _BridgeSearchResult(solutions, firstSolution);
  }

  static bool _remainingCapacityIsEnough(
    BridgeBuilderPuzzle puzzle,
    List<int> values,
    List<int> sums,
  ) {
    for (int island = 0; island < puzzle.islands.length; island++) {
      int maximum = sums[island];
      for (int edge = 0; edge < puzzle.links.length; edge++) {
        if (values[edge] >= 0) continue;
        final BridgeLink link = puzzle.links[edge];
        if (link.first == island || link.second == island) maximum += 2;
      }
      if (maximum < puzzle.islands[island].target) return false;
    }
    return true;
  }
}

class _BridgeSearchResult {
  const _BridgeSearchResult(this.count, this.firstSolution);

  final int count;
  final List<int>? firstSolution;
}
