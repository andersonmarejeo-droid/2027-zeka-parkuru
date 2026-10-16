import 'dart:collection';
import 'dart:math' as math;

import '../shared/content_seed.dart';

enum HexSide {
  red(1),
  blue(2);

  const HexSide(this.value);

  final int value;
  HexSide get opposite => this == HexSide.red ? HexSide.blue : HexSide.red;
}

class HexPosition {
  HexPosition({
    required this.size,
    required List<int> cells,
    required this.nextSide,
  }) : cells = List<int>.unmodifiable(cells) {
    if (size < 4 || size > 9 || cells.length != size * size) {
      throw ArgumentError('Hex board must be a 4×4 through 9×9 rhombus.');
    }
    if (cells.any((int value) => value < 0 || value > 2)) {
      throw ArgumentError('Hex cells are empty, red or blue.');
    }
  }

  final int size;
  final List<int> cells;
  final HexSide nextSide;

  int get redCount =>
      cells.where((int cell) => cell == HexSide.red.value).length;
  int get blueCount =>
      cells.where((int cell) => cell == HexSide.blue.value).length;
  int get emptyCount => cells.where((int cell) => cell == 0).length;
  String get signature => '$size:${cells.join()}';
  List<int> get legalMoves => <int>[
    for (int index = 0; index < cells.length; index++)
      if (cells[index] == 0) index,
  ];

  HexSide? get winner {
    for (final HexSide side in HexSide.values) {
      if (hasConnection(side)) return side;
    }
    return null;
  }

  HexPosition? play(int index) {
    if (winner != null ||
        index < 0 ||
        index >= cells.length ||
        cells[index] != 0) {
      return null;
    }
    final List<int> next = List<int>.of(cells)..[index] = nextSide.value;
    return HexPosition(size: size, cells: next, nextSide: nextSide.opposite);
  }

  bool hasConnection(HexSide side) {
    final List<int> frontier = <int>[];
    final List<bool> visited = List<bool>.filled(cells.length, false);
    if (side == HexSide.red) {
      for (int column = 0; column < size; column++) {
        final int start = column;
        if (cells[start] == side.value) {
          visited[start] = true;
          frontier.add(start);
        }
      }
    } else {
      for (int row = 0; row < size; row++) {
        final int start = row * size;
        if (cells[start] == side.value) {
          visited[start] = true;
          frontier.add(start);
        }
      }
    }
    for (int cursor = 0; cursor < frontier.length; cursor++) {
      final int cell = frontier[cursor];
      final int row = cell ~/ size;
      final int column = cell % size;
      if (side == HexSide.red && row == size - 1) return true;
      if (side == HexSide.blue && column == size - 1) return true;
      for (final int neighbor in _neighbors(cell)) {
        if (!visited[neighbor] && cells[neighbor] == side.value) {
          visited[neighbor] = true;
          frontier.add(neighbor);
        }
      }
    }
    return false;
  }

  int shortestConnectionCost(HexSide side) {
    const int blocked = 1000000;
    final List<int> distances = List<int>.filled(cells.length, blocked);
    final Queue<int> frontier = Queue<int>();
    final List<int> starts = <int>[];
    if (side == HexSide.red) {
      starts.addAll(List<int>.generate(size, (int column) => column));
    } else {
      starts.addAll(List<int>.generate(size, (int row) => row * size));
    }
    int costOf(int cell) => cells[cell] == side.value
        ? 0
        : cells[cell] == 0
        ? 1
        : blocked;
    for (final int start in starts) {
      distances[start] = costOf(start);
      if (distances[start] == 0) {
        frontier.addFirst(start);
      } else if (distances[start] < blocked) {
        frontier.addLast(start);
      }
    }
    while (frontier.isNotEmpty) {
      final int current = frontier.removeFirst();
      final int distance = distances[current];
      for (final int neighbor in _neighbors(current)) {
        final int entryCost = costOf(neighbor);
        if (entryCost == blocked) continue;
        final int candidate = distance + entryCost;
        if (candidate >= distances[neighbor]) continue;
        distances[neighbor] = candidate;
        if (entryCost == 0) {
          frontier.addFirst(neighbor);
        } else {
          frontier.addLast(neighbor);
        }
      }
    }
    final List<int> goals = side == HexSide.red
        ? List<int>.generate(size, (int column) => (size - 1) * size + column)
        : List<int>.generate(size, (int row) => row * size + size - 1);
    return goals.map((int cell) => distances[cell]).reduce(math.min);
  }

