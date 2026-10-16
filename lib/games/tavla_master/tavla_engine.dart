import 'dart:math' as math;

abstract final class TavlaPoint {
  static const int bar = -1;
  static const int off = -2;
}

abstract final class TavlaSide {
  static const int white = 1;
  static const int black = -1;
}

class TavlaMove {
  const TavlaMove({
    required this.from,
    required this.to,
    required this.die,
    this.hit = false,
    this.bearOff = false,
  });

  final int from;
  final int to;
  final int die;
  final bool hit;
  final bool bearOff;

  String get signature => '$from>$to@$die';

  @override
  bool operator ==(Object other) =>
      other is TavlaMove &&
      other.from == from &&
      other.to == to &&
      other.die == die;

  @override
  int get hashCode => Object.hash(from, to, die);
}

/// Immutable 24-point backgammon state. Positive checkers move toward point 0;
/// negative checkers move toward point 23. A blot is hit to the bar.
class TavlaPosition {
  TavlaPosition({
    required List<int> points,
    required this.whiteBar,
    required this.blackBar,
    required this.whiteOff,
    required this.blackOff,
  }) : points = List<int>.unmodifiable(points) {
    if (points.length != 24 ||
        points.any((int count) => count.abs() > 15) ||
        whiteBar < 0 ||
        blackBar < 0 ||
        whiteOff < 0 ||
        blackOff < 0 ||
        _checkerTotal(TavlaSide.white) != 15 ||
        _checkerTotal(TavlaSide.black) != 15) {
      throw ArgumentError('Invalid backgammon position.');
    }
  }

  factory TavlaPosition.standard() {
    final List<int> points = List<int>.filled(24, 0);
    points[23] = 2;
    points[12] = 5;
    points[7] = 3;
    points[5] = 5;
    points[0] = -2;
    points[11] = -5;
    points[16] = -3;
    points[18] = -5;
    return TavlaPosition(
      points: points,
      whiteBar: 0,
      blackBar: 0,
      whiteOff: 0,
      blackOff: 0,
    );
  }

  final List<int> points;
  final int whiteBar;
  final int blackBar;
  final int whiteOff;
  final int blackOff;

  int barFor(int side) => side == TavlaSide.white ? whiteBar : blackBar;
  int offFor(int side) => side == TavlaSide.white ? whiteOff : blackOff;

  int checkersOnBoard(int side) => points.fold<int>(
    0,
    (int total, int count) => total + math.max(0, count * side),
  );

  int _checkerTotal(int side) =>
      checkersOnBoard(side) + barFor(side) + offFor(side);

  bool get whiteWon => whiteOff == 15;
  bool get blackWon => blackOff == 15;
  bool wonBy(int side) => side == TavlaSide.white ? whiteWon : blackWon;

  int pipCount(int side) {
    int total = barFor(side) * 25;
    for (int point = 0; point < points.length; point++) {
      total +=
          math.max(0, points[point] * side) *
          (side == TavlaSide.white ? point + 1 : 24 - point);
    }
    return total;
  }

  List<TavlaMove> legalMovesForDie(int side, int die) {
    if ((side != TavlaSide.white && side != TavlaSide.black) ||
        die < 1 ||
        die > 6 ||
        whiteWon ||
        blackWon) {
      return const <TavlaMove>[];
    }
    final List<TavlaMove> moves = <TavlaMove>[];
    if (barFor(side) > 0) {
      final int entry = side == TavlaSide.white ? 24 - die : die - 1;
      if (_canLand(entry, side)) {
        moves.add(
          TavlaMove(
            from: TavlaPoint.bar,
            to: entry,
            die: die,
            hit: points[entry] == -side,
          ),
        );
      }
      return moves;
    }

    for (int point = 0; point < 24; point++) {
      if (points[point] * side <= 0) continue;
      final int destination = point - side * die;
      if (destination >= 0 && destination < 24) {
        if (_canLand(destination, side)) {
          moves.add(
            TavlaMove(
              from: point,
              to: destination,
              die: die,
              hit: points[destination] == -side,
            ),
          );
        }
        continue;
      }
      if (_canBearOff(side, point, die)) {
        moves.add(
          TavlaMove(from: point, to: TavlaPoint.off, die: die, bearOff: true),
        );
      }
    }
    return moves;
  }

