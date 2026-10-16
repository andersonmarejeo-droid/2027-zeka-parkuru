import 'dart:collection';

enum ShogiSide { black, white }

extension ShogiSideRules on ShogiSide {
  ShogiSide get opposite =>
      this == ShogiSide.black ? ShogiSide.white : ShogiSide.black;

  int get forward => this == ShogiSide.black ? -1 : 1;
}

enum ShogiPieceType { king, rook, bishop, gold, silver, knight, lance, pawn }

class ShogiPiece {
  const ShogiPiece(this.side, this.type, {this.promoted = false});

  final ShogiSide side;
  final ShogiPieceType type;
  final bool promoted;

  ShogiPiece promote() => ShogiPiece(side, type, promoted: true);

  ShogiPiece demote({ShogiSide? toSide}) =>
      ShogiPiece(toSide ?? side, type, promoted: false);
}

class ShogiMove {
  const ShogiMove({
    required this.to,
    this.from,
    this.drop,
    this.promote = false,
  });

  final int? from;
  final int to;
  final ShogiPieceType? drop;
  final bool promote;

  bool get isDrop => drop != null;

  String get notation => isDrop
      ? '${drop!.name.toUpperCase()}*${ShogiSquare.name(to)}'
      : '${ShogiSquare.name(from!)}${promote ? '+' : ''}${ShogiSquare.name(to)}';

  @override
  bool operator ==(Object other) =>
      other is ShogiMove &&
      other.from == from &&
      other.to == to &&
      other.drop == drop &&
      other.promote == promote;

  @override
  int get hashCode => Object.hash(from, to, drop, promote);
}

abstract final class ShogiSquare {
  static int index(int row, int column) => row * 9 + column;
  static int row(int square) => square ~/ 9;
  static int column(int square) => square % 9;
  static String name(int square) =>
      '${column(square) + 1}${String.fromCharCode(97 + row(square))}';
}

/// 9×9 Shogi legality: promotion, hands, drops, nifu, dead ranks, king safety,
/// and the forbidden pawn-drop checkmate (uchi-fuzume) rule.
class ShogiPosition {
  ShogiPosition({
    required List<ShogiPiece?> board,
    required Map<ShogiSide, Map<ShogiPieceType, int>> hands,
    required this.toMove,
  }) : board = List<ShogiPiece?>.unmodifiable(board),
       hands = UnmodifiableMapView<ShogiSide, Map<ShogiPieceType, int>>(
         <ShogiSide, Map<ShogiPieceType, int>>{
           for (final ShogiSide side in ShogiSide.values)
             side: UnmodifiableMapView<ShogiPieceType, int>(
               Map<ShogiPieceType, int>.of(hands[side] ?? const {}),
             ),
         },
       ) {
    if (board.length != 81 ||
        board.whereType<ShogiPiece>().any(
          (ShogiPiece piece) =>
              piece.type == ShogiPieceType.king && piece.promoted,
        )) {
      throw ArgumentError('Invalid Shogi board.');
    }
  }

  final List<ShogiPiece?> board;
  final Map<ShogiSide, Map<ShogiPieceType, int>> hands;
  final ShogiSide toMove;

  ShogiPiece? at(int square) => board[square];

  String get signature =>
      '${board.map((ShogiPiece? piece) => piece == null ? '.' : '${piece.side.index}${piece.type.index}${piece.promoted ? '+' : ''}').join()}:$toMove:${ShogiSide.values.map((ShogiSide side) => hands[side]!.entries.map((MapEntry<ShogiPieceType, int> entry) => '${entry.key.index}=${entry.value}').join(',')).join('|')}';

  int get handCount => hands.values.fold<int>(
    0,
    (int total, Map<ShogiPieceType, int> hand) =>
        total + hand.values.fold<int>(0, (int sum, int count) => sum + count),
  );

  List<ShogiMove> legalMoves() => _legalMoves(enforcePawnDropMate: true);

