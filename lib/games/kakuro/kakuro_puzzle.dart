import 'dart:math' as math;

import '../shared/content_seed.dart';

enum KakuroRunDirection { across, down }

class KakuroCell {
  const KakuroCell({
    required this.isPlayable,
    this.acrossSum,
    this.downSum,
    this.solutionValue,
  });

  final bool isPlayable;
  final int? acrossSum;
  final int? downSum;

  /// The answer is used by the verifier and hint system, never displayed as a
  /// clue. Blank clue cells have no solution value.
  final int? solutionValue;

  String get visibleSignature => isPlayable
      ? 'w'
      : acrossSum == null && downSum == null
      ? '#'
      : 'a${acrossSum ?? 0}d${downSum ?? 0}';
}

class KakuroRun {
  const KakuroRun({
    required this.direction,
    required this.cells,
    required this.targetSum,
  });

  final KakuroRunDirection direction;
  final List<int> cells;
  final int targetSum;

  String get signature => '$direction:${cells.join(',')}=$targetSum';
}

/// Deterministic Kakuro campaign with a bounded uniqueness verifier.
///
/// Each entry is constrained by one across and one down run. The generator
/// creates its own answer grid, derives both directional clues, then keeps a
/// board only after the Kakuro rules find exactly one solution.
class KakuroPuzzle {
  const KakuroPuzzle({
    required this.level,
    required this.chapter,
    required this.stageInChapter,
    required this.size,
    required this.cells,
    required this.acrossRuns,
    required this.downRuns,
    required this.solution,
  });

  static const int maximumLevels = 20;
  static const int poolSize = 300;
  static final Map<int, KakuroPuzzle> _pool = {};
  static final Set<String> _poolSignatures = {};

  static KakuroPuzzle forPool(int index) {
    RangeError.checkValueInInterval(index, 1, poolSize, 'index');
    final templates = List<KakuroPuzzle>.generate(maximumLevels, (i) => forLevel(i + 1))
      ..sort((a, b) {
        final comparison = a.size.compareTo(b.size);
        return comparison != 0 ? comparison : a.level.compareTo(b.level);
      });
    for (int next = _pool.length + 1; next <= index; next++) {
      final base = templates[(next - 1) % maximumLevels];
      final variant = (next - 1) ~/ maximumLevels;
      KakuroPuzzle? accepted;
      for (int offset = 0; offset < 16; offset++) {
        final transformation = (variant + offset) % 16;
        final n = base.size - 1;
        final mask = List<bool>.filled(n * n, false);
        final solution = List<int>.filled(base.size * base.size, 0);
        for (int row = 0; row < n; row++) {
          for (int column = 0; column < n; column++) {
            int r = row, c = column;
            if (transformation % 8 >= 4) c = n - 1 - c;
            for (int turn = 0; turn < transformation % 4; turn++) {
              final previousR = r;
              r = c; c = n - 1 - previousR;
            }
            final from = (row + 1) * base.size + column + 1;
            final to = (r + 1) * base.size + c + 1;
            mask[r * n + c] = base.cells[from].isPlayable;
            final value = base.solution[from];
            solution[to] = value == 0 ? 0 : transformation >= 8 ? 10 - value : value;
          }
        }
        final data = _createBoard(size: base.size, mask: mask, random: math.Random(0), fixedSolution: solution);
        if (data == null) continue;
        final candidate = KakuroPuzzle(level: base.level, chapter: base.chapter, stageInChapter: base.stageInChapter,
          size: base.size, cells: List.unmodifiable(data.cells), acrossRuns: List.unmodifiable(data.acrossRuns),
          downRuns: List.unmodifiable(data.downRuns), solution: List.unmodifiable(data.solution));
        if (_poolSignatures.add(candidate.boardSignature)) { accepted = candidate; break; }
      }
      if (accepted == null) throw StateError('Kakuro pool exhausted at $next.');
      _pool[next] = accepted;
    }
    return _pool[index]!;
  }
  static final Map<int, KakuroPuzzle> _cache = <int, KakuroPuzzle>{};
  static const Map<int, int> _verifiedAttempts = <int, int>{
    1: 219,
    2: 516,
    3: 129,
    4: 113,
    5: 448,
    6: 54,
    7: 2077,
    8: 323,
    9: 17176,
    10: 40891,
    11: 1264,
    12: 980,
    13: 646,
    14: 1538,
    15: 851,
    16: 1327,
    17: 33189,
    18: 45446,
    19: 13747,
    20: 16209,
  };

