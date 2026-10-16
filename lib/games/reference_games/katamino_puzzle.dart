import 'dart:math';

class PolyCell {
  const PolyCell(this.x, this.y);
  final int x;
  final int y;
  @override
  bool operator ==(Object other) =>
      other is PolyCell && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

class KataminoPuzzle {
  const KataminoPuzzle({
    required this.width,
    required this.height,
    required this.pieceSize,
    required this.pieces,
  });
  final int width;
  final int height;
  final int pieceSize;
  final List<List<PolyCell>> pieces;

  static final Map<int, List<KataminoPuzzle>> _uniqueVariantCache =
      <int, List<KataminoPuzzle>>{};
  static final Map<int, Set<String>> _seenVariantSignatures =
      <int, Set<String>>{};
  static final Map<int, int> _candidateCursors = <int, int>{};

  String get signature =>
      '${width}x$height:$pieceSize:${pieces.map((p) => p.map((c) => '${c.x},${c.y}').join(';')).join('|')}';

  static KataminoPuzzle generate(int level, int variant) {
    if (level < 1 || level > 10) {
      throw RangeError.range(level, 1, 10, 'level');
    }
    final int requested = variant % 300;
    final List<KataminoPuzzle> variants = _uniqueVariantCache.putIfAbsent(
      level,
      () => <KataminoPuzzle>[],
    );
    final Set<String> seen = _seenVariantSignatures.putIfAbsent(
      level,
      () => <String>{},
    );
    int cursor = _candidateCursors[level] ?? 0;
    int attempts = 0;
    while (variants.length <= requested && attempts < 12000) {
      final KataminoPuzzle candidate = _generateCandidate(level, cursor++);
      attempts++;
      if (seen.add(candidate.signature)) variants.add(candidate);
    }
    _candidateCursors[level] = cursor;
    if (variants.length <= requested) {
      throw StateError(
        'Only ${variants.length} unique Katamino boards could be generated for level $level.',
      );
    }
    return variants[requested];
  }

  static KataminoPuzzle _generateCandidate(int level, int variant) {
    final int size = level >= 7 ? 5 : 4;
    final List<(int, int)> dimensions = size == 4
        ? const <(int, int)>[(4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (8, 5)]
        : const <(int, int)>[(5, 5), (6, 5), (7, 5), (8, 5)];
    final int dimensionIndex = size == 4 ? level - 1 : level - 7;
    final (int, int) dimension = dimensions[dimensionIndex];
    final int width = dimension.$1, height = dimension.$2;
    final Random random = Random(
      0x4B415441 ^ (level * 7919) ^ (variant * 104729),
    );
    for (int attempt = 0; attempt < 90; attempt++) {
      final Set<PolyCell> remaining = <PolyCell>{
        for (int y = 0; y < height; y++)
          for (int x = 0; x < width; x++) PolyCell(x, y),
      };
      final List<List<PolyCell>> pieces = <List<PolyCell>>[];
      bool failed = false;
      while (remaining.isNotEmpty) {
        final List<PolyCell> open = remaining.toList()..shuffle(random);
        final List<PolyCell> piece = <PolyCell>[open.first];
        while (piece.length < size) {
          final List<PolyCell> frontier = <PolyCell>[];
          for (final PolyCell cell in piece) {
            for (final PolyCell next in <PolyCell>[
              PolyCell(cell.x + 1, cell.y),
              PolyCell(cell.x - 1, cell.y),
              PolyCell(cell.x, cell.y + 1),
              PolyCell(cell.x, cell.y - 1),
            ]) {
              if (remaining.contains(next) &&
                  !piece.contains(next) &&
                  !frontier.contains(next)) {
                frontier.add(next);
              }
            }
          }
          if (frontier.isEmpty) {
            failed = true;
            break;
          }
          frontier.shuffle(random);
          piece.add(frontier.first);
        }
        if (failed) break;
        remaining.removeAll(piece);
        pieces.add(_normalize(piece));
      }
      if (!failed && remaining.isEmpty) {
        pieces.shuffle(random);
        return KataminoPuzzle(
          width: width,
          height: height,
          pieceSize: size,
          pieces: pieces,
        );
      }
    }
    // Rectangular bars are an uncommon deterministic fallback, not the normal
    // generation path; they still tile every supported board exactly.
    final List<List<PolyCell>> fallback = <List<PolyCell>>[];
    if (height % size == 0) {
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y += size) {
          fallback.add(
            List<PolyCell>.generate(size, (int i) => PolyCell(0, i)),
          );
        }
      }
    } else {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x += size) {
          fallback.add(
            List<PolyCell>.generate(size, (int i) => PolyCell(i, 0)),
          );
        }
      }
    }
    return KataminoPuzzle(
      width: width,
      height: height,
      pieceSize: size,
      pieces: fallback,
    );
  }

  static List<PolyCell> _normalize(List<PolyCell> cells) {
    final int minX = cells.map((PolyCell cell) => cell.x).reduce(min);
    final int minY = cells.map((PolyCell cell) => cell.y).reduce(min);
    final List<PolyCell> normalized =
        cells
            .map((PolyCell cell) => PolyCell(cell.x - minX, cell.y - minY))
            .toList()
          ..sort(
            (PolyCell a, PolyCell b) =>
                a.y == b.y ? a.x.compareTo(b.x) : a.y.compareTo(b.y),
          );
    return normalized;
  }
}