  List<List<TavlaMove>> legalTurnSequences(int side, int dieA, int dieB) {
    if (dieA < 1 || dieA > 6 || dieB < 1 || dieB > 6) {
      throw ArgumentError('Dice must be between one and six.');
    }
    final List<int> dice = dieA == dieB
        ? <int>[dieA, dieA, dieA, dieA]
        : <int>[dieA, dieB];
    final List<List<TavlaMove>> found = <List<TavlaMove>>[];

    void search(
      TavlaPosition position,
      List<int> remaining,
      List<TavlaMove> path,
    ) {
      if (remaining.isEmpty) {
        found.add(List<TavlaMove>.unmodifiable(path));
        return;
      }
      bool moved = false;
      final Set<int> triedDice = <int>{};
      for (int index = 0; index < remaining.length; index++) {
        final int die = remaining[index];
        if (!triedDice.add(die)) continue;
        final List<TavlaMove> legal = position.legalMovesForDie(side, die);
        if (legal.isEmpty) continue;
        moved = true;
        final List<int> nextDice = List<int>.of(remaining)..removeAt(index);
        for (final TavlaMove move in legal) {
          search(position._apply(move, side), nextDice, <TavlaMove>[
            ...path,
            move,
          ]);
        }
      }
      if (!moved) found.add(List<TavlaMove>.unmodifiable(path));
    }

    search(this, dice, <TavlaMove>[]);
    final int maximumMoves = found.fold<int>(
      0,
      (int maxLength, List<TavlaMove> sequence) =>
          math.max(maxLength, sequence.length),
    );
    List<List<TavlaMove>> best = found
        .where((List<TavlaMove> sequence) => sequence.length == maximumMoves)
        .toList(growable: false);

    // When only one of two different dice can be played, standard rules require
    // the higher die if it is independently playable.
    if (dieA != dieB && maximumMoves == 1) {
      final int high = math.max(dieA, dieB);
      final int low = math.min(dieA, dieB);
      if (legalMovesForDie(side, high).isNotEmpty &&
          legalMovesForDie(side, low).isNotEmpty) {
        best = best
            .where((List<TavlaMove> sequence) => sequence.single.die == high)
            .toList(growable: false);
      }
    }
    final Map<String, List<TavlaMove>> distinct = <String, List<TavlaMove>>{};
    for (final List<TavlaMove> sequence in best) {
      distinct.putIfAbsent(
        sequence.map((TavlaMove move) => move.signature).join(','),
        () => sequence,
      );
    }
    return List<List<TavlaMove>>.unmodifiable(distinct.values);
  }

  TavlaPosition play(TavlaMove move, int side) {
    if (!legalMovesForDie(side, move.die).contains(move)) {
      throw ArgumentError('Illegal backgammon move ${move.signature}.');
    }
    return _apply(move, side);
  }

  TavlaPosition playTurn(
    int side,
    List<TavlaMove> moves, {
    required int dieA,
    required int dieB,
  }) {
    if (moves.isEmpty) throw ArgumentError('A turn must play a legal die.');
    final List<List<TavlaMove>> legalTurns = legalTurnSequences(
      side,
      dieA,
      dieB,
    );
    final bool isLegal = legalTurns.any(
      (List<TavlaMove> sequence) => _sameMoves(sequence, moves),
    );
    if (!isLegal) throw ArgumentError('Illegal or incomplete dice sequence.');
    TavlaPosition position = this;
    for (final TavlaMove move in moves) {
      position = position._apply(move, side);
    }
    return position;
  }

  TavlaPosition _apply(TavlaMove move, int side) {
    final List<int> nextPoints = List<int>.of(points);
    int nextWhiteBar = whiteBar;
    int nextBlackBar = blackBar;
    int nextWhiteOff = whiteOff;
    int nextBlackOff = blackOff;
    if (move.from == TavlaPoint.bar) {
      if (side == TavlaSide.white) {
        nextWhiteBar--;
      } else {
        nextBlackBar--;
      }
    } else {
      nextPoints[move.from] -= side;
    }
    if (move.bearOff) {
      if (side == TavlaSide.white) {
        nextWhiteOff++;
      } else {
        nextBlackOff++;
      }
    } else {
      if (nextPoints[move.to] == -side) {
        nextPoints[move.to] = 0;
        if (side == TavlaSide.white) {
          nextBlackBar++;
        } else {
          nextWhiteBar++;
        }
      }
      nextPoints[move.to] += side;
    }
    return TavlaPosition(
      points: nextPoints,
      whiteBar: nextWhiteBar,
      blackBar: nextBlackBar,
      whiteOff: nextWhiteOff,
      blackOff: nextBlackOff,
    );
  }

  bool _canLand(int point, int side) => points[point] * side >= -1;

  bool _canBearOff(int side, int point, int die) {
    if (!_allHome(side)) return false;
    if (side == TavlaSide.white) {
      final int distance = point + 1;
      if (die < distance) return false;
      return die == distance || !_hasOwnCheckerOn(side, point + 1, 5);
    }
    final int distance = 24 - point;
    if (die < distance) return false;
    return die == distance || !_hasOwnCheckerOn(side, 18, point - 1);
  }

