import 'dart:math' as math;

const int reversiBoardSide = 8;
const int reversiBoardSize = reversiBoardSide * reversiBoardSide;

abstract final class ReversiStone {
  static const int empty = 0;
  static const int dark = 1;
  static const int light = -1;
}

class ReversiPosition {
  ReversiPosition({required List<int> board, required this.toMove})
    : board = List<int>.unmodifiable(board) {
    if (board.length != reversiBoardSize ||
        board.any((int cell) => cell < -1 || cell > 1) ||
        (toMove != ReversiStone.dark && toMove != ReversiStone.light)) {
      throw ArgumentError('Invalid Reversi position.');
    }
  }

  factory ReversiPosition.standard() {
    final List<int> board = List<int>.filled(reversiBoardSize, 0);
    board[3 * 8 + 3] = ReversiStone.light;
    board[3 * 8 + 4] = ReversiStone.dark;
    board[4 * 8 + 3] = ReversiStone.dark;
    board[4 * 8 + 4] = ReversiStone.light;
    return ReversiPosition(board: board, toMove: ReversiStone.dark);
  }

  final List<int> board;
  final int toMove;

  int get darkCount =>
      board.where((int cell) => cell == ReversiStone.dark).length;
  int get lightCount =>
      board.where((int cell) => cell == ReversiStone.light).length;
  int get occupiedCount => darkCount + lightCount;
  bool get isTerminal =>
      legalMovesFor(ReversiStone.dark).isEmpty &&
      legalMovesFor(ReversiStone.light).isEmpty;

  List<int> legalMoves() => legalMovesFor(toMove);

  List<int> legalMovesFor(int player) {
    final List<int> moves = <int>[];
    for (int cell = 0; cell < board.length; cell++) {
      if (board[cell] == ReversiStone.empty &&
          flipsFor(cell, player).isNotEmpty) {
        moves.add(cell);
      }
    }
    return moves;
  }

  List<int> flipsFor(int cell, int player) {
    if (cell < 0 ||
        cell >= reversiBoardSize ||
        (player != ReversiStone.dark && player != ReversiStone.light) ||
        board[cell] != ReversiStone.empty) {
      return const <int>[];
    }
    final List<int> flips = <int>[];
    final int row = cell ~/ reversiBoardSide;
    final int column = cell % reversiBoardSide;
    for (int rowStep = -1; rowStep <= 1; rowStep++) {
      for (int columnStep = -1; columnStep <= 1; columnStep++) {
        if (rowStep == 0 && columnStep == 0) continue;
        final List<int> line = <int>[];
        int nextRow = row + rowStep;
        int nextColumn = column + columnStep;
        while (_inside(nextRow, nextColumn)) {
          final int nextCell = nextRow * reversiBoardSide + nextColumn;
          final int occupant = board[nextCell];
          if (occupant == -player) {
            line.add(nextCell);
          } else if (occupant == player) {
            if (line.isNotEmpty) flips.addAll(line);
            break;
          } else {
            break;
          }
          nextRow += rowStep;
          nextColumn += columnStep;
        }
      }
    }
    return flips;
  }

  ReversiPosition play(int cell) {
    final List<int> flips = flipsFor(cell, toMove);
    if (flips.isEmpty) throw ArgumentError('Illegal Reversi move: $cell');
    final List<int> nextBoard = List<int>.of(board);
    nextBoard[cell] = toMove;
    for (final int flipped in flips) {
      nextBoard[flipped] = toMove;
    }
    return ReversiPosition(board: nextBoard, toMove: -toMove);
  }

  ReversiPosition pass() => ReversiPosition(board: board, toMove: -toMove);

  String get signature =>
      '${toMove == ReversiStone.dark ? 'D' : 'L'}:'
      '${board.map((int cell) => cell == 1
          ? 'D'
          : cell == -1
          ? 'L'
          : '.').join()}';

  static bool _inside(int row, int column) =>
      row >= 0 &&
      row < reversiBoardSide &&
      column >= 0 &&
      column < reversiBoardSide;
}

class ReversiTurnResolution {
  const ReversiTurnResolution({
    required this.position,
    required this.passed,
    required this.ended,
  });

  final ReversiPosition position;
  final bool passed;
  final bool ended;
}

ReversiTurnResolution resolveReversiTurn(ReversiPosition position) {
  if (position.legalMoves().isNotEmpty) {
    return ReversiTurnResolution(
      position: position,
      passed: false,
      ended: false,
    );
  }
  final ReversiPosition passed = position.pass();
  if (passed.legalMoves().isNotEmpty) {
    return ReversiTurnResolution(position: passed, passed: true, ended: false);
  }
  return ReversiTurnResolution(position: position, passed: false, ended: true);
}