List<PolyCell> transformPolyomino(
  List<PolyCell> source,
  int quarterTurns,
  bool mirrored,
) {
  List<PolyCell> cells = source
      .map((PolyCell c) => PolyCell(mirrored ? -c.x : c.x, c.y))
      .toList();
  for (int turn = 0; turn < quarterTurns % 4; turn++) {
    cells = cells.map((PolyCell c) => PolyCell(-c.y, c.x)).toList();
  }
  final int minX = cells.map((PolyCell c) => c.x).reduce(min);
  final int minY = cells.map((PolyCell c) => c.y).reduce(min);
  cells = cells.map((PolyCell c) => PolyCell(c.x - minX, c.y - minY)).toList()
    ..sort(
      (PolyCell a, PolyCell b) =>
          a.y == b.y ? a.x.compareTo(b.x) : a.y.compareTo(b.y),
    );
  return cells;
}

class KataminoPlacement {
  const KataminoPlacement({
    required this.x,
    required this.y,
    required this.rotation,
    required this.mirrored,
    required this.cells,
    required this.indices,
  });

  final int x;
  final int y;
  final int rotation;
  final bool mirrored;
  final List<PolyCell> cells;
  final List<int> indices;
}

/// Finds a legal placement nearest to the cell the player touched.
///
/// A touched empty cell is preferred as part of the piece footprint. If it
/// cannot be covered by a legal fit, the closest available fit is returned.
/// The player's chosen rotation/mirror orientation wins ties.
KataminoPlacement? findNearestKataminoPlacement({
  required KataminoPuzzle puzzle,
  required List<int?> board,
  required List<PolyCell> piece,
  required int targetX,
  required int targetY,
  required int preferredRotation,
  required bool preferredMirror,
}) {
  if (board.length != puzzle.width * puzzle.height || piece.isEmpty) {
    return null;
  }

  final List<(int, bool)> orientations = <(int, bool)>[];
  for (int mirrorOffset = 0; mirrorOffset < 2; mirrorOffset++) {
    final bool mirrored = mirrorOffset == 0
        ? preferredMirror
        : !preferredMirror;
    for (int turnOffset = 0; turnOffset < 4; turnOffset++) {
      orientations.add(((preferredRotation + turnOffset) % 4, mirrored));
    }
  }

  final Set<String> seenShapes = <String>{};
  KataminoPlacement? best;
  double bestScore = double.infinity;
  for (
    int orientationRank = 0;
    orientationRank < orientations.length;
    orientationRank++
  ) {
    final (int rotation, bool mirrored) = orientations[orientationRank];
    final List<PolyCell> cells = transformPolyomino(piece, rotation, mirrored);
    final String signature = cells
        .map((PolyCell cell) => '${cell.x},${cell.y}')
        .join(';');
    if (!seenShapes.add(signature)) continue;

    for (int y = 0; y < puzzle.height; y++) {
      for (int x = 0; x < puzzle.width; x++) {
        final List<int> indices = <int>[];
        bool fits = true;
        double nearestDistance = double.infinity;
        double centerX = 0, centerY = 0;
        for (final PolyCell cell in cells) {
          final int boardX = x + cell.x, boardY = y + cell.y;
          if (boardX >= puzzle.width || boardY >= puzzle.height) {
            fits = false;
            break;
          }
          final int index = boardY * puzzle.width + boardX;
          if (board[index] != null) {
            fits = false;
            break;
          }
          indices.add(index);
          final double dx = (boardX - targetX).toDouble();
          final double dy = (boardY - targetY).toDouble();
          final double distance = dx * dx + dy * dy;
          if (distance < nearestDistance) nearestDistance = distance;
          centerX += boardX;
          centerY += boardY;
        }
        if (!fits) continue;

        centerX /= cells.length;
        centerY /= cells.length;
        final double centerDx = centerX - targetX;
        final double centerDy = centerY - targetY;
        final double score =
            nearestDistance * 100 +
            (centerDx * centerDx + centerDy * centerDy) * .05 +
            orientationRank * .001;
        if (score >= bestScore) continue;
        bestScore = score;
        best = KataminoPlacement(
          x: x,
          y: y,
          rotation: rotation,
          mirrored: mirrored,
          cells: cells,
          indices: indices,
        );
      }
    }
  }
  return best;
}