  List<int> _neighbors(int cell) {
    final int row = cell ~/ size;
    final int column = cell % size;
    const List<(int, int)> directions = <(int, int)>[
      (0, -1),
      (0, 1),
      (-1, 0),
      (-1, 1),
      (1, -1),
      (1, 0),
    ];
    return <int>[
      for (final (int dr, int dc) in directions)
        if (row + dr >= 0 &&
            row + dr < size &&
            column + dc >= 0 &&
            column + dc < size)
          (row + dr) * size + column + dc,
    ];
  }
}

class HexScenario {
  const HexScenario({
    required this.level,
    required this.seed,
    required this.openingMoves,
    required this.start,
  });

  final int level;
  final int seed;
  final int openingMoves;
  final HexPosition start;

  int get size => start.size;
  String get signature => start.signature;
  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP READING',
    _ => 'MASTER HEX',
  };

  bool get isValidStart =>
      start.nextSide == HexSide.red &&
      start.winner == null &&
      start.emptyCount > 0;
}

class HexScenarioBank {
  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, HexScenario> _campaign = <int, HexScenario>{};
  static final Map<int, HexScenario> _practice = <int, HexScenario>{};

  static int sizeForLevel(int level) => switch (level) {
    >= 1 && <= 4 => 5,
    >= 5 && <= 8 => 6,
    >= 9 && <= maximumLevels => 7,
    _ => throw RangeError.range(level, 1, maximumLevels, 'level'),
  };

  static int openingMovesForLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return switch (level) {
      <= 4 => (level - 1) * 2,
      <= 8 => 2 + (level - 5) * 2,
      9 || 10 => 8 + (level - 9) * 2,
      <= 16 => 12 + ((level - 11) ~/ 2) * 2,
      _ => 18,
    };
  }

  static int searchDepthForLevel(int level) => switch (level) {
    <= 4 => 0,
    <= 8 => 1,
    <= 10 => 2,
    <= 16 => 3,
    <= 20 => 4,
    _ => throw RangeError.range(level, 1, maximumLevels, 'level'),
  };

  static Set<String> get _usedSignatures => <String>{
    ..._campaign.values.map((HexScenario scenario) => scenario.signature),
    ..._practice.values.map((HexScenario scenario) => scenario.signature),
  };

  static HexScenario forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    for (int next = 1; next <= level; next++) {
      if (_campaign.containsKey(next)) continue;
      _campaign[next] = _generate(next, cycle: 0, used: _usedSignatures);
    }
    return _campaign[level]!;
  }

  static HexScenario forPracticeBoard(int index) {
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

  static HexScenario _generate(
    int level, {
    required int cycle,
    required Set<String> used,
  }) {
    final int size = sizeForLevel(level);
    final int targetOpening = cycle == 0
        ? openingMovesForLevel(level)
        : math.min(18, openingMovesForLevel(level) + (cycle % 4 + 1) * 2);
    for (int attempt = 0; attempt < 3000; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'hex_connection:$cycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      HexPosition position = HexPosition(
        size: size,
        cells: List<int>.filled(size * size, 0),
        nextSide: HexSide.red,
      );
      final List<int> opening = position.legalMoves..shuffle(random);
      int movesPlayed = 0;
      while (movesPlayed < targetOpening && opening.isNotEmpty) {
        final int selected = opening.removeLast();
        final HexPosition? next = position.play(selected);
        if (next == null) break;
        position = next;
        movesPlayed++;
      }
      if (movesPlayed != targetOpening ||
          !HexScenario(
            level: level,
            seed: seed,
            openingMoves: targetOpening,
            start: position,
          ).isValidStart) {
        continue;
      }
      final HexScenario scenario = HexScenario(
        level: level,
        seed: seed,
        openingMoves: targetOpening,
        start: position,
      );
      if (!used.contains(scenario.signature)) return scenario;
    }
    throw StateError('Could not create a distinct non-terminal Hex layout.');
  }
}

