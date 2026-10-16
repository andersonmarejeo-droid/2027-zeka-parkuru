import 'dart:math' as math;

import '../shared/content_seed.dart';
import 'shogi_position.dart';

class ShogiMatePuzzle {
  const ShogiMatePuzzle._({
    required this.level,
    required this.seed,
    required this.position,
    required this.solution,
    required this.proofCandidateMoves,
    required this.supportPieces,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, ShogiMatePuzzle> _campaign = <int, ShogiMatePuzzle>{};
  static final Map<int, ShogiMatePuzzle> _practice = <int, ShogiMatePuzzle>{};

  final int level;
  final int seed;
  final ShogiPosition position;
  final ShogiMove solution;
  final int proofCandidateMoves;
  final int supportPieces;

  String get signature => '${position.signature}:${solution.notation}';

  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP READING',
    _ => 'MASTER TSUME',
  };

  static ShogiMatePuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _campaign.putIfAbsent(level, () {
      for (int attempt = 0; attempt < 1000; attempt++) {
        final ShogiMatePuzzle candidate = _generate(level, attempt: attempt);
        if (_allContent.every(
          (ShogiMatePuzzle previous) =>
              previous.signature != candidate.signature,
        )) {
          return candidate;
        }
      }
      throw StateError('Could not create a unique Shogi study for $level.');
    });
  }

  static ShogiMatePuzzle forPracticeBoard(int index) {
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _campaign.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      ShogiMatePuzzle? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final ShogiMatePuzzle candidate = _generate(level, contentCycle: cycle);
        if (_allContent.every(
          (ShogiMatePuzzle previous) =>
              previous.signature != candidate.signature,
        )) {
          accepted = candidate;
        }
      }
      _practice[next] = accepted;
    }
    return _practice[index]!;
  }

  static List<ShogiMatePuzzle> get _allContent => <ShogiMatePuzzle>[
    ..._campaign.values,
    ..._practice.values,
  ];

  static int _supportCount(int level) => switch (level) {
    <= 3 => 0,
    <= 6 => 2,
    7 || 8 => 4,
    <= 10 => 6,
    <= 13 => 8,
    <= 16 => 11,
    <= 18 => 14,
    _ => 18,
  };

  static ShogiMatePuzzle _generate(
    int level, {
    int contentCycle = 0,
    int attempt = 0,
  }) {
    // Practice boards need enough independent material variation to avoid a
    // tiny early-level signature pool while keeping campaign tutorials clean.
    final int supportCount = contentCycle == 0
        ? _supportCount(level)
        : math.max(2, _supportCount(level));
    for (int buildAttempt = 0; buildAttempt < 12000; buildAttempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'shogi_mate:$contentCycle',
        level: level,
        attempt: attempt + buildAttempt,
      );
      final math.Random random = math.Random(seed);
      final bool defenderAtBottom =
          (level + contentCycle + buildAttempt).isEven;
      final ShogiSide attacker = defenderAtBottom
          ? ShogiSide.white
          : ShogiSide.black;
      final ShogiSide defender = attacker.opposite;
      final int defenderRow = defenderAtBottom ? 8 : 0;
      final int attackerRow = defenderAtBottom ? 6 : 2;
      final int dropRow = defenderAtBottom ? 7 : 1;
      final int column = 2 + random.nextInt(5);
      final List<ShogiPiece?> board = List<ShogiPiece?>.filled(81, null);
      board[ShogiSquare.index(defenderRow, column)] = ShogiPiece(
        defender,
        ShogiPieceType.king,
      );
      board[ShogiSquare.index(attackerRow, column)] = ShogiPiece(
        attacker,
        ShogiPieceType.king,
      );
      final List<(int, int)> safeSquares = <(int, int)>[
        for (int row = 0; row < 9; row++)
          for (int col = 0; col < 9; col++)
            if (row != defenderRow &&
                row != attackerRow &&
                (row - defenderRow).abs() + (col - column).abs() >= 4 &&
                (row - attackerRow).abs() + (col - column).abs() >= 3)
              (row, col),
      ]..shuffle(random);
      final List<ShogiPieceType> decoyTypes = <ShogiPieceType>[
        ShogiPieceType.pawn,
        ShogiPieceType.silver,
        ShogiPieceType.knight,
        ShogiPieceType.lance,
        ShogiPieceType.gold,
        ShogiPieceType.bishop,
        ShogiPieceType.rook,
      ];
      for (int index = 0; index < supportCount; index++) {
        final (int row, int col) = safeSquares[index];
        board[ShogiSquare.index(row, col)] = ShogiPiece(
          attacker,
          decoyTypes[random.nextInt(decoyTypes.length)],
        );
      }
      final ShogiPosition position = ShogiPosition(
        board: board,
        hands: <ShogiSide, Map<ShogiPieceType, int>>{
          attacker: <ShogiPieceType, int>{ShogiPieceType.gold: 1},
        },
        toMove: attacker,
      );
      if (position.isKingInCheck(attacker) ||
          position.isKingInCheck(defender)) {
        continue;
      }
      final List<ShogiMove> candidateMoves = position.legalMoves();
      final List<ShogiMove> matingMoves = <ShogiMove>[
        for (final ShogiMove move in candidateMoves)
          if (position.applyCertifiedLegalMove(move).isCheckmate()) move,
      ];
      final ShogiMove solution = ShogiMove(
        to: ShogiSquare.index(dropRow, column),
        drop: ShogiPieceType.gold,
      );
      if (matingMoves.length != 1 || matingMoves.single != solution) continue;
      return ShogiMatePuzzle._(
        level: level,
        seed: seed,
        position: position,
        solution: solution,
        proofCandidateMoves: candidateMoves.length,
        supportPieces: supportCount,
      );
    }
    throw StateError('Could not certify a unique Shogi mate at level $level.');
  }
}
