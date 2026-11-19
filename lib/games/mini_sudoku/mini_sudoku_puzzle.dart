import 'dart:math' as math;

import '../shared/content_seed.dart';
import '../shared/studio_game_contracts.dart';

class MiniSudokuAnalysis {
  const MiniSudokuAnalysis({
    required this.solutionCount,
    required this.solution,
    required this.searchNodes,
  });

  final int solutionCount;
  final List<int>? solution;
  final int searchNodes;
}

/// Kademeli Sudoku:
/// 1–6. Seviyeler: 4×4 Mini Sudoku (2×2 kutular, 1–4 rakamları, hızlı ısınma & kolay başlangıç)
/// 7–19. Seviyeler: 6×6 Sudoku (2×3 kutular, 1–6 rakamları, gelişim & hız)
/// 20–30+ Seviyeler: 9×9 Klasik & Uzman Sudoku (3×3 kutular, 1–9 rakamları)
class MiniSudokuPuzzle {
  static const int maximumUniqueCases = 300;
  static const int campaignStages = 30;

  // 4×4 Seviyeler (1–6): 16 hücreden 8–11 ipucu dolu
  static const List<int> _fourByFourGivenCounts = <int>[
    11,
    11,
    10,
    10,
    9,
    8,
  ];

  // 6×6 Seviyeler (7–19): 36 hücreden 14–24 ipucu dolu
  static const List<int> _sixBySixGivenCounts = <int>[
    24,
    23,
    22,
    21,
    20,
    19,
    18,
    17,
    16,
    16,
    15,
    15,
    14,
  ];

  // 9×9 Seviyeler (20–30): 81 hücreden 24–52 ipucu dolu
  static const List<int> _nineByNineGivenCounts = <int>[
    52,
    48,
    44,
    40,
    36,
    33,
    30,
    28,
    26,
    25,
    24,
  ];

  static final Map<int, MiniSudokuPuzzle> _cache = <int, MiniSudokuPuzzle>{};
  static final Map<int, _NineSudokuCore> _nineByNineCores =
      <int, _NineSudokuCore>{};

  const MiniSudokuPuzzle({
    required this.level,
    required this.localStage,
    required this.size,
    required this.boxHeight,
    required this.boxWidth,
    required this.givens,
    required this.solution,
    required this.searchNodes,
  });

  final int level;
  final int localStage;
  final int size;
  final int boxHeight;
  final int boxWidth;
  final List<int> givens;
  final List<int> solution;

  /// Number of search states visited while proving the board has one solution.
  final int searchNodes;

  int get cellCount => size * size;
  int get givenCount => givens.where((int value) => value != 0).length;
  int get blankCount => cellCount - givenCount;
  String get boardSignature => '${size}x$size:${givens.join()}';

  String get difficultyTier => switch (localStage) {
    <= 6 => 'BAŞLANGIÇ 4×4',
    <= 12 => 'KOLAY 6×6',
    <= 19 => 'GELİŞİM 6×6',
    <= 24 => 'KLASİK 9×9',
    <= 28 => 'UZMAN 9×9',
    _ => 'USTA 9×9',
  };

  static int stageForLevel(int level) {
    if (level <= maximumUniqueCases) {
      return ((level - 1) % campaignStages) + 1;
    }
    final int safeLevel = GameContentPolicy.endlessHighChapter(level);
    return safeLevel;
  }

  static int sizeForStage(int stage) {
    if (stage <= 6) return 4;
    if (stage <= 19) return 6;
    return 9;
  }

  static int boxHeightForStage(int stage) => sizeForStage(stage) == 9 ? 3 : 2;

  static int boxWidthForStage(int stage) => sizeForStage(stage) == 4 ? 2 : 3;

