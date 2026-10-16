import 'dart:math' as math;

import '../shared/content_seed.dart';

enum ChessSide { white, black }

enum ChessPieceType { king, queen, rook, bishop, knight, pawn }

class ChessPiece {
  const ChessPiece(this.side, this.type);

  final ChessSide side;
  final ChessPieceType type;

  String get fen => switch (type) {
    ChessPieceType.king => side == ChessSide.white ? 'K' : 'k',
    ChessPieceType.queen => side == ChessSide.white ? 'Q' : 'q',
    ChessPieceType.rook => side == ChessSide.white ? 'R' : 'r',
    ChessPieceType.bishop => side == ChessSide.white ? 'B' : 'b',
    ChessPieceType.knight => side == ChessSide.white ? 'N' : 'n',
    ChessPieceType.pawn => side == ChessSide.white ? 'P' : 'p',
  };

  String get symbol => switch (type) {
    ChessPieceType.king => side == ChessSide.white ? '♔' : '♚',
    ChessPieceType.queen => side == ChessSide.white ? '♕' : '♛',
    ChessPieceType.rook => side == ChessSide.white ? '♖' : '♜',
    ChessPieceType.bishop => side == ChessSide.white ? '♗' : '♝',
    ChessPieceType.knight => side == ChessSide.white ? '♘' : '♞',
    ChessPieceType.pawn => side == ChessSide.white ? '♙' : '♟',
  };

  @override
  bool operator ==(Object other) =>
      other is ChessPiece && other.side == side && other.type == type;

  @override
  int get hashCode => Object.hash(side, type);
}

class ChessMove {
  const ChessMove({required this.from, required this.to, this.promotion});

  final int from;
  final int to;
  final ChessPieceType? promotion;

  String get uci =>
      '${ChessSquare.name(from)}${ChessSquare.name(to)}${switch (promotion) {
        ChessPieceType.queen => 'q',
        ChessPieceType.rook => 'r',
        ChessPieceType.bishop => 'b',
        ChessPieceType.knight => 'n',
        _ => '',
      }}';

  @override
  bool operator ==(Object other) =>
      other is ChessMove &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);
}

abstract final class ChessSquare {
  static int index(int file, int rank) => rank * 8 + file;

  static int file(int square) => square & 7;

  static int rank(int square) => square >> 3;

  static String name(int square) =>
      '${String.fromCharCode(97 + file(square))}${rank(square) + 1}';

  static int? parse(String name) {
    if (name.length != 2) return null;
    final int file = name.codeUnitAt(0) - 97;
    final int rank = name.codeUnitAt(1) - 49;
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return index(file, rank);
  }
}

/// Standard 8×8 chess position and legal move generator for puzzle play.
/// Castling, en-passant and all four promotion choices are represented even
/// though the curated mate studies do not depend on special-move loopholes.
class ChessPosition {
  ChessPosition._({
    required List<ChessPiece?> board,
    required this.whiteToMove,
    required this.castlingRights,
    required this.enPassantSquare,
  }) : board = List<ChessPiece?>.unmodifiable(board);

  static const int whiteKingSide = 1;
  static const int whiteQueenSide = 2;
  static const int blackKingSide = 4;
  static const int blackQueenSide = 8;

  final List<ChessPiece?> board;
  final bool whiteToMove;
  final int castlingRights;
  final int? enPassantSquare;

  ChessSide get sideToMove => whiteToMove ? ChessSide.white : ChessSide.black;