  final int level;
  final int chapter;
  final int stageInChapter;
  final int size;
  final List<KakuroCell> cells;
  final List<KakuroRun> acrossRuns;
  final List<KakuroRun> downRuns;
  final List<int> solution;

  int get playableCount =>
      cells.where((KakuroCell cell) => cell.isPlayable).length;
  int get difficultySize => size;

  String get difficultyTier => switch (stageInChapter) {
    <= 6 => chapter == 1 ? 'MASTERY' : 'ADVANCED',
    <= 8 => 'EXPERT',
    _ => 'EXPERT+',
  };

  String get boardSignature =>
      '$size:${cells.map((KakuroCell cell) => cell.visibleSignature).join('|')}';

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static KakuroPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  List<int>? solveUnique({int nodeLimit = 90000}) {
    final List<int> assignment = List<int>.filled(cells.length, 0);
    final List<KakuroRun> allRuns = <KakuroRun>[...acrossRuns, ...downRuns];
    final List<List<KakuroRun>> runsByCell = List<List<KakuroRun>>.generate(
      cells.length,
      (_) => <KakuroRun>[],
    );
    final Map<KakuroRun, List<int>> combinationsByRun =
        <KakuroRun, List<int>>{};
    for (final KakuroRun run in allRuns) {
      for (final int cell in run.cells) {
        runsByCell[cell].add(run);
      }
      combinationsByRun[run] = <int>[
        for (int digits = 0; digits < 1 << 10; digits++)
          if (_digitCount(digits) == run.cells.length &&
              _digitSum(digits) == run.targetSum)
            digits,
      ];
    }
    final List<List<int>> found = <List<int>>[];
    int visitedNodes = 0;
    bool limitReached = false;

    bool canPlace(KakuroRun run, int cell, int digit) {
      int usedDigits = 1 << digit;
      int assigned = 1;
      for (final int runCell in run.cells) {
        if (runCell == cell) continue;
        final int value = assignment[runCell];
        if (value == 0) {
          continue;
        }
        final int bit = 1 << value;
        if (usedDigits & bit != 0) return false;
        usedDigits |= bit;
        assigned++;
      }
      return combinationsByRun[run]!.any(
            (int combination) => combination & usedDigits == usedDigits,
          ) &&
          assigned <= run.cells.length;
    }

    void search() {
      if (found.length >= 2 || limitReached) return;
      visitedNodes++;
      if (visitedNodes > nodeLimit) {
        limitReached = true;
        return;
      }

      int selectedCell = -1;
      List<int>? selectedDomain;
      for (int cell = 0; cell < cells.length; cell++) {
        if (!cells[cell].isPlayable || assignment[cell] != 0) continue;
        final List<int> domain = <int>[];
        for (int digit = 1; digit <= 9; digit++) {
          if (runsByCell[cell].every(
            (KakuroRun run) => canPlace(run, cell, digit),
          )) {
            domain.add(digit);
          }
        }
        if (domain.isEmpty) return;
        if (selectedDomain == null || domain.length < selectedDomain.length) {
          selectedCell = cell;
          selectedDomain = domain;
          if (domain.length == 1) break;
        }
      }

      if (selectedCell < 0) {
        found.add(List<int>.unmodifiable(assignment));
        return;
      }
      for (final int digit in selectedDomain!) {
        assignment[selectedCell] = digit;
        search();
        assignment[selectedCell] = 0;
        if (found.length >= 2 || limitReached) return;
      }
    }

    search();
    if (limitReached || found.length != 1) return null;
    return found.single;
  }