  List<ShogiMove> _legalMoves({required bool enforcePawnDropMate}) {
    final List<ShogiMove> legal = <ShogiMove>[];
    for (int from = 0; from < board.length; from++) {
      final ShogiPiece? piece = board[from];
      if (piece == null || piece.side != toMove) continue;
      for (final int to in _destinations(from, piece)) {
        final ShogiPiece? captured = board[to];
        if (captured?.side == toMove.opposite &&
            captured?.type == ShogiPieceType.king) {
          continue;
        }
        for (final bool promote in _promotionChoices(from, to, piece)) {
          final ShogiMove move = ShogiMove(
            from: from,
            to: to,
            promote: promote,
          );
          final ShogiPosition next = _applyUnchecked(move);
          if (next.isKingInCheck(toMove)) continue;
          legal.add(move);
        }
      }
    }
    for (final MapEntry<ShogiPieceType, int> entry in hands[toMove]!.entries) {
      if (entry.value <= 0 || entry.key == ShogiPieceType.king) continue;
      for (int to = 0; to < board.length; to++) {
        if (board[to] != null || !_dropAllowed(entry.key, to, toMove)) continue;
        final ShogiMove move = ShogiMove(to: to, drop: entry.key);
        final ShogiPosition next = _applyUnchecked(move);
        if (next.isKingInCheck(toMove)) continue;
        if (enforcePawnDropMate &&
            entry.key == ShogiPieceType.pawn &&
            next.isKingInCheck(toMove.opposite) &&
            next._legalMoves(enforcePawnDropMate: false).isEmpty) {
          continue;
        }
        legal.add(move);
      }
    }
    return List<ShogiMove>.unmodifiable(legal);
  }

  ShogiPosition? play(ShogiMove move) =>
      legalMoves().contains(move) ? _applyUnchecked(move) : null;

  /// Applies a move obtained from [legalMoves] without regenerating the tree.
  /// Proof search uses this for sibling moves that are already certified legal.
  ShogiPosition applyCertifiedLegalMove(ShogiMove move) =>
      _applyUnchecked(move);

  bool isCheckmate() => isKingInCheck(toMove) && legalMoves().isEmpty;

  bool isKingInCheck(ShogiSide side) {
    final int king = board.indexWhere(
      (ShogiPiece? piece) =>
          piece?.side == side && piece?.type == ShogiPieceType.king,
    );
    if (king < 0) return true;
    for (int from = 0; from < board.length; from++) {
      final ShogiPiece? piece = board[from];
      if (piece?.side == side.opposite && _attacks(from, king, piece!)) {
        return true;
      }
    }
    return false;
  }

  ShogiPosition _applyUnchecked(ShogiMove move) {
    final List<ShogiPiece?> nextBoard = List<ShogiPiece?>.of(board);
    final Map<ShogiPieceType, int> moverHand = Map<ShogiPieceType, int>.of(
      hands[toMove]!,
    );
    if (move.isDrop) {
      final ShogiPieceType type = move.drop!;
      moverHand[type] = (moverHand[type] ?? 0) - 1;
      if (moverHand[type] == 0) moverHand.remove(type);
      nextBoard[move.to] = ShogiPiece(toMove, type);
    } else {
      final ShogiPiece moving = nextBoard[move.from!]!;
      final ShogiPiece? captured = nextBoard[move.to];
      if (captured != null) {
        final ShogiPieceType handType = captured.type;
        moverHand[handType] = (moverHand[handType] ?? 0) + 1;
      }
      nextBoard[move.from!] = null;
      nextBoard[move.to] = move.promote ? moving.promote() : moving;
    }
    return ShogiPosition(
      board: nextBoard,
      hands: <ShogiSide, Map<ShogiPieceType, int>>{
        toMove: moverHand,
        toMove.opposite: hands[toMove.opposite]!,
      },
      toMove: toMove.opposite,
    );
  }