  factory ChessPosition.fromFen(String fen) {
    final List<String> fields = fen.trim().split(RegExp(r'\s+'));
    if (fields.length < 4) throw FormatException('Incomplete FEN: $fen');
    if (fields[1] != 'w' && fields[1] != 'b') {
      throw FormatException('Invalid FEN side-to-move: ${fields[1]}');
    }
    final List<ChessPiece?> board = List<ChessPiece?>.filled(64, null);
    final List<String> rows = fields[0].split('/');
    if (rows.length != 8) throw FormatException('FEN must have 8 ranks.');
    for (int row = 0; row < 8; row++) {
      int file = 0;
      for (final String token in rows[row].split('')) {
        final int? empty = int.tryParse(token);
        if (empty != null) {
          file += empty;
          continue;
        }
        final ChessPiece? piece = _pieceFromFen(token);
        if (piece == null || file > 7) {
          throw FormatException('Invalid FEN rank: ${rows[row]}');
        }
        board[ChessSquare.index(file, 7 - row)] = piece;
        file++;
      }
      if (file != 8) throw FormatException('Invalid FEN rank: ${rows[row]}');
    }
    int rights = 0;
    if (fields[2] != '-') {
      if (fields[2].contains('K')) rights |= whiteKingSide;
      if (fields[2].contains('Q')) rights |= whiteQueenSide;
      if (fields[2].contains('k')) rights |= blackKingSide;
      if (fields[2].contains('q')) rights |= blackQueenSide;
    }
    final int? enPassant = fields[3] == '-'
        ? null
        : ChessSquare.parse(fields[3]);
    if (fields[3] != '-' && enPassant == null) {
      throw FormatException('Invalid en-passant square: ${fields[3]}');
    }
    return ChessPosition._(
      board: board,
      whiteToMove: fields[1] == 'w',
      castlingRights: rights,
      enPassantSquare: enPassant,
    );
  }

  factory ChessPosition.composed(List<ChessPiece?> board) => ChessPosition._(
    board: board,
    whiteToMove: true,
    castlingRights: 0,
    enPassantSquare: null,
  );

  static ChessPiece? _pieceFromFen(String token) {
    if (token.length != 1) return null;
    final ChessSide side = token == token.toUpperCase()
        ? ChessSide.white
        : ChessSide.black;
    final ChessPieceType? type = switch (token.toLowerCase()) {
      'k' => ChessPieceType.king,
      'q' => ChessPieceType.queen,
      'r' => ChessPieceType.rook,
      'b' => ChessPieceType.bishop,
      'n' => ChessPieceType.knight,
      'p' => ChessPieceType.pawn,
      _ => null,
    };
    return type == null ? null : ChessPiece(side, type);
  }

  String get placement => List<String>.generate(8, (int row) {
    final StringBuffer out = StringBuffer();
    int empty = 0;
    for (int file = 0; file < 8; file++) {
      final ChessPiece? piece = board[ChessSquare.index(file, 7 - row)];
      if (piece == null) {
        empty++;
      } else {
        if (empty > 0) out.write(empty);
        empty = 0;
        out.write(piece.fen);
      }
    }
    if (empty > 0) out.write(empty);
    return out.toString();
  }).join('/');

  String get fen =>
      '$placement ${whiteToMove ? 'w' : 'b'} ${_castlingText()} ${enPassantSquare == null ? '-' : ChessSquare.name(enPassantSquare!)} 0 1';

  String _castlingText() {
    if (castlingRights == 0) return '-';
    final StringBuffer out = StringBuffer();
    if ((castlingRights & whiteKingSide) != 0) out.write('K');
    if ((castlingRights & whiteQueenSide) != 0) out.write('Q');
    if ((castlingRights & blackKingSide) != 0) out.write('k');
    if ((castlingRights & blackQueenSide) != 0) out.write('q');
    return out.toString();
  }

  int? kingSquare(ChessSide side) {
    for (int square = 0; square < 64; square++) {
      final ChessPiece? piece = board[square];
      if (piece?.side == side && piece?.type == ChessPieceType.king) {
        return square;
      }
    }
    return null;
  }

