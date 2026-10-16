import 'package:flutter/material.dart';

class FlowPair {
  const FlowPair({
    required this.id,
    required this.color,
    required this.label,
    required this.start,
    required this.end,
    required this.solution,
  });

  final int id;
  final Color color;
  final String label;
  final int start;
  final int end;
  final List<int> solution;

  bool containsEndpoint(int cell) => cell == start || cell == end;
}

class FlowPuzzle {
  const FlowPuzzle({required this.size, required this.pairs});

  final int size;
  final List<FlowPair> pairs;

  int get cellCount => size * size;
  int get optimalMoves => pairs.fold<int>(
    0,
    (int total, FlowPair pair) => total + pair.solution.length - 1,
  );

  FlowPair? pairForEndpoint(int cell) {
    for (final FlowPair pair in pairs) {
      if (pair.containsEndpoint(cell)) return pair;
    }
    return null;
  }

  bool containsCell(int cell) => cell >= 0 && cell < cellCount;

  bool areAdjacent(int first, int second) {
    if (!containsCell(first) || !containsCell(second)) return false;
    final int firstRow = first ~/ size;
    final int secondRow = second ~/ size;
    return firstRow == secondRow
        ? (first - second).abs() == 1
        : (first - second).abs() == size;
  }

  bool isConnected(FlowPair pair, List<int>? path) {
    if (path == null || path.length < 2) return false;
    final bool startsAtPair = pair.containsEndpoint(path.first);
    final bool endsAtOtherEndpoint = pair.containsEndpoint(path.last);
    return startsAtPair && endsAtOtherEndpoint && path.first != path.last;
  }

  bool isComplete(Map<int, List<int>> paths) {
    return pairs.every((FlowPair pair) => isConnected(pair, paths[pair.id]));
  }

  bool hasValidSolution() {
    final Set<int> occupied = <int>{};
    for (final FlowPair pair in pairs) {
      final List<int> path = pair.solution;
      if (!isConnected(pair, path) ||
          path.any((int cell) => !containsCell(cell))) {
        return false;
      }
      for (int index = 1; index < path.length; index++) {
        if (!areAdjacent(path[index - 1], path[index])) return false;
      }
      if (path.any(occupied.contains)) return false;
      occupied.addAll(path);
    }
    return true;
  }

  static FlowPuzzle forLevel(int level) {
    return _puzzles[(level - 1).clamp(0, _puzzles.length - 1).toInt()];
  }