  Iterable<int> _destinations(int from, ShogiPiece piece) sync* {
    final int row = ShogiSquare.row(from);
    final int column = ShogiSquare.column(from);
    final int forward = piece.side.forward;
    final List<(int, int)> steps = _stepVectors(piece);
    for (final (int dr, int dc) in steps) {
      final int nextRow = row + dr;
      final int nextColumn = column + dc;
      if (_inBounds(nextRow, nextColumn)) {
        final int next = ShogiSquare.index(nextRow, nextColumn);
        if (board[next]?.side != piece.side) yield next;
      }
    }
    final List<(int, int)> rays = _rayVectors(piece, forward);
    for (final (int dr, int dc) in rays) {
      int nextRow = row + dr;
      int nextColumn = column + dc;
      while (_inBounds(nextRow, nextColumn)) {
        final int next = ShogiSquare.index(nextRow, nextColumn);
        if (board[next]?.side == piece.side) break;
        yield next;
        if (board[next] != null) break;
        nextRow += dr;
        nextColumn += dc;
      }
    }
  }

  List<(int, int)> _stepVectors(ShogiPiece piece) {
    final int f = piece.side.forward;
    if (piece.promoted &&
        <ShogiPieceType>{
          ShogiPieceType.pawn,
          ShogiPieceType.lance,
          ShogiPieceType.knight,
          ShogiPieceType.silver,
        }.contains(piece.type)) {
      return <(int, int)>[(f, 0), (f, -1), (f, 1), (0, -1), (0, 1), (-f, 0)];
    }
    return switch (piece.type) {
      ShogiPieceType.king => <(int, int)>[
        (-1, -1),
        (-1, 0),
        (-1, 1),
        (0, -1),
        (0, 1),
        (1, -1),
        (1, 0),
        (1, 1),
      ],
      ShogiPieceType.gold => <(int, int)>[
        (f, -1),
        (f, 0),
        (f, 1),
        (0, -1),
        (0, 1),
        (-f, 0),
      ],
      ShogiPieceType.silver => <(int, int)>[
        (f, -1),
        (f, 0),
        (f, 1),
        (-f, -1),
        (-f, 1),
      ],
      ShogiPieceType.knight => <(int, int)>[(f * 2, -1), (f * 2, 1)],
      ShogiPieceType.pawn => <(int, int)>[(f, 0)],
      _ => const <(int, int)>[],
    };
  }

  List<(int, int)> _rayVectors(ShogiPiece piece, int forward) {
    final List<(int, int)> result = <(int, int)>[];
    if (piece.type == ShogiPieceType.rook ||
        (piece.promoted && piece.type == ShogiPieceType.rook)) {
      result.addAll(const <(int, int)>[(-1, 0), (1, 0), (0, -1), (0, 1)]);
    }
    if (piece.type == ShogiPieceType.bishop ||
        (piece.promoted && piece.type == ShogiPieceType.bishop)) {
      result.addAll(const <(int, int)>[(-1, -1), (-1, 1), (1, -1), (1, 1)]);
    }
    if (!piece.promoted && piece.type == ShogiPieceType.lance) {
      result.add((forward, 0));
    }
    return result;
  }