  bool isStructurallyLegal({bool requireQuietStart = false}) {
    final int whiteKings = board
        .where(
          (ChessPiece? piece) =>
              piece?.side == ChessSide.white &&
              piece?.type == ChessPieceType.king,
        )
        .length;
    final int blackKings = board
        .where(
          (ChessPiece? piece) =>
              piece?.side == ChessSide.black &&
              piece?.type == ChessPieceType.king,
        )
        .length;
    if (whiteKings != 1 || blackKings != 1) return false;
    for (int square = 0; square < 64; square++) {
      final ChessPiece? piece = board[square];
      if (piece?.type == ChessPieceType.pawn &&
          (ChessSquare.rank(square) == 0 || ChessSquare.rank(square) == 7)) {
        return false;
      }
    }
    final int whiteKing = kingSquare(ChessSide.white)!;
    final int blackKing = kingSquare(ChessSide.black)!;
    if ((ChessSquare.file(whiteKing) - ChessSquare.file(blackKing)).abs() <=
            1 &&
        (ChessSquare.rank(whiteKing) - ChessSquare.rank(blackKing)).abs() <=
            1) {
      return false;
    }
    if (inCheck(ChessSide.white) && inCheck(ChessSide.black)) return false;
    return !requireQuietStart ||
        (!inCheck(ChessSide.white) && !inCheck(ChessSide.black));
  }

  bool inCheck(ChessSide side) {
    final int? king = kingSquare(side);
    return king == null || isSquareAttacked(king, _opposite(side));
  }

  bool isSquareAttacked(int target, ChessSide bySide) {
    for (int from = 0; from < 64; from++) {
      final ChessPiece? piece = board[from];
      if (piece == null || piece.side != bySide) continue;
      if (_attacks(from, target, piece)) return true;
    }
    return false;
  }

  bool _attacks(int from, int to, ChessPiece piece) {
    if (from == to) return false;
    final int df = ChessSquare.file(to) - ChessSquare.file(from);
    final int dr = ChessSquare.rank(to) - ChessSquare.rank(from);
    final int absFile = df.abs();
    final int absRank = dr.abs();
    switch (piece.type) {
      case ChessPieceType.king:
        return absFile <= 1 && absRank <= 1;
      case ChessPieceType.knight:
        return (absFile == 1 && absRank == 2) || (absFile == 2 && absRank == 1);
      case ChessPieceType.pawn:
        return absFile == 1 && dr == (piece.side == ChessSide.white ? 1 : -1);
      case ChessPieceType.rook:
        if (df != 0 && dr != 0) return false;
      case ChessPieceType.bishop:
        if (absFile != absRank) return false;
      case ChessPieceType.queen:
        if (df != 0 && dr != 0 && absFile != absRank) return false;
    }
    final int stepFile = df == 0 ? 0 : df.sign;
    final int stepRank = dr == 0 ? 0 : dr.sign;
    int file = ChessSquare.file(from) + stepFile;
    int rank = ChessSquare.rank(from) + stepRank;
    while (file != ChessSquare.file(to) || rank != ChessSquare.rank(to)) {
      if (board[ChessSquare.index(file, rank)] != null) return false;
      file += stepFile;
      rank += stepRank;
    }
    return true;
  }

  List<ChessMove> legalMoves({ChessSide? side}) {
    final ChessSide mover = side ?? sideToMove;
    final ChessPosition current = mover == sideToMove
        ? this
        : ChessPosition._(
            board: board,
            whiteToMove: mover == ChessSide.white,
            castlingRights: castlingRights,
            enPassantSquare: null,
          );
    return current
        ._pseudoMoves(mover)
        .where((ChessMove move) {
          final ChessPosition after = current.play(move);
          return !after.inCheck(mover);
        })
        .toList(growable: false);
  }

  bool isCheckmate(ChessSide side) =>
      inCheck(side) && legalMoves(side: side).isEmpty;

