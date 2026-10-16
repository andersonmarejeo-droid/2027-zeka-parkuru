import 'dart:math' as math;

import '../shared/content_seed.dart';

/// A deterministic, solver-verified nonogram board.
///
/// Rows are stored as bitmasks (bit 0 is the left-most cell); the visible
/// clues are derived from those masks and never contain the answer itself.
class PicrossPuzzle {
  const PicrossPuzzle._({
    required this.level,
    required this.size,
    required this.seed,
    required this.solutionRows,
    required this.rowClues,
    required this.columnClues,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static const int _generationAttemptLimit = 600;
  static const int _solverNodeLimit = 80000;
  static final Map<int, PicrossPuzzle> _cache = <int, PicrossPuzzle>{};
  static final Map<int, PicrossPuzzle> _practiceCache = <int, PicrossPuzzle>{};

  final int level;
  final int size;
  final int seed;
  final List<int> solutionRows;
  final List<List<int>> rowClues;
  final List<List<int>> columnClues;

  int get filledCellCount =>
      solutionRows.fold<int>(0, (int total, int row) => total + _popCount(row));

  String get boardSignature =>
      '$size:${solutionRows.map((int row) => row.toRadixString(16)).join('-')}';

  String get difficultyTier {
    if (level <= 6) return 'MASTERY';
    if (level <= 8) return 'ADVANCED';
    if (level <= 16) return 'EXPERT';
    return 'MASTER';
  }

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'size': size,
    'seed': seed,
    'solutionRows': solutionRows,
    'rowClues': rowClues,
    'columnClues': columnClues,
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) {
      throw FormatException('Invalid picross_master bank');
    }
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practiceCache[i + 1] = PicrossPuzzle._(
        level: m['level'] as int,
        size: m['size'] as int,
        seed: m['seed'] as int,
        solutionRows: List<int>.from(m['solutionRows'] as List),
        rowClues: (m['rowClues'] as List)
            .map((row) => List<int>.from(row as List))
            .toList(),
        columnClues: (m['columnClues'] as List)
            .map((row) => List<int>.from(row as List))
            .toList(),
      );
    }
  }

  static PicrossPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  /// Provides a stable, non-repeating practice board for daily/replay modes.
  /// Campaign progress remains capped at 20; practice has its own 300 seeds.
  static PicrossPuzzle forPracticeBoard(int index) {
    final cached = _practiceCache[index];
    if (cached != null) return cached;
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _cache.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practiceCache.length + 1; next <= index; next++) {
      final int mappedLevel = ((next - 1) % maximumLevels) + 1;
      PicrossPuzzle? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final PicrossPuzzle candidate = _generate(
          mappedLevel,
          contentCycle: 1000 + cycle,
        );
        final bool repeated =
            <PicrossPuzzle>[..._cache.values, ..._practiceCache.values].any(
              (PicrossPuzzle prior) =>
                  prior.boardSignature == candidate.boardSignature,
            );
        if (!repeated) accepted = candidate;
      }
      _practiceCache[next] = accepted;
    }
    return _practiceCache[index]!;
  }

  bool isFilled(int row, int column) =>
      (solutionRows[row] & (1 << column)) != 0;

  int solutionCount({int nodeLimit = _solverNodeLimit}) => _countSolutions(
    rowClues: rowClues,
    columnClues: columnClues,
    size: size,
    nodeLimit: nodeLimit,
  );

  static PicrossPuzzle _generate(int level, {int contentCycle = 0}) {
    final int size = _sizeForLevel(level);
    int usefulCandidates = 0;
    int nonUniqueCandidates = 0;
    for (int attempt = 0; attempt < _generationAttemptLimit; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'picross_master:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final List<int> rows = _drawSilhouette(size, seed, level);
      if (!_hasUsefulDensity(rows, size)) continue;
      usefulCandidates++;
      final List<List<int>> rowClues = List<List<int>>.generate(
        size,
        (int row) => _runs(rows[row], size),
        growable: false,
      );
      final List<List<int>> columnClues = List<List<int>>.generate(
        size,
        (int column) => _runs(_columnMask(rows, column, size), size),
        growable: false,
      );
      final int count = _countSolutions(
        rowClues: rowClues,
        columnClues: columnClues,
        size: size,
        nodeLimit: _solverNodeLimit,
      );
      if (count == 1) {
        return PicrossPuzzle._(
          level: level,
          size: size,
          seed: seed,
          solutionRows: List<int>.unmodifiable(rows),
          rowClues: _freezeClues(rowClues),
          columnClues: _freezeClues(columnClues),
        );
      }
      nonUniqueCandidates++;
    }
    throw StateError(
      'Could not create a unique Picross board for $level '
      '(size $size, useful $usefulCandidates, checked $nonUniqueCandidates).',
    );
  }

  static int _sizeForLevel(int level) => switch (level) {
    <= 2 => 5,
    <= 4 => 6,
    <= 6 => 7,
    <= 8 => 8,
    <= 10 => 9,
    <= 12 => 10,
    <= 14 => 11,
    <= 16 => 12,
    <= 18 => 13,
    19 => 14,
    _ => 15,
  };

  static List<int> _drawSilhouette(int size, int seed, int level) {
    final math.Random random = math.Random(seed);
    final double phase = random.nextDouble() * math.pi * 2;
    final double scale = 0.66 + random.nextDouble() * 0.18;
    final int motif = (level + seed % 7) % 6;
    final List<int> rows = List<int>.filled(size, 0);
    for (int row = 0; row < size; row++) {
      for (int column = 0; column < size; column++) {
        final double x = (column - (size - 1) / 2) / (size / 2);
        final double y = (row - (size - 1) / 2) / (size / 2);
        final double radial = math.sqrt(x * x + y * y);
        final double angle = math.atan2(y, x) + phase;
        final double wave = math.sin(angle * (3 + motif % 3) + phase) * .08;
        bool ink = switch (motif) {
          0 =>
            radial < scale + wave &&
                (radial > .20 || (x.abs() < .12 || y.abs() < .12)),
          1 =>
            (x.abs() < .15 && y > -.05 && y < .86) ||
                (_ellipse(x + .24, y + .12, .53, .34) && x < .20) ||
                (_ellipse(x - .23, y - .22, .43, .32) && x > -.18),
          2 =>
            (radial < .78 + wave && radial > .40 + wave) ||
                (y.abs() < .13 && x.abs() < .84),
          3 => _star(x, y, phase, .77, .31),
          4 =>
            (y < .36 && y > -.72 && x.abs() < (.25 + (y + .72) * .48)) ||
                (y > .28 &&
                    y < .58 &&
                    x.abs() < .82 &&
                    math.sin((x + 1) * 8 + phase) > -.25),
          _ =>
            _ellipse(x, y + .02, .76, .78) &&
                    (!_ellipse(x - .31, y + .13, .18, .23) ||
                        !_ellipse(x + .31, y + .13, .18, .23)) ||
                (y.abs() < .08 && x.abs() < .70),
        };
        // Seeded edge variation gives each generated silhouette its own
        // readable pixel contour without relying on stock AI art.
        final double variation = random.nextDouble();
        if (ink && variation < .075) {
          ink = false;
        } else if (!ink && variation > .82) {
          ink = true;
        }
        if (ink) rows[row] |= 1 << column;
      }
    }
    return rows;
  }

  static bool _ellipse(double x, double y, double rx, double ry) =>
      (x * x) / (rx * rx) + (y * y) / (ry * ry) <= 1;

  static bool _star(
    double x,
    double y,
    double phase,
    double outer,
    double inner,
  ) {
    final double angle = math.atan2(y, x) + phase;
    final double radius = math.sqrt(x * x + y * y);
    final double edge =
        inner + (outer - inner) * (.5 + .5 * math.cos(angle * 5));
    return radius < edge;
  }

  static bool _hasUsefulDensity(List<int> rows, int size) {
    final int filled = rows.fold<int>(
      0,
      (int total, int row) => total + _popCount(row),
    );
    final int area = size * size;
    if (filled < area * .18 || filled > area * .78) return false;
    for (int index = 0; index < size; index++) {
      if (rows[index] == 0 || rows[index] == (1 << size) - 1) return false;
      final int column = _columnMask(rows, index, size);
      if (column == 0 || column == (1 << size) - 1) return false;
    }
    return true;
  }

  static int _columnMask(List<int> rows, int column, int size) {
    int mask = 0;
    for (int row = 0; row < size; row++) {
      if ((rows[row] & (1 << column)) != 0) mask |= 1 << row;
    }
    return mask;
  }

  static List<int> _runs(int mask, int size) {
    final List<int> runs = <int>[];
    int run = 0;
    for (int index = 0; index < size; index++) {
      if ((mask & (1 << index)) != 0) {
        run++;
      } else if (run > 0) {
        runs.add(run);
        run = 0;
      }
    }
    if (run > 0) runs.add(run);
    return runs.isEmpty ? <int>[0] : runs;
  }

  static int _countSolutions({
    required List<List<int>> rowClues,
    required List<List<int>> columnClues,
    required int size,
    required int nodeLimit,
  }) {
    final int possibilities = 1 << size;
    List<List<int>> domainsFor(List<List<int>> clues) => clues
        .map(
          (List<int> clue) => <int>[
            for (int mask = 0; mask < possibilities; mask++)
              if (_matchesRuns(mask, size, clue)) mask,
          ],
        )
        .toList(growable: false);

    final List<List<int>> rowDomains = domainsFor(rowClues);
    final List<List<int>> columnDomains = domainsFor(columnClues);
    if (rowDomains.any((List<int> domain) => domain.isEmpty) ||
        columnDomains.any((List<int> domain) => domain.isEmpty)) {
      return 0;
    }
    final List<List<Set<int>>> prefixes = List<List<Set<int>>>.generate(
      size,
      (int column) => List<Set<int>>.generate(size + 1, (int depth) {
        final int mask = (1 << depth) - 1;
        return columnDomains[column].map((int option) => option & mask).toSet();
      }, growable: false),
      growable: false,
    );
    final List<int> columnPartial = List<int>.filled(size, 0);
    int visited = 0;
    int solutions = 0;

    void search(int row) {
      if (solutions >= 2 || visited >= nodeLimit) return;
      visited++;
      if (row == size) {
        solutions++;
        return;
      }
      for (final int option in rowDomains[row]) {
        bool possible = true;
        for (int column = 0; column < size; column++) {
          final int bit = 1 << column;
          final int next = (option & bit) == 0
              ? columnPartial[column]
              : columnPartial[column] | (1 << row);
          if (!prefixes[column][row + 1].contains(next)) {
            possible = false;
            break;
          }
        }
        if (!possible) continue;
        final List<int> before = List<int>.of(columnPartial);
        for (int column = 0; column < size; column++) {
          if ((option & (1 << column)) != 0) {
            columnPartial[column] |= 1 << row;
          }
        }
        search(row + 1);
        for (int column = 0; column < size; column++) {
          columnPartial[column] = before[column];
        }
        if (solutions >= 2 || visited >= nodeLimit) return;
      }
    }

    search(0);
    // A search that hits its safety limit is not accepted as proof of a unique
    // board. Returning 2 conservatively rejects that candidate.
    return visited >= nodeLimit && solutions < 2 ? 2 : solutions;
  }

  static bool _matchesRuns(int mask, int size, List<int> expected) {
    int expectedIndex = 0;
    int run = 0;
    for (int index = 0; index < size; index++) {
      if ((mask & (1 << index)) != 0) {
        run++;
      } else if (run > 0) {
        if (expectedIndex >= expected.length ||
            expected[expectedIndex] != run) {
          return false;
        }
        expectedIndex++;
        run = 0;
      }
    }
    if (run > 0) {
      if (expectedIndex >= expected.length || expected[expectedIndex] != run) {
        return false;
      }
      expectedIndex++;
    }
    return expectedIndex == expected.length &&
        (expected.isNotEmpty || mask == 0);
  }

  static List<List<int>> _freezeClues(List<List<int>> clues) =>
      List<List<int>>.unmodifiable(
        clues.map((List<int> clue) => List<int>.unmodifiable(clue)),
      );

  static int _popCount(int value) {
    int count = 0;
    while (value != 0) {
      value &= value - 1;
      count++;
    }
    return count;
  }
}