  static KakuroPuzzle _generate(int level, {int variant = 0}) {
    final int stage = stageForLevel(level);
    final int chapter = (level - 1) ~/ 10 + 1;
    final int size = _boardSize(chapter, stage);
    final int interior = size - 1;
    final int minCells = math.max(6, (interior * interior * .21).round());
    final int minimumLongRun = stage <= 6
        ? 2
        : stage <= 8
        ? 3
        : chapter == 2 && stage >= 9
        ? 5
        : 4;
    int candidatesChecked = 0;
    int uniqueSolutionsFound = 0;
    int mismatchedSolutions = 0;

    final int firstAttempt = _verifiedAttempts[level] ?? 0;
    for (int offset = 0; offset < 4096; offset++) {
      final int attempt = firstAttempt + offset;
      final math.Random random = ContentSeed.randomFor(
        gameId: 'kakuro',
        level: level + variant * maximumLevels,
        attempt: attempt,
      );
      final double density = chapter == 1
          ? (stage <= 3
                ? .62
                : stage <= 6
                ? .52
                : stage <= 8
                ? .42
                : .38)
          : (stage <= 6 ? .46 : .38);
      final List<bool> mask = List<bool>.generate(
        interior * interior,
        (_) => random.nextDouble() < density,
      );
      _removeSingleCellRuns(mask, interior);
      final int filledCount = mask.where((bool value) => value).length;
      if (filledCount < minCells || !_isConnected(mask, interior)) continue;

      final _KakuroBoardData? board = _createBoard(
        size: size,
        mask: mask,
        random: random,
      );
      if (board == null) continue;
      final int longestRun = <KakuroRun>[
        ...board.acrossRuns,
        ...board.downRuns,
      ].map((KakuroRun run) => run.cells.length).fold<int>(0, math.max);
      if (longestRun < minimumLongRun) continue;
      candidatesChecked++;

      final List<KakuroCell> immutableCells = List<KakuroCell>.unmodifiable(
        board.cells,
      );
      final KakuroPuzzle candidate = KakuroPuzzle(
        level: level,
        chapter: chapter,
        stageInChapter: stage,
        size: size,
        cells: immutableCells,
        acrossRuns: List<KakuroRun>.unmodifiable(board.acrossRuns),
        downRuns: List<KakuroRun>.unmodifiable(board.downRuns),
        solution: List<int>.unmodifiable(board.solution),
      );
      final List<int>? verified = candidate.solveUnique();
      if (verified == null) continue;
      uniqueSolutionsFound++;
      if (!_sameEntries(verified, board.solution, mask, size)) {
        mismatchedSolutions++;
        continue;
      }
      return candidate;
    }
    throw StateError(
      'Unable to generate a unique Kakuro level $level '
      '(checked $candidatesChecked, unique $uniqueSolutionsFound, '
      'mismatch $mismatchedSolutions).',
    );
  }

  static int _boardSize(int chapter, int stage) {
    if (chapter == 1) {
      return switch (stage) {
        <= 3 => 5,
        <= 6 => 6,
        <= 8 => 7,
        _ => 8,
      };
    }
    return switch (stage) {
      <= 3 => 6,
      <= 6 => 7,
      _ => 8,
    };
  }

  static void _removeSingleCellRuns(List<bool> mask, int size) {
    bool changed;
    do {
      changed = false;
      final List<int> remove = <int>[];
      for (int row = 0; row < size; row++) {
        for (int column = 0; column < size; column++) {
          final int index = row * size + column;
          if (!mask[index]) continue;
          final int acrossLength = _runLength(mask, size, row, column, true);
          final int downLength = _runLength(mask, size, row, column, false);
          if (acrossLength < 2 || downLength < 2) remove.add(index);
        }
      }
      for (final int index in remove) {
        if (mask[index]) {
          mask[index] = false;
          changed = true;
        }
      }
    } while (changed);
  }