  List<ChessMove> _pseudoMoves(ChessSide side) {
    final List<ChessMove> moves = <ChessMove>[];
    for (int from = 0; from < 64; from++) {
      final ChessPiece? piece = board[from];
      if (piece == null || piece.side != side) continue;
      final int file = ChessSquare.file(from);
      final int rank = ChessSquare.rank(from);
      switch (piece.type) {
        case ChessPieceType.king:
          for (int df = -1; df <= 1; df++) {
            for (int dr = -1; dr <= 1; dr++) {
              if (df == 0 && dr == 0) continue;
              _addStep(moves, from, file + df, rank + dr, side);
            }
          }
          _addCastles(moves, from, side);
        case ChessPieceType.knight:
          for (final (int df, int dr) in const <(int, int)>[
            (1, 2),
            (2, 1),
            (2, -1),
            (1, -2),
            (-1, -2),
            (-2, -1),
            (-2, 1),
            (-1, 2),
          ]) {
            _addStep(moves, from, file + df, rank + dr, side);
          }
        case ChessPieceType.bishop:
          _addSlides(moves, from, side, const <(int, int)>[
            (1, 1),
            (1, -1),
            (-1, 1),
            (-1, -1),
          ]);
        case ChessPieceType.rook:
          _addSlides(moves, from, side, const <(int, int)>[
            (1, 0),
            (-1, 0),
            (0, 1),
            (0, -1),
          ]);
        case ChessPieceType.queen:
          _addSlides(moves, from, side, const <(int, int)>[
            (1, 1),
            (1, -1),
            (-1, 1),
            (-1, -1),
            (1, 0),
            (-1, 0),
            (0, 1),
            (0, -1),
          ]);
        case ChessPieceType.pawn:
          _addPawnMoves(moves, from, side);
      }
    }
    return moves;
  }

  void _addStep(
    List<ChessMove> moves,
    int from,
    int file,
    int rank,
    ChessSide side,
  ) {
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return;
    final int to = ChessSquare.index(file, rank);
    final ChessPiece? target = board[to];
    if (target != null && target.side == side) return;
    if (target?.type == ChessPieceType.king) return;
    moves.add(ChessMove(from: from, to: to));
  }

  void _addSlides(
    List<ChessMove> moves,
    int from,
    ChessSide side,
    List<(int, int)> directions,
  ) {
    for (final (int df, int dr) in directions) {
      int file = ChessSquare.file(from) + df;
      int rank = ChessSquare.rank(from) + dr;
      while (file >= 0 && file < 8 && rank >= 0 && rank < 8) {
        final int to = ChessSquare.index(file, rank);
        final ChessPiece? target = board[to];
        if (target?.side == side) break;
        if (target?.type == ChessPieceType.king) break;
        moves.add(ChessMove(from: from, to: to));
        if (target != null) break;
        file += df;
        rank += dr;
      }
    }
  }

  void _addPawnMoves(List<ChessMove> moves, int from, ChessSide side) {
    final int direction = side == ChessSide.white ? 1 : -1;
    final int file = ChessSquare.file(from);
    final int rank = ChessSquare.rank(from);
    final int nextRank = rank + direction;
    if (nextRank >= 0 && nextRank < 8) {
      final int forward = ChessSquare.index(file, nextRank);
      if (board[forward] == null) {
        _addPawnDestination(moves, from, forward, side);
        final int startRank = side == ChessSide.white ? 1 : 6;
        final int doubleRank = rank + 2 * direction;
        if (rank == startRank &&
            board[ChessSquare.index(file, doubleRank)] == null) {
          moves.add(
            ChessMove(from: from, to: ChessSquare.index(file, doubleRank)),
          );
        }
      }
      for (final int targetFile in <int>[file - 1, file + 1]) {
        if (targetFile < 0 || targetFile > 7) continue;
        final int target = ChessSquare.index(targetFile, nextRank);
        final ChessPiece? occupant = board[target];
        if (occupant != null &&
            occupant.side != side &&
            occupant.type != ChessPieceType.king) {
          _addPawnDestination(moves, from, target, side);
        } else if (target == enPassantSquare) {
          moves.add(ChessMove(from: from, to: target));
        }
      }
    }
  }

