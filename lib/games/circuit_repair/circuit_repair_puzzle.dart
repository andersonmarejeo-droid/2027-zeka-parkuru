/// Rotation-safe puzzle data for S03 — Circuit Repair.
///
/// Wires use a four-bit mask: up, right, down and left. A connection is
/// valid only when both adjacent tiles expose the matching direction.
enum CircuitDirection {
  up(1, 0, -1),
  right(2, 1, 0),
  down(4, 0, 1),
  left(8, -1, 0);

  const CircuitDirection(this.bit, this.dx, this.dy);

  final int bit;
  final int dx;
  final int dy;

  CircuitDirection get clockwise => switch (this) {
    CircuitDirection.up => CircuitDirection.right,
    CircuitDirection.right => CircuitDirection.down,
    CircuitDirection.down => CircuitDirection.left,
    CircuitDirection.left => CircuitDirection.up,
  };

  CircuitDirection get opposite => switch (this) {
    CircuitDirection.up => CircuitDirection.down,
    CircuitDirection.right => CircuitDirection.left,
    CircuitDirection.down => CircuitDirection.up,
    CircuitDirection.left => CircuitDirection.right,
  };
}

class CircuitTile {
  const CircuitTile({required this.solvedMask, required this.initialTurns});

  final int solvedMask;
  final int initialTurns;

  bool get isEmpty => solvedMask == 0;

  int maskAt(int turns) {
    int mask = solvedMask;
    for (int index = 0; index < (turns + initialTurns) % 4; index++) {
      mask = rotateMaskClockwise(mask);
    }
    return mask;
  }
}

int rotateMaskClockwise(int mask) {
  int rotated = 0;
  for (final CircuitDirection direction in CircuitDirection.values) {
    if ((mask & direction.bit) != 0) rotated |= direction.clockwise.bit;
  }
  return rotated;
}

class CircuitPuzzle {
  const CircuitPuzzle({
    required this.size,
    required this.source,
    required this.target,
    required this.tiles,
  });

  final int size;
  final int source;
  final int target;
  final List<CircuitTile> tiles;

  int get cellCount => size * size;

  int get minimumTurns => tiles.fold<int>(
    0,
    (int total, CircuitTile tile) =>
        total + (tile.isEmpty ? 0 : (4 - tile.initialTurns) % 4),
  );

  int initialMaskAt(int cell) => tiles[cell].maskAt(0);
  int solvedMaskAt(int cell) => tiles[cell].solvedMask;

  int rotateCurrentMask(int cell, int turns) => tiles[cell].maskAt(turns);

  bool isTargetEnergized(List<int> masks) {
    if (masks.length != cellCount) return false;
    final Set<int> visited = <int>{source};
    final List<int> queue = <int>[source];

    while (queue.isNotEmpty) {
      final int cell = queue.removeAt(0);
      if (cell == target) return true;
      final int row = cell ~/ size;
      final int column = cell % size;
      for (final CircuitDirection direction in CircuitDirection.values) {
        if ((masks[cell] & direction.bit) == 0) continue;
        final int nextRow = row + direction.dy;
        final int nextColumn = column + direction.dx;
        if (nextRow < 0 ||
            nextColumn < 0 ||
            nextRow >= size ||
            nextColumn >= size) {
          continue;
        }
        final int next = nextRow * size + nextColumn;
        if ((masks[next] & direction.opposite.bit) == 0) continue;
        if (visited.add(next)) queue.add(next);
      }
    }
    return false;
  }

  bool hasValidSolution() =>
      isTargetEnergized(List<int>.generate(cellCount, solvedMaskAt));

  static CircuitPuzzle forLevel(int level) {
    return _puzzles[(level - 1).clamp(0, _puzzles.length - 1).toInt()];
  }

  static CircuitPuzzle _fromPath({
    required int size,
    required List<int> path,
    required int level,
  }) {
    assert(path.length >= 2);
    final List<int> masks = List<int>.filled(size * size, 0);
    for (int index = 0; index < path.length - 1; index++) {
      final int current = path[index];
      final int next = path[index + 1];
      final int rowDelta = next ~/ size - current ~/ size;
      final int columnDelta = next % size - current % size;
      final CircuitDirection direction = switch ((rowDelta, columnDelta)) {
        (-1, 0) => CircuitDirection.up,
        (0, 1) => CircuitDirection.right,
        (1, 0) => CircuitDirection.down,
        (0, -1) => CircuitDirection.left,
        _ => throw ArgumentError('Circuit path has a non-adjacent step.'),
      };
      masks[current] |= direction.bit;
      masks[next] |= direction.opposite.bit;
    }
    return CircuitPuzzle(
      size: size,
      source: path.first,
      target: path.last,
      tiles: List<CircuitTile>.generate(
        masks.length,
        (int cell) => CircuitTile(
          solvedMask: masks[cell],
          initialTurns: masks[cell] == 0 ? 0 : (cell + level * 2) % 4,
        ),
      ),
    );
  }

  static final List<CircuitPuzzle> _puzzles = <CircuitPuzzle>[
    _fromPath(size: 4, level: 1, path: <int>[0, 1, 2, 3, 7, 11, 15]),
    _fromPath(size: 4, level: 2, path: <int>[0, 4, 8, 9, 10, 11, 15]),
    _fromPath(size: 4, level: 3, path: <int>[0, 1, 5, 9, 13, 14, 15]),
    _fromPath(size: 4, level: 4, path: <int>[0, 4, 5, 6, 7, 11, 15]),
    _fromPath(size: 5, level: 5, path: <int>[0, 1, 2, 7, 12, 17, 22, 23, 24]),
    _fromPath(size: 5, level: 6, path: <int>[0, 5, 10, 11, 12, 13, 14, 19, 24]),
    _fromPath(size: 5, level: 7, path: <int>[0, 1, 6, 11, 16, 21, 22, 23, 24]),
    _fromPath(size: 5, level: 8, path: <int>[0, 5, 6, 7, 8, 13, 18, 23, 24]),
    _fromPath(size: 5, level: 9, path: <int>[0, 1, 2, 3, 4, 9, 14, 19, 24]),
    _fromPath(
      size: 5,
      level: 10,
      path: <int>[0, 5, 10, 15, 16, 17, 12, 7, 8, 9, 14, 19, 24],
    ),
  ];
}
