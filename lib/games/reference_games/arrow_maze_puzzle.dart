import 'dart:math';

import 'package:flutter/material.dart';

enum MazeDirection { up, right, down, left }

extension MazeDirectionGeometry on MazeDirection {
  int get dx => switch (this) {
    MazeDirection.left => -1,
    MazeDirection.right => 1,
    _ => 0,
  };
  int get dy => switch (this) {
    MazeDirection.up => -1,
    MazeDirection.down => 1,
    _ => 0,
  };
  MazeDirection get opposite => MazeDirection.values[(index + 2) % 4];
  IconData get icon => switch (this) {
    MazeDirection.up => Icons.north_rounded,
    MazeDirection.right => Icons.east_rounded,
    MazeDirection.down => Icons.south_rounded,
    MazeDirection.left => Icons.west_rounded,
  };
}

class ArrowMazePuzzle {
  const ArrowMazePuzzle({
    required this.width,
    required this.height,
    required this.walls,
    required this.path,
    required this.arrows,
  });
  final int width;
  final int height;

  /// Each cell stores the open neighboring cell indices.
  final List<Set<int>> walls;
  final List<int> path;
  final List<MazeDirection> arrows;

  /// Returns the neighbouring cell only when the move stays in the board and
  /// the generated maze has an open passage between the two cells. Keeping
  /// this rule on the puzzle itself prevents the renderer and the move button
  /// from disagreeing about which directions are usable.
  int? nextCell(int cell, MazeDirection direction) {
    final int x = cell % width + direction.dx;
    final int y = cell ~/ width + direction.dy;
    if (x < 0 || x >= width || y < 0 || y >= height) return null;
    final int next = y * width + x;
    return walls[cell].contains(next) ? next : null;
  }

  bool isWall(int cell, MazeDirection direction) =>
      nextCell(cell, direction) == null;

  String get signature =>
      '$width:$height:${walls.map((Set<int> edges) => (edges.toList()..sort()).join(',')).join(';')}:${arrows.map((MazeDirection d) => d.index).join()}';

  static ArrowMazePuzzle generate(int level, int variant) {
    final int width = level <= 3
        ? 5
        : level <= 6
        ? 6
        : level <= 8
        ? 7
        : 8;
    final int height = width;
    final Random random = Random(0x4152524F ^ level * 7919 ^ variant * 104729);
    final int total = width * height;
    final List<Set<int>> passages = List<Set<int>>.generate(
      total,
      (_) => <int>{},
    );
    final List<bool> visited = List<bool>.filled(total, false);
    final List<int> stack = <int>[0];
    visited[0] = true;
    while (stack.isNotEmpty) {
      final int current = stack.last;
      final int x = current % width, y = current ~/ width;
      final List<int> choices = <int>[];
      for (final MazeDirection direction in MazeDirection.values) {
        final int nx = x + direction.dx, ny = y + direction.dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        final int next = ny * width + nx;
        if (!visited[next]) choices.add(next);
      }
      if (choices.isEmpty) {
        stack.removeLast();
        continue;
      }
      choices.shuffle(random);
      final int next = choices.first;
      visited[next] = true;
      passages[current].add(next);
      passages[next].add(current);
      stack.add(next);
    }
    final List<int> previous = List<int>.filled(total, -1);
    final List<int> queue = <int>[0];
    previous[0] = 0;
    for (int cursor = 0; cursor < queue.length; cursor++) {
      final int at = queue[cursor];
      for (final int next in passages[at]) {
        if (previous[next] != -1) continue;
        previous[next] = at;
        queue.add(next);
      }
    }
    final List<int> path = <int>[];
    int at = total - 1;
    while (at != 0) {
      path.add(at);
      at = previous[at];
    }
    path.add(0);
    final List<int> solution = path.reversed.toList(growable: false);

    List<MazeDirection> openDirectionsFor(int cell) {
      final int x = cell % width;
      final int y = cell ~/ width;
      return MazeDirection.values
          .where((MazeDirection direction) {
            final int nextX = x + direction.dx;
            final int nextY = y + direction.dy;
            if (nextX < 0 || nextX >= width || nextY < 0 || nextY >= height) {
              return false;
            }
            return passages[cell].contains(nextY * width + nextX);
          })
          .toList(growable: true);
    }

    // Every starting arrow must enter a real corridor. A blocked initial
    // arrow made the primary move button look broken at otherwise valid
    // levels, especially at border and dead-end cells.
    final List<MazeDirection> arrows = List<MazeDirection>.generate(
      total,
      (int i) {
        final List<MazeDirection> open = openDirectionsFor(i);
        return open[random.nextInt(open.length)];
      },
    );
    for (int i = 0; i < solution.length - 1; i++) {
      final int from = solution[i], to = solution[i + 1];
      final MazeDirection solutionDirection = MazeDirection.values.firstWhere(
        (MazeDirection d) =>
            from % width + d.dx == to % width &&
            from ~/ width + d.dy == to ~/ width,
      );
      arrows[from] = solutionDirection;
      final double scrambleChance = level >= 9
          ? .62
          : level >= 7
          ? .48
          : level >= 4
          ? .28
          : .12;
      if (random.nextDouble() < scrambleChance) {
        final List<MazeDirection> alternatives = openDirectionsFor(from)
          ..remove(solutionDirection);
        if (alternatives.isNotEmpty) {
          arrows[from] = alternatives[random.nextInt(alternatives.length)];
        }
      }
    }
    return ArrowMazePuzzle(
      width: width,
      height: height,
      walls: passages,
      path: solution,
      arrows: arrows,
    );
  }
}