/// A deterministic, budgeted alpha-beta opponent. Evaluation prioritises
/// corners and mobility before raw disc count, then values stable edges late.
abstract final class ReversiEngine {
  static int chooseMove(
    ReversiPosition position, {
    required int player,
    required int difficulty,
    required int seed,
  }) {
    final List<int> moves = position.legalMovesFor(player);
    if (moves.isEmpty) throw StateError('No legal Reversi move.');

    final int level = difficulty.clamp(1, 20).toInt();
    final int depth = switch (level) {
      <= 6 => 1,
      <= 8 => 2,
      <= 14 => 3,
      <= 18 => 4,
      _ => 5,
    };
    final int budget = switch (level) {
      <= 6 => 1200,
      <= 8 => 5200,
      <= 10 => 8600,
      <= 14 => 11000,
      <= 18 => 19000,
      _ => 26000,
    };
    final math.Random random = math.Random(seed);
    moves.shuffle(random);
    moves.sort(
      (int a, int b) =>
          _moveOrder(b, position).compareTo(_moveOrder(a, position)),
    );
    // Give every legal root move a fair slice. A single difficult branch must
    // not consume the whole search budget before the opponent compares replies.
    final int branchBudget = math.max(180, budget ~/ moves.length);

    int bestScore = -0x3fffffff;
    final List<int> bestMoves = <int>[];
    int alpha = -0x3fffffff;
    for (final int move in moves) {
      final _SearchBudget searchBudget = _SearchBudget(branchBudget);
      final ReversiTurnResolution next = resolveReversiTurn(
        position.play(move),
      );
      final int score = _search(
        next.position,
        depth - 1,
        player,
        alpha,
        0x3fffffff,
        searchBudget,
        next.ended,
      );
      if (score > bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(move);
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
      if (score > alpha) alpha = score;
    }
    return bestMoves[random.nextInt(bestMoves.length)];
  }

  static int _search(
    ReversiPosition position,
    int depth,
    int perspective,
    int alpha,
    int beta,
    _SearchBudget budget,
    bool ended,
  ) {
    if (ended || depth <= 0 || budget.exhausted) {
      return evaluate(position, perspective);
    }
    budget.visit();
    List<int> moves = position.legalMoves();
    if (moves.isEmpty) {
      final ReversiTurnResolution pass = resolveReversiTurn(position);
      if (pass.ended) return evaluate(position, perspective);
      return _search(
        pass.position,
        depth,
        perspective,
        alpha,
        beta,
        budget,
        false,
      );
    }
    moves.sort(
      (int a, int b) =>
          _moveOrder(b, position).compareTo(_moveOrder(a, position)),
    );
    final bool maximizing = position.toMove == perspective;
    int best = maximizing ? -0x3fffffff : 0x3fffffff;
    for (final int move in moves) {
      final ReversiTurnResolution next = resolveReversiTurn(
        position.play(move),
      );
      final int score = _search(
        next.position,
        depth - 1,
        perspective,
        alpha,
        beta,
        budget,
        next.ended,
      );
      if (maximizing) {
        if (score > best) best = score;
        if (best > alpha) alpha = best;
      } else {
        if (score < best) best = score;
        if (best < beta) beta = best;
      }
      if (beta <= alpha || budget.exhausted) break;
    }
    return best;
  }

  static int evaluate(ReversiPosition position, int perspective) {
    const List<int> positionalWeights = <int>[
      120,
      -28,
      18,
      8,
      8,
      18,
      -28,
      120,
      -28,
      -42,
      -4,
      -4,
      -4,
      -4,
      -42,
      -28,
      18,
      -4,
      12,
      4,
      4,
      12,
      -4,
      18,
      8,
      -4,
      4,
      2,
      2,
      4,
      -4,
      8,
      8,
      -4,
      4,
      2,
      2,
      4,
      -4,
      8,
      18,
      -4,
      12,
      4,
      4,
      12,
      -4,
      18,
      -28,
      -42,
      -4,
      -4,
      -4,
      -4,
      -42,
      -28,
      120,
      -28,
      18,
      8,
      8,
      18,
      -28,
      120,
    ];
    final int occupied = position.occupiedCount;
    final int empty = reversiBoardSize - occupied;
    int positionScore = 0;
    int frontier = 0;
    for (int cell = 0; cell < reversiBoardSize; cell++) {
      final int stone = position.board[cell];
      if (stone == ReversiStone.empty) continue;
      positionScore += stone * positionalWeights[cell];
      if (_isFrontier(position, cell)) frontier += stone;
    }
    final int mobility =
        position.legalMovesFor(ReversiStone.light).length -
        position.legalMovesFor(ReversiStone.dark).length;
    final int discDifference = position.lightCount - position.darkCount;
    final int discWeight = empty <= 14
        ? 7
        : empty <= 30
        ? 2
        : 1;
    final int score =
        positionScore +
        mobility * 9 +
        discDifference * discWeight -
        frontier * 3;
    return perspective == ReversiStone.light ? score : -score;
  }

  static bool _isFrontier(ReversiPosition position, int cell) {
    final int row = cell ~/ 8;
    final int column = cell % 8;
    for (int rowStep = -1; rowStep <= 1; rowStep++) {
      for (int columnStep = -1; columnStep <= 1; columnStep++) {
        if (rowStep == 0 && columnStep == 0) continue;
        final int nextRow = row + rowStep;
        final int nextColumn = column + columnStep;
        if (nextRow >= 0 &&
            nextRow < 8 &&
            nextColumn >= 0 &&
            nextColumn < 8 &&
            position.board[nextRow * 8 + nextColumn] == ReversiStone.empty) {
          return true;
        }
      }
    }
    return false;
  }

  static int _moveOrder(int move, ReversiPosition position) {
    const Set<int> corners = <int>{0, 7, 56, 63};
    if (corners.contains(move)) return 10000;
    final int row = move ~/ 8;
    final int column = move % 8;
    final bool edge = row == 0 || row == 7 || column == 0 || column == 7;
    final int flips = position.flipsFor(move, position.toMove).length;
    return (edge ? 300 : 0) + flips;
  }
}

class _SearchBudget {
  _SearchBudget(this.limit);

  final int limit;
  int visited = 0;

  bool get exhausted => visited >= limit;

  void visit() => visited++;
}