  static int _runLength(
    List<bool> mask,
    int size,
    int row,
    int column,
    bool across,
  ) {
    int startRow = row;
    int startColumn = column;
    while (across ? startColumn > 0 : startRow > 0) {
      final int previousRow = startRow - (across ? 0 : 1);
      final int previousColumn = startColumn - (across ? 1 : 0);
      if (previousRow < 0 ||
          previousColumn < 0 ||
          previousRow >= size ||
          previousColumn >= size ||
          !mask[previousRow * size + previousColumn]) {
        break;
      }
      startRow = previousRow;
      startColumn = previousColumn;
    }
    int length = 0;
    int currentRow = startRow;
    int currentColumn = startColumn;
    while (currentRow < size && currentColumn < size) {
      if (!mask[currentRow * size + currentColumn]) break;
      length++;
      currentRow += across ? 0 : 1;
      currentColumn += across ? 1 : 0;
    }
    return length;
  }

  static bool _isConnected(List<bool> mask, int size) {
    final int first = mask.indexWhere((bool cell) => cell);
    if (first < 0) return false;
    final Set<int> visited = <int>{first};
    final List<int> pending = <int>[first];
    while (pending.isNotEmpty) {
      final int current = pending.removeLast();
      final int row = current ~/ size;
      final int column = current % size;
      for (final (int, int) delta in const <(int, int)>[
        (-1, 0),
        (1, 0),
        (0, -1),
        (0, 1),
      ]) {
        final int nextRow = row + delta.$1;
        final int nextColumn = column + delta.$2;
        if (nextRow < 0 ||
            nextColumn < 0 ||
            nextRow >= size ||
            nextColumn >= size) {
          continue;
        }
        final int next = nextRow * size + nextColumn;
        if (mask[next] && visited.add(next)) pending.add(next);
      }
    }
    return visited.length == mask.where((bool cell) => cell).length;
  }

  static List<int>? _assignSolution(
    List<bool> mask,
    int size,
    math.Random random,
  ) {
    final List<int> solution = List<int>.filled(size * size, 0);
    final List<int> interiorCells = <int>[
      for (int index = 0; index < mask.length; index++)
        if (mask[index]) index,
    ];
    int visitedNodes = 0;

    List<int> candidates(int maskIndex) {
      final int interior = size - 1;
      final int row = maskIndex ~/ interior + 1;
      final int column = maskIndex % interior + 1;
      final Set<int> used = <int>{};
      for (int c = column - 1; c >= 1; c--) {
        if (!mask[(row - 1) * interior + c - 1]) break;
        used.add(solution[row * size + c]);
      }
      for (int c = column + 1; c < size; c++) {
        if (!mask[(row - 1) * interior + c - 1]) break;
        used.add(solution[row * size + c]);
      }
      for (int r = row - 1; r >= 1; r--) {
        if (!mask[(r - 1) * interior + column - 1]) break;
        used.add(solution[r * size + column]);
      }
      for (int r = row + 1; r < size; r++) {
        if (!mask[(r - 1) * interior + column - 1]) break;
        used.add(solution[r * size + column]);
      }
      final List<int> values = <int>[
        for (int digit = 1; digit <= 9; digit++)
          if (!used.contains(digit)) digit,
      ]..shuffle(random);
      return values;
    }

    bool fill(int remaining) {
      if (remaining == 0) return true;
      visitedNodes++;
      if (visitedNodes > 24000) return false;
      int selected = -1;
      List<int>? selectedCandidates;
      final List<int> tied = <int>[];
      for (final int maskIndex in interiorCells) {
        final int row = maskIndex ~/ (size - 1) + 1;
        final int column = maskIndex % (size - 1) + 1;
        if (solution[row * size + column] != 0) continue;
        final List<int> values = candidates(maskIndex);
        if (values.isEmpty) return false;
        if (selectedCandidates == null ||
            values.length < selectedCandidates.length) {
          selected = maskIndex;
          selectedCandidates = values;
          tied
            ..clear()
            ..add(maskIndex);
        } else if (values.length == selectedCandidates.length) {
          tied.add(maskIndex);
        }
      }
      if (selectedCandidates == null) return true;
      if (tied.length > 1) selected = tied[random.nextInt(tied.length)];
      selectedCandidates = candidates(selected);
      final int row = selected ~/ (size - 1) + 1;
      final int column = selected % (size - 1) + 1;
      final int cell = row * size + column;
      for (final int digit in selectedCandidates) {
        solution[cell] = digit;
        if (fill(remaining - 1)) return true;
        solution[cell] = 0;
      }
      return false;
    }

    if (!fill(interiorCells.length)) return null;
    return solution;
  }