class HexComputerPlayer {
  const HexComputerPlayer._();

  static int? chooseMove(
    HexPosition position, {
    required HexSide side,
    required int level,
    required int seed,
  }) {
    if (position.nextSide != side || position.winner != null) return null;
    final List<int> moves = _orderedMoves(position, side, 0x7FFFFFFF);
    if (moves.isEmpty) return null;
    final int depth = HexScenarioBank.searchDepthForLevel(level);
    final int branch = switch (level) {
      <= 6 => 4,
      <= 8 => 5,
      <= 10 => 6,
      <= 16 => 7,
      _ => 8,
    };
    final List<(int, int)> scored = <(int, int)>[];
    int alpha = -100001;
    int beta = 100001;
    int best = side == HexSide.blue ? -100001 : 100001;
    for (final int move in moves) {
      final HexPosition next = position.play(move)!;
      final int score = depth == 0
          ? _evaluate(next)
          : _search(
              next,
              depth: depth - 1,
              branch: branch,
              alpha: alpha,
              beta: beta,
            );
      scored.add((move, score));
      if (side == HexSide.blue) {
        best = math.max(best, score);
        alpha = math.max(alpha, best);
      } else {
        best = math.min(best, score);
        beta = math.min(beta, best);
      }
    }
    final int optimal = side == HexSide.blue
        ? scored.map(((int, int) item) => item.$2).reduce(math.max)
        : scored.map(((int, int) item) => item.$2).reduce(math.min);
    final List<int> ties = scored
        .where(((int, int) item) => item.$2 == optimal)
        .map(((int, int) item) => item.$1)
        .toList(growable: false);
    int stateHash = position.size;
    for (final int cell in position.cells) {
      stateHash = (stateHash * 31 + cell) & 0x7FFFFFFF;
    }
    return ties[math.Random(seed ^ stateHash).nextInt(ties.length)];
  }

  static int _search(
    HexPosition position, {
    required int depth,
    required int branch,
    required int alpha,
    required int beta,
  }) {
    final HexSide? winner = position.winner;
    if (winner == HexSide.blue) return 100000 + depth;
    if (winner == HexSide.red) return -100000 - depth;
    if (depth == 0) return _evaluate(position);
    final HexSide side = position.nextSide;
    final List<int> moves = _orderedMoves(position, side, branch);
    if (moves.isEmpty) return _evaluate(position);
    if (side == HexSide.blue) {
      int value = -100001;
      for (final int move in moves) {
        value = math.max(
          value,
          _search(
            position.play(move)!,
            depth: depth - 1,
            branch: branch,
            alpha: alpha,
            beta: beta,
          ),
        );
        alpha = math.max(alpha, value);
        if (alpha >= beta) break;
      }
      return value;
    }
    int value = 100001;
    for (final int move in moves) {
      value = math.min(
        value,
        _search(
          position.play(move)!,
          depth: depth - 1,
          branch: branch,
          alpha: alpha,
          beta: beta,
        ),
      );
      beta = math.min(beta, value);
      if (alpha >= beta) break;
    }
    return value;
  }

  static List<int> _orderedMoves(
    HexPosition position,
    HexSide side,
    int limit,
  ) {
    final List<(int, int)> scored = <(int, int)>[
      for (final int move in position.legalMoves)
        (move, _evaluate(position.play(move)!)),
    ];
    scored.sort(((int, int) left, (int, int) right) {
      final int comparison = left.$2.compareTo(right.$2);
      return side == HexSide.blue ? -comparison : comparison;
    });
    final Iterable<(int, int)> selected = limit >= scored.length
        ? scored
        : scored.take(limit);
    return selected.map(((int, int) item) => item.$1).toList(growable: false);
  }

  static int _evaluate(HexPosition position) {
    final HexSide? winner = position.winner;
    if (winner == HexSide.blue) return 100000;
    if (winner == HexSide.red) return -100000;
    final int red = position.shortestConnectionCost(HexSide.red);
    final int blue = position.shortestConnectionCost(HexSide.blue);
    return red - blue;
  }
}