  void _addPawnDestination(
    List<ChessMove> moves,
    int from,
    int to,
    ChessSide side,
  ) {
    if (ChessSquare.rank(to) != (side == ChessSide.white ? 7 : 0)) {
      moves.add(ChessMove(from: from, to: to));
      return;
    }
    for (final ChessPieceType promotion in const <ChessPieceType>[
      ChessPieceType.queen,
      ChessPieceType.rook,
      ChessPieceType.bishop,
      ChessPieceType.knight,
    ]) {
      moves.add(ChessMove(from: from, to: to, promotion: promotion));
    }
  }

  void _addCastles(List<ChessMove> moves, int from, ChessSide side) {
    final int rank = side == ChessSide.white ? 0 : 7;
    final int home = ChessSquare.index(4, rank);
    if (from != home || inCheck(side)) return;
    final int kingRight = side == ChessSide.white
        ? whiteKingSide
        : blackKingSide;
    final int queenRight = side == ChessSide.white
        ? whiteQueenSide
        : blackQueenSide;
    final int rookRank = ChessSquare.index(7, rank);
    if ((castlingRights & kingRight) != 0 &&
        board[rookRank] == ChessPiece(side, ChessPieceType.rook) &&
        board[ChessSquare.index(5, rank)] == null &&
        board[ChessSquare.index(6, rank)] == null &&
        !isSquareAttacked(ChessSquare.index(5, rank), _opposite(side)) &&
        !isSquareAttacked(ChessSquare.index(6, rank), _opposite(side))) {
      moves.add(ChessMove(from: home, to: ChessSquare.index(6, rank)));
    }
    final int queenRook = ChessSquare.index(0, rank);
    if ((castlingRights & queenRight) != 0 &&
        board[queenRook] == ChessPiece(side, ChessPieceType.rook) &&
        board[ChessSquare.index(1, rank)] == null &&
        board[ChessSquare.index(2, rank)] == null &&
        board[ChessSquare.index(3, rank)] == null &&
        !isSquareAttacked(ChessSquare.index(3, rank), _opposite(side)) &&
        !isSquareAttacked(ChessSquare.index(2, rank), _opposite(side))) {
      moves.add(ChessMove(from: home, to: ChessSquare.index(2, rank)));
    }
  }

  ChessPosition play(ChessMove move) {
    final ChessPiece? moving = board[move.from];
    if (moving == null) {
      throw StateError('No chess piece on ${ChessSquare.name(move.from)}.');
    }
    final List<ChessPiece?> next = List<ChessPiece?>.from(board);
    int rights = castlingRights;
    int? enPassant;
    final ChessPiece? captured = board[move.to];
    next[move.from] = null;
    next[move.to] = move.promotion == null
        ? moving
        : ChessPiece(moving.side, move.promotion!);
    if (moving.type == ChessPieceType.pawn &&
        enPassantSquare == move.to &&
        captured == null &&
        ChessSquare.file(move.from) != ChessSquare.file(move.to)) {
      final int capturedSquare =
          move.to + (moving.side == ChessSide.white ? -8 : 8);
      next[capturedSquare] = null;
    }
    if (moving.type == ChessPieceType.king &&
        (move.to - move.from).abs() == 2) {
      final int rank = ChessSquare.rank(move.from);
      final bool kingSide = move.to > move.from;
      final int rookFrom = ChessSquare.index(kingSide ? 7 : 0, rank);
      final int rookTo = ChessSquare.index(kingSide ? 5 : 3, rank);
      next[rookTo] = next[rookFrom];
      next[rookFrom] = null;
    }
    if (moving.type == ChessPieceType.king) {
      rights &= moving.side == ChessSide.white
          ? ~(whiteKingSide | whiteQueenSide)
          : ~(blackKingSide | blackQueenSide);
    }
    if (moving.type == ChessPieceType.rook) {
      rights = _removeRookRight(rights, move.from);
    }
    if (captured?.type == ChessPieceType.rook) {
      rights = _removeRookRight(rights, move.to);
    }
    if (moving.type == ChessPieceType.pawn &&
        (move.to - move.from).abs() == 16) {
      enPassant = (move.from + move.to) ~/ 2;
    }
    return ChessPosition._(
      board: next,
      whiteToMove: !whiteToMove,
      castlingRights: rights,
      enPassantSquare: enPassant,
    );
  }

