import 'dart:math' as math;

import '../shared/content_seed.dart';

class PegMove {
  const PegMove({required this.from, required this.over, required this.to});

  final int from;
  final int over;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is PegMove &&
      other.from == from &&
      other.over == over &&
      other.to == to;

  @override
  int get hashCode => Object.hash(from, over, to);
}

abstract final class PegSquare {
  static int index(int row, int column) => row * 7 + column;
  static int row(int cell) => cell ~/ 7;
  static int column(int cell) => cell % 7;
}

class PegSolitairePosition {
  PegSolitairePosition({required List<bool> pegs})
    : pegs = List<bool>.unmodifiable(pegs) {
    if (pegs.length != 49 ||
        pegs.asMap().entries.any(
          (MapEntry<int, bool> entry) => entry.value && !isBoardHole(entry.key),
        )) {
      throw ArgumentError('Invalid English-board Peg Solitaire position.');
    }
  }

  final List<bool> pegs;

  static const int center = 24;
  static final List<int> holes = <int>[
    for (int row = 0; row < 7; row++)
      for (int column = 0; column < 7; column++)
        if (isBoardHole(PegSquare.index(row, column)))
          PegSquare.index(row, column),
  ];

  int get pegCount => pegs.where((bool hasPeg) => hasPeg).length;
  String get signature => pegs.map((bool peg) => peg ? '1' : '0').join();
  bool contains(int cell) => cell >= 0 && cell < pegs.length && pegs[cell];

  List<PegMove> legalMoves() => <PegMove>[
    for (final PegMove move in _allMoves)
      if (pegs[move.from] && pegs[move.over] && !pegs[move.to]) move,
  ];

  PegSolitairePosition? play(PegMove move) {
    if (!legalMoves().contains(move)) return null;
    final List<bool> next = List<bool>.of(pegs);
    next[move.from] = false;
    next[move.over] = false;
    next[move.to] = true;
    return PegSolitairePosition(pegs: next);
  }

  bool isWon(int goal) => pegCount == 1 && pegs[goal];

  static bool isBoardHole(int cell) {
    if (cell < 0 || cell >= 49) return false;
    final int row = PegSquare.row(cell);
    final int column = PegSquare.column(cell);
    return (row >= 2 && row <= 4) || (column >= 2 && column <= 4);
  }

  static final List<PegMove> _allMoves = <PegMove>[
    for (int row = 0; row < 7; row++)
      for (int column = 0; column < 7; column++)
        for (final (int dr, int dc) in const <(int, int)>[
          (-2, 0),
          (2, 0),
          (0, -2),
          (0, 2),
        ])
          if (row + dr >= 0 &&
              row + dr < 7 &&
              column + dc >= 0 &&
              column + dc < 7 &&
              isBoardHole(PegSquare.index(row, column)) &&
              isBoardHole(PegSquare.index(row + dr ~/ 2, column + dc ~/ 2)) &&
              isBoardHole(PegSquare.index(row + dr, column + dc)))
            PegMove(
              from: PegSquare.index(row, column),
              over: PegSquare.index(row + dr ~/ 2, column + dc ~/ 2),
              to: PegSquare.index(row + dr, column + dc),
            ),
  ];
}

class PegSolitairePuzzle {
  PegSolitairePuzzle._({
    required this.level,
    required this.seed,
    required this.start,
    required this.goal,
    required List<PegMove> solution,
    required this.reverseSearchNodes,
  }) : solution = List<PegMove>.unmodifiable(solution);

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, PegSolitairePuzzle> _campaign =
      <int, PegSolitairePuzzle>{};
  static final Map<int, PegSolitairePuzzle> _practice =
      <int, PegSolitairePuzzle>{};

  final int level;
  final int seed;
  final PegSolitairePosition start;
  final int goal;
  final List<PegMove> solution;
  final int reverseSearchNodes;

  String get signature => '${start.signature}:$goal';
  int get targetPegCount => start.pegCount;
  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP READING',
    _ => 'MASTER SOLITAIRE',
  };

  static int targetPegsForLevel(int level) =>
      13 + ((level - 1) * 15 ~/ (maximumLevels - 1));

  static PegSolitairePuzzle forLevel(int level) {
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

  static PegSolitairePuzzle forPracticeBoard(int index) {
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
    ..._campaign.values.map((PegSolitairePuzzle puzzle) => puzzle.signature),
    ..._practice.values.map((PegSolitairePuzzle puzzle) => puzzle.signature),
  };

  List<PegSolitairePosition> get certifiedStates {
    final List<PegSolitairePosition> states = <PegSolitairePosition>[start];
    for (final PegMove move in solution) {
      final PegSolitairePosition? next = states.last.play(move);
      if (next == null) throw StateError('Invalid certified peg move.');
      states.add(next);
    }
    return states;
  }

  PegMove? hintFor(PegSolitairePosition position) {
    final String current = position.signature;
    final int step = certifiedStates.indexWhere(
      (PegSolitairePosition state) => state.signature == current,
    );
    if (step < 0 || step >= solution.length) return null;
    return solution[step];
  }

  bool get isCertified {
    final List<PegSolitairePosition> states = certifiedStates;
    return solution.length == targetPegCount - 1 &&
        states.last.isWon(goal) &&
        states.length == solution.length + 1;
  }

  static PegSolitairePuzzle _generate(
    int level, {
    required int contentCycle,
    required Set<String> usedSignatures,
  }) {
    final int targetPegs = targetPegsForLevel(level);
    for (int attempt = 0; attempt < 4000; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'peg_solitaire:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final List<bool> pegs = List<bool>.filled(49, false)
        ..[PegSolitairePosition.center] = true;
      final List<PegMove> reverseMoves = <PegMove>[];
      int nodes = 0;
      while (reverseMoves.length < targetPegs - 1) {
        final List<PegMove> candidates = <PegMove>[
          for (final PegMove move in PegSolitairePosition._allMoves)
            if (!pegs[move.from] &&
                !pegs[move.over] &&
                pegs[move.to] &&
                move.from != PegSolitairePosition.center &&
                move.over != PegSolitairePosition.center)
              move,
        ];
        if (candidates.isEmpty) break;
        candidates.shuffle(random);
        final PegMove selected = candidates.first;
        pegs[selected.from] = true;
        pegs[selected.over] = true;
        pegs[selected.to] = false;
        reverseMoves.add(selected);
        nodes++;
      }
      if (reverseMoves.length != targetPegs - 1) continue;
      final PegSolitairePosition start = PegSolitairePosition(pegs: pegs);
      final String signature =
          '${start.signature}:${PegSolitairePosition.center}';
      if (usedSignatures.contains(signature)) continue;
      final PegSolitairePuzzle puzzle = PegSolitairePuzzle._(
        level: level,
        seed: seed,
        start: start,
        goal: PegSolitairePosition.center,
        solution: reverseMoves.reversed.toList(growable: false),
        reverseSearchNodes: nodes,
      );
      if (puzzle.isCertified) return puzzle;
    }
    throw StateError(
      'Could not certify a unique reachable peg-solitaire board for level $level.',
    );
  }
}