  static const List<FlowPuzzle> _puzzles = <FlowPuzzle>[
    FlowPuzzle(
      size: 5,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 4,
          solution: <int>[0, 1, 2, 3, 4],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 20,
          end: 24,
          solution: <int>[20, 21, 22, 23, 24],
        ),
      ],
    ),
    FlowPuzzle(
      size: 5,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 4,
          solution: <int>[0, 1, 2, 3, 4],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 10,
          end: 14,
          solution: <int>[10, 11, 12, 13, 14],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 20,
          end: 24,
          solution: <int>[20, 21, 22, 23, 24],
        ),
      ],
    ),
    FlowPuzzle(
      size: 5,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 20,
          solution: <int>[0, 5, 10, 15, 20],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 2,
          end: 22,
          solution: <int>[2, 7, 12, 17, 22],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 4,
          end: 24,
          solution: <int>[4, 9, 14, 19, 24],
        ),
      ],
    ),
    FlowPuzzle(
      size: 5,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 4,
          solution: <int>[0, 1, 2, 3, 4],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 20,
          end: 24,
          solution: <int>[20, 21, 22, 23, 24],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 6,
          end: 18,
          solution: <int>[6, 11, 16, 17, 18],
        ),
      ],
    ),
    FlowPuzzle(
      size: 6,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 5,
          solution: <int>[0, 1, 2, 3, 4, 5],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 12,
          end: 17,
          solution: <int>[12, 13, 14, 15, 16, 17],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 30,
          end: 35,
          solution: <int>[30, 31, 32, 33, 34, 35],
        ),
        FlowPair(
          id: 4,
          color: Color(0xFFC76E93),
          label: 'Rose',
          start: 7,
          end: 10,
          solution: <int>[7, 8, 9, 10],
        ),
      ],
    ),
    FlowPuzzle(
      size: 6,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 30,
          solution: <int>[0, 6, 12, 18, 24, 30],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 2,
          end: 32,
          solution: <int>[2, 8, 14, 20, 26, 32],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 5,
          end: 35,
          solution: <int>[5, 11, 17, 23, 29, 35],
        ),
        FlowPair(
          id: 4,
          color: Color(0xFFC76E93),
          label: 'Rose',
          start: 9,
          end: 10,
          solution: <int>[9, 10],
        ),
      ],
    ),
    FlowPuzzle(
      size: 6,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 5,
          solution: <int>[0, 1, 2, 3, 4, 5],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 12,
          end: 17,
          solution: <int>[12, 13, 14, 15, 16, 17],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 24,
          end: 29,
          solution: <int>[24, 25, 26, 27, 28, 29],
        ),
        FlowPair(
          id: 4,
          color: Color(0xFFC76E93),
          label: 'Rose',
          start: 30,
          end: 35,
          solution: <int>[30, 31, 32, 33, 34, 35],
        ),
      ],
    ),
    FlowPuzzle(
      size: 6,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 30,
          solution: <int>[0, 6, 12, 18, 24, 30],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 2,
          end: 32,
          solution: <int>[2, 8, 14, 20, 26, 32],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 4,
          end: 34,
          solution: <int>[4, 10, 16, 22, 28, 34],
        ),
        FlowPair(
          id: 4,
          color: Color(0xFFC76E93),
          label: 'Rose',
          start: 5,
          end: 35,
          solution: <int>[5, 11, 17, 23, 29, 35],
        ),
      ],
    ),
    FlowPuzzle(
      size: 6,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 5,
          solution: <int>[0, 1, 2, 3, 4, 5],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 6,
          end: 11,
          solution: <int>[6, 7, 8, 9, 10, 11],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 12,
          end: 17,
          solution: <int>[12, 13, 14, 15, 16, 17],
        ),
        FlowPair(
          id: 4,
          color: Color(0xFFC76E93),
          label: 'Rose',
          start: 24,
          end: 29,
          solution: <int>[24, 25, 26, 27, 28, 29],
        ),
        FlowPair(
          id: 5,
          color: Color(0xFFD96767),
          label: 'Coral',
          start: 30,
          end: 35,
          solution: <int>[30, 31, 32, 33, 34, 35],
        ),
      ],
    ),
    FlowPuzzle(
      size: 6,
      pairs: <FlowPair>[
        FlowPair(
          id: 1,
          color: Color(0xFF6F63C8),
          label: 'İndigo',
          start: 0,
          end: 30,
          solution: <int>[0, 6, 12, 18, 24, 30],
        ),
        FlowPair(
          id: 2,
          color: Color(0xFF259C89),
          label: 'Teal',
          start: 3,
          end: 33,
          solution: <int>[3, 9, 15, 21, 27, 33],
        ),
        FlowPair(
          id: 3,
          color: Color(0xFFD89A42),
          label: 'Amber',
          start: 5,
          end: 35,
          solution: <int>[5, 11, 17, 23, 29, 35],
        ),
        FlowPair(
          id: 4,
          color: Color(0xFFC76E93),
          label: 'Rose',
          start: 13,
          end: 14,
          solution: <int>[13, 14],
        ),
        FlowPair(
          id: 5,
          color: Color(0xFFD96767),
          label: 'Coral',
          start: 25,
          end: 26,
          solution: <int>[25, 26],
        ),
      ],
    ),
  ];
}