  static _KakuroBoardData? _createBoard({
    required int size,
    required List<bool> mask,
    required math.Random random,
    List<int>? fixedSolution,
  }) {
    final int interior = size - 1;
    final List<bool> white = List<bool>.filled(size * size, false);
    final List<int>? assignedSolution = fixedSolution ?? _assignSolution(mask, size, random);
    if (assignedSolution == null) return null;
    final List<int> solution = assignedSolution;
    for (int row = 1; row < size; row++) {
      for (int column = 1; column < size; column++) {
        final bool isWhite = mask[(row - 1) * interior + column - 1];
        final int index = row * size + column;
        white[index] = isWhite;
      }
    }

    final List<int?> acrossSums = List<int?>.filled(size * size, null);
    final List<int?> downSums = List<int?>.filled(size * size, null);
    final List<KakuroRun> acrossRuns = <KakuroRun>[];
    final List<KakuroRun> downRuns = <KakuroRun>[];

    for (int row = 1; row < size; row++) {
      int column = 1;
      while (column < size) {
        if (!white[row * size + column]) {
          column++;
          continue;
        }
        final int start = column;
        final List<int> run = <int>[];
        int sum = 0;
        while (column < size && white[row * size + column]) {
          final int index = row * size + column;
          run.add(index);
          sum += solution[index];
          column++;
        }
        if (run.length < 2) return null;
        acrossSums[row * size + start - 1] = sum;
        acrossRuns.add(
          KakuroRun(
            direction: KakuroRunDirection.across,
            cells: List<int>.unmodifiable(run),
            targetSum: sum,
          ),
        );
      }
    }
    for (int column = 1; column < size; column++) {
      int row = 1;
      while (row < size) {
        if (!white[row * size + column]) {
          row++;
          continue;
        }
        final int start = row;
        final List<int> run = <int>[];
        int sum = 0;
        while (row < size && white[row * size + column]) {
          final int index = row * size + column;
          run.add(index);
          sum += solution[index];
          row++;
        }
        if (run.length < 2) return null;
        downSums[(start - 1) * size + column] = sum;
        downRuns.add(
          KakuroRun(
            direction: KakuroRunDirection.down,
            cells: List<int>.unmodifiable(run),
            targetSum: sum,
          ),
        );
      }
    }
    if (acrossRuns.length < 3 || downRuns.length < 3) return null;

    final List<KakuroCell> cells = List<KakuroCell>.generate(
      size * size,
      (int index) => KakuroCell(
        isPlayable: white[index],
        acrossSum: acrossSums[index],
        downSum: downSums[index],
        solutionValue: white[index] ? solution[index] : null,
      ),
      growable: false,
    );
    return _KakuroBoardData(
      cells: cells,
      acrossRuns: acrossRuns,
      downRuns: downRuns,
      solution: solution,
    );
  }

  static bool _sameEntries(
    List<int> solved,
    List<int> expected,
    List<bool> mask,
    int size,
  ) {
    final int interior = size - 1;
    for (int row = 1; row < size; row++) {
      for (int column = 1; column < size; column++) {
        final int index = row * size + column;
        if (!mask[(row - 1) * interior + column - 1]) continue;
        if (solved[index] != expected[index]) return false;
      }
    }
    return true;
  }

  static int _digitCount(int mask) {
    int count = 0;
    int remaining = mask;
    while (remaining != 0) {
      remaining &= remaining - 1;
      count++;
    }
    return count;
  }

  static int _digitSum(int mask) {
    int sum = 0;
    for (int digit = 1; digit <= 9; digit++) {
      if (mask & (1 << digit) != 0) sum += digit;
    }
    return sum;
  }
}

class _KakuroBoardData {
  const _KakuroBoardData({
    required this.cells,
    required this.acrossRuns,
    required this.downRuns,
    required this.solution,
  });

  final List<KakuroCell> cells;
  final List<KakuroRun> acrossRuns;
  final List<KakuroRun> downRuns;
  final List<int> solution;
}
