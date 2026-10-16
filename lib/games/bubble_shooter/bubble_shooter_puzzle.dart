import 'dart:math';

import '../reference_games/reference_game_support.dart';

/// A deterministic, solvable-by-play bubble field. The staggered rows model the
/// classic hex-neighbour layout; every tenth-level variation remains distinct
/// for the first 300 rounds of that level.
class BubbleShooterPuzzle {
  const BubbleShooterPuzzle({
    required this.level,
    required this.variant,
    required this.rows,
    required this.colorCount,
    required this.shotLimit,
    required this.cells,
  });

  static const int columns = 8;
  static const int maxRows = 12;

  final int level;
  final int variant;
  final int rows;
  final int colorCount;
  final int shotLimit;
  final List<int?> cells;

  String get signature => cells.map((int? value) => value ?? '.').join();

  static int colorCountForLevel(int level) => switch (level) {
    <= 2 => 3,
    <= 5 => 4,
    <= 8 => 5,
    _ => 6,
  };

  static int rowsForLevel(int level) => switch (level) {
    <= 2 => 7,
    <= 4 => 8,
    <= 6 => 9,
    <= 8 => 10,
    9 => 11,
    _ => maxRows,
  };

  static int shotLimitForLevel(int level) => switch (level) {
    <= 2 => 44,
    <= 4 => 40,
    <= 6 => 36,
    <= 8 => 32,
    9 => 29,
    _ => 26,
  };

  static bool isValidCell(int row, int column) =>
      row >= 0 &&
      row < maxRows &&
      column >= 0 &&
      column < columns &&
      (row.isEven || column < columns - 1);

  static BubbleShooterPuzzle generate(int level, int variant) {
    final int safeLevel = level.clamp(1, 10).toInt();
    final int rows = rowsForLevel(safeLevel);
    final int colors = colorCountForLevel(safeLevel);
    final Random random = Random(
      mixedSeed('bubble_shooter', safeLevel, variant),
    );
    final List<int?> cells = List<int?>.filled(maxRows * columns, null);

    for (int row = 0; row < rows; row++) {
      final int count = row.isEven ? columns : columns - 1;
      for (int column = 0; column < count; column++) {
        // The first cells make every color represented without making every
        // opening shot depend on a lucky random draw.
        final int color = row == 0 && column < colors
            ? column
            : random.nextInt(colors);
        cells[row * columns + column] = color;
      }
    }

    return BubbleShooterPuzzle(
      level: safeLevel,
      variant: variant,
      rows: rows,
      colorCount: colors,
      shotLimit: shotLimitForLevel(safeLevel),
      cells: List<int?>.unmodifiable(cells),
    );
  }
}

class BubbleShotResult {
  const BubbleShotResult({
    required this.placed,
    required this.matched,
    required this.fallen,
    this.removedBubbles = const <(int, int, int)>[],
  });

  final bool placed;
  final int matched;
  final int fallen;

  /// Board coordinates and colors removed by this shot, for pop feedback.
  final List<(int, int, int)> removedBubbles;

  bool get popped => matched >= 3;
}

/// Rules engine kept separate from the screen so collision results, cluster
/// removal and floating-bubble drops can be tested without rendering a frame.
class BubbleShooterEngine {
  BubbleShooterEngine(BubbleShooterPuzzle puzzle)
    : puzzle = puzzle,
      cells = List<int?>.of(puzzle.cells);

  final BubbleShooterPuzzle puzzle;
  final List<int?> cells;

  int get occupiedCount => cells.whereType<int>().length;
  bool get isCleared => occupiedCount == 0;

  int? at(int row, int column) => BubbleShooterPuzzle.isValidCell(row, column)
      ? cells[row * BubbleShooterPuzzle.columns + column]
      : null;

  List<(int, int)> neighbors(int row, int column) {
    final List<(int, int)> result = <(int, int)>[
      (row, column - 1),
      (row, column + 1),
      if (row.isEven) ...<(int, int)>[
        (row - 1, column - 1),
        (row - 1, column),
        (row + 1, column - 1),
        (row + 1, column),
      ] else ...<(int, int)>[
        (row - 1, column),
        (row - 1, column + 1),
        (row + 1, column),
        (row + 1, column + 1),
      ],
    ];
    return result
        .where(
          ((int, int) cell) =>
              BubbleShooterPuzzle.isValidCell(cell.$1, cell.$2),
        )
        .toList(growable: false);
  }

  BubbleShotResult fire({
    required int row,
    required int column,
    required int color,
  }) {
    if (!BubbleShooterPuzzle.isValidCell(row, column) ||
        at(row, column) != null) {
      return const BubbleShotResult(placed: false, matched: 0, fallen: 0);
    }

    cells[row * BubbleShooterPuzzle.columns + column] = color;
    final Set<(int, int)> cluster = _matchingCluster(row, column, color);
    if (cluster.length < 3) {
      return const BubbleShotResult(placed: true, matched: 0, fallen: 0);
    }

    final List<(int, int, int)> removed = cluster
        .map(
          ((int, int) cell) =>
              (cell.$1, cell.$2, at(cell.$1, cell.$2) ?? color),
        )
        .toList(growable: true);
    for (final (int, int) cell in cluster) {
      cells[cell.$1 * BubbleShooterPuzzle.columns + cell.$2] = null;
    }
    final List<(int, int, int)> fallenBubbles = _dropFloatingBubbles();
    removed.addAll(fallenBubbles);
    return BubbleShotResult(
      placed: true,
      matched: cluster.length,
      fallen: fallenBubbles.length,
      removedBubbles: List<(int, int, int)>.unmodifiable(removed),
    );
  }

  Set<(int, int)> _matchingCluster(int row, int column, int color) {
    final Set<(int, int)> seen = <(int, int)>{(row, column)};
    final List<(int, int)> queue = <(int, int)>[(row, column)];
    for (int cursor = 0; cursor < queue.length; cursor++) {
      for (final (int, int) neighbor in neighbors(
        queue[cursor].$1,
        queue[cursor].$2,
      )) {
        if (at(neighbor.$1, neighbor.$2) != color || !seen.add(neighbor)) {
          continue;
        }
        queue.add(neighbor);
      }
    }
    return seen;
  }

  List<(int, int, int)> _dropFloatingBubbles() {
    final Set<(int, int)> connected = <(int, int)>{};
    final List<(int, int)> queue = <(int, int)>[];
    for (int column = 0; column < BubbleShooterPuzzle.columns; column++) {
      if (at(0, column) != null) {
        connected.add((0, column));
        queue.add((0, column));
      }
    }
    for (int cursor = 0; cursor < queue.length; cursor++) {
      for (final (int, int) neighbor in neighbors(
        queue[cursor].$1,
        queue[cursor].$2,
      )) {
        if (at(neighbor.$1, neighbor.$2) != null && connected.add(neighbor)) {
          queue.add(neighbor);
        }
      }
    }

    final List<(int, int, int)> fallen = <(int, int, int)>[];
    for (int row = 0; row < BubbleShooterPuzzle.maxRows; row++) {
      for (int column = 0; column < BubbleShooterPuzzle.columns; column++) {
        final int? color = cells[row * BubbleShooterPuzzle.columns + column];
        if (color == null || connected.contains((row, column))) continue;
        fallen.add((row, column, color));
        cells[row * BubbleShooterPuzzle.columns + column] = null;
      }
    }
    return fallen;
  }
}