  bool _attacks(int from, int to, ShogiPiece piece) {
    final int fromRow = ShogiSquare.row(from);
    final int fromColumn = ShogiSquare.column(from);
    final int toRow = ShogiSquare.row(to);
    final int toColumn = ShogiSquare.column(to);
    final int dr = toRow - fromRow;
    final int dc = toColumn - fromColumn;
    final int f = piece.side.forward;
    final int adr = dr.abs();
    final int adc = dc.abs();
    final bool goldLike =
        piece.promoted &&
        <ShogiPieceType>{
          ShogiPieceType.pawn,
          ShogiPieceType.lance,
          ShogiPieceType.knight,
          ShogiPieceType.silver,
        }.contains(piece.type);
    if (piece.type == ShogiPieceType.king) {
      return adr <= 1 && adc <= 1 && (adr + adc > 0);
    }
    if (goldLike || piece.type == ShogiPieceType.gold) {
      return (dr == f && adc <= 1) ||
          (dr == 0 && adc == 1) ||
          (dr == -f && dc == 0);
    }
    if (piece.type == ShogiPieceType.silver) {
      return (dr == f && adc <= 1) || (dr == -f && adc == 1);
    }
    if (piece.type == ShogiPieceType.knight) return dr == 2 * f && adc == 1;
    if (piece.type == ShogiPieceType.pawn) return dr == f && dc == 0;
    if (piece.type == ShogiPieceType.lance && !piece.promoted) {
      return dc == 0 && dr.sign == f && _clearRay(fromRow, fromColumn, dr, dc);
    }
    final bool rookRay =
        (piece.type == ShogiPieceType.rook ||
            (piece.promoted && piece.type == ShogiPieceType.rook)) &&
        ((dr == 0) != (dc == 0)) &&
        _clearRay(fromRow, fromColumn, dr, dc);
    final bool bishopRay =
        (piece.type == ShogiPieceType.bishop ||
            (piece.promoted && piece.type == ShogiPieceType.bishop)) &&
        adr == adc &&
        _clearRay(fromRow, fromColumn, dr, dc);
    if (rookRay || bishopRay) return true;
    if (piece.promoted && piece.type == ShogiPieceType.bishop) {
      return adr + adc == 1;
    }
    if (piece.promoted && piece.type == ShogiPieceType.rook) {
      return adr == 1 && adc == 1;
    }
    return false;
  }

  bool _clearRay(int row, int column, int dr, int dc) {
    final int stepRow = dr.sign;
    final int stepColumn = dc.sign;
    int r = row + stepRow;
    int c = column + stepColumn;
    final int targetRow = row + dr;
    final int targetColumn = column + dc;
    while (r != targetRow || c != targetColumn) {
      if (board[ShogiSquare.index(r, c)] != null) return false;
      r += stepRow;
      c += stepColumn;
    }
    return true;
  }

  List<bool> _promotionChoices(int from, int to, ShogiPiece piece) {
    if (piece.promoted ||
        <ShogiPieceType>{
          ShogiPieceType.king,
          ShogiPieceType.gold,
        }.contains(piece.type)) {
      return const <bool>[false];
    }
    final bool inZone =
        _inPromotionZone(piece.side, from) || _inPromotionZone(piece.side, to);
    final int row = ShogiSquare.row(to);
    final bool mandatory =
        piece.type == ShogiPieceType.pawn || piece.type == ShogiPieceType.lance
        ? row == (piece.side == ShogiSide.black ? 0 : 8)
        : piece.type == ShogiPieceType.knight &&
              (piece.side == ShogiSide.black ? row <= 1 : row >= 7);
    if (mandatory) return const <bool>[true];
    return inZone ? const <bool>[false, true] : const <bool>[false];
  }

  bool _dropAllowed(ShogiPieceType type, int to, ShogiSide side) {
    final int row = ShogiSquare.row(to);
    if ((type == ShogiPieceType.pawn || type == ShogiPieceType.lance) &&
        (side == ShogiSide.black ? row == 0 : row == 8)) {
      return false;
    }
    if (type == ShogiPieceType.knight &&
        (side == ShogiSide.black ? row <= 1 : row >= 7)) {
      return false;
    }
    if (type == ShogiPieceType.pawn) {
      final int column = ShogiSquare.column(to);
      for (int candidateRow = 0; candidateRow < 9; candidateRow++) {
        final ShogiPiece? piece =
            board[ShogiSquare.index(candidateRow, column)];
        if (piece?.side == side &&
            piece?.type == ShogiPieceType.pawn &&
            piece?.promoted == false) {
          return false;
        }
      }
    }
    return true;
  }

  bool _inPromotionZone(ShogiSide side, int square) => side == ShogiSide.black
      ? ShogiSquare.row(square) <= 2
      : ShogiSquare.row(square) >= 6;

  bool _inBounds(int row, int column) =>
      row >= 0 && row < 9 && column >= 0 && column < 9;
}