  int _removeRookRight(int rights, int square) => switch (square) {
    0 => rights & ~whiteQueenSide,
    7 => rights & ~whiteKingSide,
    56 => rights & ~blackQueenSide,
    63 => rights & ~blackKingSide,
    _ => rights,
  };

  static ChessSide _opposite(ChessSide side) =>
      side == ChessSide.white ? ChessSide.black : ChessSide.white;
}

/// A deterministic one-move tactical study whose unique correct move is mate.
/// The verifier searches every legal white move and proves there is one and
/// only one immediate checkmate before the board can enter a campaign.
class ChessMatePuzzle {
  const ChessMatePuzzle._({
    required this.level,
    required this.seed,
    required this.position,
    required this.solution,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, ChessMatePuzzle> _campaign = <int, ChessMatePuzzle>{};
  static final Map<int, ChessMatePuzzle> _practice = <int, ChessMatePuzzle>{};

  final int level;
  final int seed;
  final ChessPosition position;
  final ChessMove solution;

  String get signature => position.placement;

  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    <= 16 => 'EXPERT',
    _ => 'MASTER',
  };

  int get candidateMoveCount => position.legalMoves().length;

  int get occupiedPieceCount =>
      position.board.where((ChessPiece? piece) => piece != null).length;

  int get minimumCandidateMoveCount => switch (level) {
    <= 3 => 3,
    <= 6 => 5,
    7 || 8 => 8,
    9 || 10 => 10,
    <= 16 => 12,
    _ => 14,
  };

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'seed': seed,
    'position': position.fen,
    'solution': [solution.from, solution.to, solution.promotion?.index],
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) {
      throw FormatException('Invalid mini_chess_tactics bank');
    }
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practice[i + 1] = ChessMatePuzzle._(
        level: m['level'] as int,
        seed: m['seed'] as int,
        position: ChessPosition.fromFen(m['position'] as String),
        solution: ChessMove(
          from: (m['solution'] as List)[0] as int,
          to: (m['solution'] as List)[1] as int,
          promotion: (m['solution'] as List)[2] == null
              ? null
              : ChessPieceType.values[(m['solution'] as List)[2] as int],
        ),
      );
    }
  }

  static ChessMatePuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _campaign.putIfAbsent(level, () => _generate(level));
  }

  static ChessMatePuzzle forPracticeBoard(int index) {
    final cached = _practice[index];
    if (cached != null) return cached;
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _campaign.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      ChessMatePuzzle? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final ChessMatePuzzle candidate = _generate(
          level,
          contentCycle: 1000 + cycle,
        );
        if (<ChessMatePuzzle>[..._campaign.values, ..._practice.values].every(
          (ChessMatePuzzle previous) =>
              previous.signature != candidate.signature,
        )) {
          accepted = candidate;
        }
      }
      _practice[next] = accepted;
    }
    return _practice[index]!;
  }

  static ChessMatePuzzle _generate(int level, {int contentCycle = 0}) {
    final int extraPieces = switch (level) {
      <= 6 => 0,
      7 || 8 => 1,
      <= 10 => 2,
      <= 16 => 3,
      _ => 4,
    };
    for (int attempt = 0; attempt < 250000; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'mini_chess_tactics:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final List<ChessPiece?> board = List<ChessPiece?>.filled(64, null);
      final int blackKing = _edgeBiasedSquare(random, level >= 9);
      final int whiteKing = random.nextInt(64);
      if (!_kingsSeparated(blackKing, whiteKing)) continue;
      board[blackKing] = const ChessPiece(ChessSide.black, ChessPieceType.king);
      board[whiteKing] = const ChessPiece(ChessSide.white, ChessPieceType.king);

      final ChessPieceType mainType = level <= 6 || random.nextInt(3) != 0
          ? ChessPieceType.queen
          : ChessPieceType.rook;
      if (!_placeRandomPiece(board, random, ChessSide.white, mainType)) {
        continue;
      }
      bool failed = false;
      for (int index = 0; index < extraPieces; index++) {
        final ChessSide side = random.nextBool()
            ? ChessSide.white
            : ChessSide.black;
        final ChessPieceType type = _extraType(random, level, side);
        if (!_placeRandomPiece(board, random, side, type)) {
          failed = true;
          break;
        }
      }
      if (failed) continue;
      final ChessPosition position = ChessPosition.composed(board);
      if (!position.isStructurallyLegal(requireQuietStart: true)) continue;
      final List<ChessMove> candidateMoves = position.legalMoves();
      if (candidateMoves.length < _minimumCandidateMoveCount(level)) continue;
      final List<ChessMove> mates = <ChessMove>[];
      for (final ChessMove move in candidateMoves) {
        final ChessPosition after = position.play(move);
        if (after.isCheckmate(ChessSide.black)) mates.add(move);
        if (mates.length > 1) break;
      }
      if (mates.length != 1) continue;
      return ChessMatePuzzle._(
        level: level,
        seed: seed,
        position: position,
        solution: mates.single,
      );
    }
    throw StateError(
      'Could not certify a unique mate puzzle for level $level.',
    );
  }

  static int _minimumCandidateMoveCount(int level) => switch (level) {
    <= 3 => 3,
    <= 6 => 5,
    7 || 8 => 8,
    9 || 10 => 10,
    <= 16 => 12,
    _ => 14,
  };

  static int _edgeBiasedSquare(math.Random random, bool biasEdge) {
    if (!biasEdge || random.nextInt(5) == 0) return random.nextInt(64);
    final int edge = random.nextInt(4);
    final int file = random.nextInt(8);
    return switch (edge) {
      0 => ChessSquare.index(file, 0),
      1 => ChessSquare.index(file, 7),
      2 => ChessSquare.index(0, file),
      _ => ChessSquare.index(7, file),
    };
  }

  static bool _kingsSeparated(int first, int second) =>
      (ChessSquare.file(first) - ChessSquare.file(second)).abs() > 1 ||
      (ChessSquare.rank(first) - ChessSquare.rank(second)).abs() > 1;

  static bool _placeRandomPiece(
    List<ChessPiece?> board,
    math.Random random,
    ChessSide side,
    ChessPieceType type,
  ) {
    for (int tries = 0; tries < 100; tries++) {
      final int square = random.nextInt(64);
      if (board[square] != null) continue;
      if (type == ChessPieceType.pawn &&
          (ChessSquare.rank(square) == 0 || ChessSquare.rank(square) == 7)) {
        continue;
      }
      board[square] = ChessPiece(side, type);
      return true;
    }
    return false;
  }

  static ChessPieceType _extraType(
    math.Random random,
    int level,
    ChessSide side,
  ) {
    final List<ChessPieceType> pool = level <= 8
        ? const <ChessPieceType>[
            ChessPieceType.rook,
            ChessPieceType.bishop,
            ChessPieceType.knight,
          ]
        : const <ChessPieceType>[
            ChessPieceType.rook,
            ChessPieceType.bishop,
            ChessPieceType.knight,
            ChessPieceType.pawn,
            ChessPieceType.queen,
          ];
    if (side == ChessSide.black && level >= 17 && random.nextInt(5) == 0) {
      return ChessPieceType.pawn;
    }
    return pool[random.nextInt(pool.length)];
  }
}