  bool _allHome(int side) {
    if (barFor(side) > 0) return false;
    final int start = side == TavlaSide.white ? 0 : 18;
    for (int point = 0; point < 24; point++) {
      if (points[point] * side > 0 && (point < start || point >= start + 6)) {
        return false;
      }
    }
    return true;
  }

  bool _hasOwnCheckerOn(int side, int from, int to) {
    if (from > to) return false;
    for (int point = from; point <= to; point++) {
      if (points[point] * side > 0) return true;
    }
    return false;
  }

  String get signature =>
      '${points.join(',')}|$whiteBar|$blackBar|$whiteOff|$blackOff';

  static bool _sameMoves(List<TavlaMove> left, List<TavlaMove> right) {
    if (left.length != right.length) return false;
    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

abstract final class TavlaEngine {
  static List<TavlaMove> chooseTurn(
    TavlaPosition position,
    int side,
    List<List<TavlaMove>> legalTurns, {
    int strategyLevel = 1,
  }) {
    if (legalTurns.isEmpty) throw ArgumentError('No legal turn to choose.');
    final List<({List<TavlaMove> moves, TavlaPosition after, int score})>
    candidates = <({List<TavlaMove> moves, TavlaPosition after, int score})>[];
    for (final List<TavlaMove> sequence in legalTurns) {
      TavlaPosition after = position;
      for (final TavlaMove move in sequence) {
        after = after.play(move, side);
      }
      candidates.add((
        moves: sequence,
        after: after,
        score: _evaluateTurn(position, after, side, sequence),
      ));
    }
    candidates.sort((left, right) => right.score.compareTo(left.score));
    if (strategyLevel < 9) return candidates.first.moves;

    // Expert opponents consider the likely tactical reply, not just the
    // immediate pip gain. The final four levels evaluate every unordered
    // dice result with its actual 1/36 or 2/36 probability.
    final List<({int a, int b, int weight})> replyRolls = strategyLevel >= 17
        ? <({int a, int b, int weight})>[
            for (int a = 1; a <= 6; a++)
              for (int b = a; b <= 6; b++) (a: a, b: b, weight: a == b ? 1 : 2),
          ]
        : <({int a, int b, int weight})>[
            (a: 1, b: 2, weight: 1),
            (a: 1, b: 4, weight: 1),
            (a: 2, b: 5, weight: 1),
            (a: 3, b: 6, weight: 1),
            (a: 4, b: 5, weight: 1),
            (a: 1, b: 1, weight: 1),
            (a: 3, b: 3, weight: 1),
            (a: 6, b: 6, weight: 1),
          ];
    final int candidateLimit = strategyLevel >= 17 ? 6 : 4;
    final double replyRiskWeight = strategyLevel >= 17 ? .48 : .34;
    int bestScore = -0x7fffffff;
    List<TavlaMove> best = candidates.first.moves;
    for (final ({List<TavlaMove> moves, TavlaPosition after, int score})
        candidate
        in candidates.take(candidateLimit)) {
      int weightedReplyScore = 0;
      int totalWeight = 0;
      for (final ({int a, int b, int weight}) roll in replyRolls) {
        final List<List<TavlaMove>> replies = candidate.after
            .legalTurnSequences(-side, roll.a, roll.b);
        int bestReply = 0;
        for (final List<TavlaMove> reply in replies) {
          TavlaPosition replyPosition = candidate.after;
          for (final TavlaMove move in reply) {
            replyPosition = replyPosition.play(move, -side);
          }
          bestReply = math.max(
            bestReply,
            _evaluateTurn(candidate.after, replyPosition, -side, reply),
          );
        }
        weightedReplyScore += bestReply * roll.weight;
        totalWeight += roll.weight;
      }
      final int score =
          candidate.score -
          (weightedReplyScore / totalWeight * replyRiskWeight).round();
      if (score > bestScore) {
        bestScore = score;
        best = candidate.moves;
      }
    }
    return best;
  }

  static int _evaluateTurn(
    TavlaPosition before,
    TavlaPosition after,
    int side,
    List<TavlaMove> sequence,
  ) {
    final int pipGain = before.pipCount(side) - after.pipCount(side);
    final int offGain = after.offFor(side) - before.offFor(side);
    final int barGain = before.barFor(side) - after.barFor(side);
    final int opponentBarGain = after.barFor(-side) - before.barFor(-side);
    int madePoints = 0;
    int exposedBlots = 0;
    for (int point = 0; point < 24; point++) {
      if (before.points[point] * side < 2 && after.points[point] * side >= 2) {
        madePoints++;
      }
      if (before.points[point] * side != 1 && after.points[point] * side == 1) {
        exposedBlots++;
      }
    }
    return pipGain +
        offGain * 36 +
        barGain * 42 +
        opponentBarGain * 48 +
        madePoints * 9 -
        exposedBlots * 6 +
        sequence.length * 5;
  }
}