  static int targetGivenCountForStage(int stage) {
    if (stage <= 6) {
      return _fourByFourGivenCounts[
          (stage - 1).clamp(0, _fourByFourGivenCounts.length - 1)];
    }
    if (stage <= 19) {
      return _sixBySixGivenCounts[
          (stage - 7).clamp(0, _sixBySixGivenCounts.length - 1)];
    }
    return _nineByNineGivenCounts[
        (stage - 20).clamp(0, _nineByNineGivenCounts.length - 1)];
  }

  static MiniSudokuPuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    for (int nextLevel = 1; nextLevel <= level; nextLevel++) {
      if (_cache.containsKey(nextLevel)) continue;
      _cache[nextLevel] = _generate(
        nextLevel,
        usedSignatures: _cache.values
            .map((MiniSudokuPuzzle puzzle) => puzzle.boardSignature)
            .toSet(),
      );
    }
    return _cache[level]!;
  }

  MiniSudokuAnalysis analyze({List<int>? board, int limit = 2}) => analyzeBoard(
    board ?? givens,
    size: size,
    boxHeight: boxHeight,
    boxWidth: boxWidth,
    limit: limit,
  );

  bool isSolved(List<int> board) {
    if (board.length != cellCount || board.any((int value) => value == 0)) {
      return false;
    }
    for (int index = 0; index < cellCount; index++) {
      if (hasConflict(board, index, board[index])) return false;
    }
    return true;
  }

  bool hasConflict(List<int> board, int index, int value) {
    if (index < 0 || index >= cellCount) return true;
    if (value < 1 || value > size) return true;
    final int row = index ~/ size;
    final int column = index % size;

    for (int c = 0; c < size; c++) {
      final int otherIndex = row * size + c;
      if (otherIndex != index && board[otherIndex] == value) return true;
    }

    for (int r = 0; r < size; r++) {
      final int otherIndex = r * size + column;
      if (otherIndex != index && board[otherIndex] == value) return true;
    }

    final int firstRow = (row ~/ boxHeight) * boxHeight;
    final int firstColumn = (column ~/ boxWidth) * boxWidth;
    for (int boxRow = firstRow; boxRow < firstRow + boxHeight; boxRow++) {
      for (
        int boxColumn = firstColumn;
        boxColumn < firstColumn + boxWidth;
        boxColumn++
      ) {
        final int otherIndex = boxRow * size + boxColumn;
        if (otherIndex != index && board[otherIndex] == value) return true;
      }
    }
    return false;
  }

  Set<int> possibleValues(List<int> board, int index) {
    if (board[index] != 0) return const <int>{};
    final int row = index ~/ size;
    final int column = index % size;
    final Set<int> used = <int>{};

    for (int c = 0; c < size; c++) {
      final int value = board[row * size + c];
      if (value != 0) used.add(value);
    }
    for (int r = 0; r < size; r++) {
      final int value = board[r * size + column];
      if (value != 0) used.add(value);
    }

    final int firstRow = (row ~/ boxHeight) * boxHeight;
    final int firstColumn = (column ~/ boxWidth) * boxWidth;
    for (int boxRow = firstRow; boxRow < firstRow + boxHeight; boxRow++) {
      for (
        int boxColumn = firstColumn;
        boxColumn < firstColumn + boxWidth;
        boxColumn++
      ) {
        final int value = board[boxRow * size + boxColumn];
        if (value != 0) used.add(value);
      }
    }

    return <int>{
      for (int value = 1; value <= size; value++)
        if (!used.contains(value)) value,
    };
  }

  Set<int> candidatesFor(List<int> board, int index) =>
      possibleValues(board, index);

  static MiniSudokuAnalysis analyzeBoard(
    List<int> source, {
    required int size,
    int boxHeight = 2,
    int boxWidth = 3,
    int limit = 2,
  }) {
    if (source.length != size * size ||
        source.any((int value) => value < 0 || value > size) ||
        !_hasNoInitialConflicts(
          source,
          size: size,
          boxHeight: boxHeight,
          boxWidth: boxWidth,
        )) {
      return const MiniSudokuAnalysis(
        solutionCount: 0,
        solution: null,
        searchNodes: 0,
      );
    }

    final List<int> working = List<int>.from(source);
    int solutionCount = 0;
    List<int>? firstSolution;
    int searchNodes = 0;

    void search() {
      if (solutionCount >= limit) return;
      searchNodes++;

      int? bestIndex;
      Set<int>? selectedCandidates;

      for (int index = 0; index < working.length; index++) {
        if (working[index] != 0) continue;
        final Set<int> candidates = _validCandidatesAt(
          working,
          index,
          size: size,
          boxHeight: boxHeight,
          boxWidth: boxWidth,
        );
        if (candidates.isEmpty) return;
        if (selectedCandidates == null ||
            candidates.length < selectedCandidates.length) {
          selectedCandidates = candidates;
          bestIndex = index;
          if (candidates.length == 1) break;
        }
      }

      if (bestIndex == null) {
        solutionCount++;
        firstSolution ??= List<int>.unmodifiable(working);
        return;
      }

      for (final int candidate in selectedCandidates!) {
        working[bestIndex] = candidate;
        search();
        working[bestIndex] = 0;
        if (solutionCount >= limit) return;
      }
    }

    search();
    return MiniSudokuAnalysis(
      solutionCount: solutionCount,
      solution: firstSolution,
      searchNodes: searchNodes,
    );
  }

  static bool _hasNoInitialConflicts(
    List<int> board, {
    required int size,
    required int boxHeight,
    required int boxWidth,
  }) {
    for (int index = 0; index < board.length; index++) {
      final int value = board[index];
      if (value == 0) continue;
      final int row = index ~/ size;
      final int column = index % size;

      for (int c = 0; c < size; c++) {
        final int otherIndex = row * size + c;
        if (otherIndex != index && board[otherIndex] == value) return false;
      }

      for (int r = 0; r < size; r++) {
        final int otherIndex = r * size + column;
        if (otherIndex != index && board[otherIndex] == value) return false;
      }

      final int firstRow = (row ~/ boxHeight) * boxHeight;
      final int firstColumn = (column ~/ boxWidth) * boxWidth;
      for (int boxRow = firstRow; boxRow < firstRow + boxHeight; boxRow++) {
        for (
          int boxColumn = firstColumn;
          boxColumn < firstColumn + boxWidth;
          boxColumn++
        ) {
          final int otherIndex = boxRow * size + boxColumn;
          if (otherIndex != index && board[otherIndex] == value) return false;
        }
      }
    }
    return true;
  }

  static Set<int> _validCandidatesAt(
    List<int> board,
    int index, {
    required int size,
    required int boxHeight,
    required int boxWidth,
  }) {
    final int row = index ~/ size;
    final int column = index % size;
    final Set<int> used = <int>{};

    for (int c = 0; c < size; c++) {
      final int value = board[row * size + c];
      if (value != 0) used.add(value);
    }
    for (int r = 0; r < size; r++) {
      final int value = board[r * size + column];
      if (value != 0) used.add(value);
    }

    final int firstRow = (row ~/ boxHeight) * boxHeight;
    final int firstColumn = (column ~/ boxWidth) * boxWidth;
    for (int boxRow = firstRow; boxRow < firstRow + boxHeight; boxRow++) {
      for (
        int boxColumn = firstColumn;
        boxColumn < firstColumn + boxWidth;
        boxColumn++
      ) {
        final int value = board[boxRow * size + boxColumn];
        if (value != 0) used.add(value);
      }
    }

    return <int>{
      for (int value = 1; value <= size; value++)
        if (!used.contains(value)) value,
    };
  }

  static MiniSudokuPuzzle _generate(
    int level, {
    required Set<String> usedSignatures,
  }) {
    final int stage = stageForLevel(level);
    final int size = sizeForStage(stage);
    final int boxHeight = boxHeightForStage(stage);
    final int boxWidth = boxWidthForStage(stage);
    final int targetGivenCount = targetGivenCountForStage(stage);
    if (size == 9) {
      return _generateNineByNine(
        level: level,
        stage: stage,
        boxHeight: boxHeight,
        boxWidth: boxWidth,
        targetGivenCount: targetGivenCount,
        usedSignatures: usedSignatures,
      );
    }

    for (int attempt = 0; attempt < 24000; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'mini_sudoku',
        level: level,
        attempt: attempt,
      );
      final List<int> solved = _randomSolvedBoard(
        random,
        size: size,
        boxHeight: boxHeight,
        boxWidth: boxWidth,
      );
      final List<int> board = List<int>.from(solved);
      final List<int> removalOrder = List<int>.generate(
        size * size,
        (int index) => index,
      )..shuffle(random);
      MiniSudokuAnalysis analysis = analyzeBoard(
        board,
        size: size,
        boxHeight: boxHeight,
        boxWidth: boxWidth,
      );
      int remaining = size * size;

      for (final int index in removalOrder) {
        if (remaining == targetGivenCount) break;
        board[index] = 0;
        analysis = analyzeBoard(
          board,
          size: size,
          boxHeight: boxHeight,
          boxWidth: boxWidth,
        );
        if (analysis.solutionCount == 1) {
          remaining--;
        } else {
          board[index] = solved[index];
        }
      }

      if (remaining != targetGivenCount ||
          analysis.solutionCount != 1 ||
          analysis.solution == null) {
        continue;
      }
      final String signature = '${size}x$size:${board.join()}';
      if (usedSignatures.contains(signature)) continue;

      return MiniSudokuPuzzle(
        level: level,
        localStage: stage,
        size: size,
        boxHeight: boxHeight,
        boxWidth: boxWidth,
        givens: List<int>.unmodifiable(board),
        solution: List<int>.unmodifiable(analysis.solution!),
        searchNodes: analysis.searchNodes,
      );
    }
    throw StateError(
      'Could not create a unique $size×$size Sudoku for level $level '
      'with $targetGivenCount clues.',
    );
  }

  static MiniSudokuPuzzle _generateNineByNine({
    required int level,
    required int stage,
    required int boxHeight,
    required int boxWidth,
    required int targetGivenCount,
    required Set<String> usedSignatures,
  }) {
    final _NineSudokuCore core = _nineByNineCores.putIfAbsent(
      stage,
      () => _createNineByNineCore(stage, targetGivenCount),
    );
    for (int attempt = 0; attempt < 1024; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'mini_sudoku',
        level: level,
        attempt: attempt,
      );
      final _NineSudokuCore transformed = core.transformed(random);
      final List<int> board = List<int>.from(transformed.coreGivens);
      final String signature = '9x9:${board.join()}';
      if (usedSignatures.contains(signature)) continue;

      final MiniSudokuAnalysis analysis = analyzeBoard(
        board,
        size: 9,
        boxHeight: boxHeight,
        boxWidth: boxWidth,
      );
      if (analysis.solutionCount != 1 ||
          analysis.solution == null ||
          !_sameValues(analysis.solution!, transformed.solution)) {
        throw StateError('Invalid transformed 9×9 Sudoku at level $level.');
      }
      return MiniSudokuPuzzle(
        level: level,
        localStage: stage,
        size: 9,
        boxHeight: boxHeight,
        boxWidth: boxWidth,
        givens: List<int>.unmodifiable(board),
        solution: List<int>.unmodifiable(transformed.solution),
        searchNodes: analysis.searchNodes,
      );
    }
    throw StateError('Could not create a unique 9×9 Sudoku for level $level.');
  }

  static _NineSudokuCore _createNineByNineCore(int stage, int targetClues) {
    for (int attempt = 0; attempt < 24000; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'mini_sudoku_nine_core',
        level: stage,
        attempt: attempt,
      );
      final List<int> solution = _randomSolvedBoard(
        random,
        size: 9,
        boxHeight: 3,
        boxWidth: 3,
      );
      final List<int> board = List<int>.from(solution);
      final List<int> removalOrder = List<int>.generate(
        81,
        (int index) => index,
      )..shuffle(random);
      int remaining = 81;

      for (final int index in removalOrder) {
        if (remaining == targetClues) break;
        board[index] = 0;
        final MiniSudokuAnalysis analysis = analyzeBoard(
          board,
          size: 9,
          boxHeight: 3,
          boxWidth: 3,
        );
        if (analysis.solutionCount == 1) {
          remaining--;
        } else {
          board[index] = solution[index];
        }
      }
      if (remaining == targetClues) {
        return _NineSudokuCore(
          solution: List<int>.unmodifiable(solution),
          coreGivens: List<int>.unmodifiable(board),
        );
      }
    }
    throw StateError('Could not prepare the unique 9×9 expert template.');
  }

  static List<int> _randomSolvedBoard(
    math.Random random, {
    required int size,
    required int boxHeight,
    required int boxWidth,
  }) {
    final List<int> rowOrder = <int>[];
    final List<int> rowBands = List<int>.generate(
      size ~/ boxHeight,
      (int index) => index,
    )..shuffle(random);
    for (final int band in rowBands) {
      final List<int> insideBand = List<int>.generate(
        boxHeight,
        (int row) => row,
      )..shuffle(random);
      rowOrder.addAll(insideBand.map((int row) => band * boxHeight + row));
    }

    final List<int> columnOrder = <int>[];
    final List<int> columnStacks = List<int>.generate(
      size ~/ boxWidth,
      (int index) => index,
    )..shuffle(random);
    for (final int stack in columnStacks) {
      final List<int> insideStack = List<int>.generate(
        boxWidth,
        (int col) => col,
      )..shuffle(random);
      columnOrder.addAll(insideStack.map((int col) => stack * boxWidth + col));
    }

    final List<int> symbolMap = List<int>.generate(
      size,
      (int index) => index + 1,
    )..shuffle(random);

    return <int>[
      for (int row = 0; row < size; row++)
        for (int column = 0; column < size; column++)
          symbolMap[(rowOrder[row] * boxWidth +
                  rowOrder[row] ~/ boxHeight +
                  columnOrder[column]) %
              size],
    ];
  }

  static bool _sameValues(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class _NineSudokuCore {
  const _NineSudokuCore({required this.solution, required this.coreGivens});

  final List<int> solution;
  final List<int> coreGivens;

  _NineSudokuCore transformed(math.Random random) {
    final List<int> rowPermutation = <int>[];
    final List<int> bandPermutation = <int>[0, 1, 2]..shuffle(random);
    for (final int band in bandPermutation) {
      final List<int> rowsInsideBand = <int>[0, 1, 2]..shuffle(random);
      rowPermutation.addAll(
        rowsInsideBand.map((int offset) => band * 3 + offset),
      );
    }

    final List<int> columnPermutation = <int>[];
    final List<int> stackPermutation = <int>[0, 1, 2]..shuffle(random);
    for (final int stack in stackPermutation) {
      final List<int> colsInsideStack = <int>[0, 1, 2]..shuffle(random);
      columnPermutation.addAll(
        colsInsideStack.map((int offset) => stack * 3 + offset),
      );
    }

    final List<int> digitMap = List<int>.generate(9, (int index) => index + 1)
      ..shuffle(random);

    int mapValue(int value) => value == 0 ? 0 : digitMap[value - 1];

    List<int> remap(List<int> input) {
      final List<int> output = List<int>.filled(81, 0);
      for (int row = 0; row < 9; row++) {
        for (int column = 0; column < 9; column++) {
          final int mappedRow = rowPermutation[row];
          final int mappedColumn = columnPermutation[column];
          output[row * 9 + column] = mapValue(
            input[mappedRow * 9 + mappedColumn],
          );
        }
      }
      return output;
    }

    return _NineSudokuCore(
      solution: remap(solution),
      coreGivens: remap(coreGivens),
    );
  }
}
