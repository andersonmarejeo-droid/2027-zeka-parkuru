import 'dart:math' as math;

import '../shared/content_seed.dart';

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

class MiniSudokuPuzzle {
  static const int size = 6;
  static const int boxHeight = 2;
  static const int boxWidth = 3;
  static const int maximumUniqueCases = 300;
  static const int cellCount = size * size;
  static const List<int> _givenCountsByStage = <int>[
    28,
    26,
    24,
    22,
    20,
    18,
    17,
    16,
    15,
    14,
  ];

  static final Map<int, MiniSudokuPuzzle> _cache = <int, MiniSudokuPuzzle>{};

  const MiniSudokuPuzzle({
    required this.level,
    required this.localStage,
    required this.givens,
    required this.solution,
    required this.searchNodes,
  });

  final int level;
  final int localStage;
  final List<int> givens;
  final List<int> solution;

  /// Number of search states the exact solver visits while proving uniqueness.
  /// This is retained for test diagnostics and balancing future difficulty.
  final int searchNodes;

  int get givenCount => givens.where((int value) => value != 0).length;
  int get blankCount => cellCount - givenCount;
  String get boardSignature => givens.join();

  String get difficultyTier => switch (localStage) {
    <= 2 => 'BAŞLANGIÇ',
    <= 6 => 'USTALAŞMA',
    <= 8 => 'İLERİ',
    _ => 'UZMAN',
  };

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static int targetGivenCountForStage(int stage) =>
      _givenCountsByStage[(stage - 1).clamp(0, 9)];

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

  MiniSudokuAnalysis analyze({List<int>? board, int limit = 2}) =>
      analyzeBoard(board ?? givens, limit: limit);

  bool isSolved(List<int> board) {
    if (board.length != cellCount || board.any((int value) => value == 0)) {
      return false;
    }
    for (int index = 0; index < cellCount; index++) {
      if (board[index] != solution[index]) return false;
    }
    return true;
  }

  bool hasConflict(List<int> board, int index, int value) {
    if (board.length != cellCount || index < 0 || index >= cellCount) {
      return true;
    }
    if (value < 1 || value > size) return true;
    final int row = index ~/ size;
    final int column = index % size;
    for (int offset = 0; offset < size; offset++) {
      final int rowIndex = row * size + offset;
      final int columnIndex = offset * size + column;
      if (rowIndex != index && board[rowIndex] == value) return true;
      if (columnIndex != index && board[columnIndex] == value) return true;
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

  Set<int> candidatesFor(List<int> board, int index) {
    if (board.length != cellCount ||
        index < 0 ||
        index >= cellCount ||
        board[index] != 0) {
      return <int>{};
    }
    final Set<int> used = <int>{};
    final int row = index ~/ size;
    final int column = index % size;
    for (int offset = 0; offset < size; offset++) {
      used.add(board[row * size + offset]);
      used.add(board[offset * size + column]);
    }
    final int firstRow = (row ~/ boxHeight) * boxHeight;
    final int firstColumn = (column ~/ boxWidth) * boxWidth;
    for (int boxRow = firstRow; boxRow < firstRow + boxHeight; boxRow++) {
      for (
        int boxColumn = firstColumn;
        boxColumn < firstColumn + boxWidth;
        boxColumn++
      ) {
        used.add(board[boxRow * size + boxColumn]);
      }
    }
    return <int>{
      for (int value = 1; value <= size; value++)
        if (!used.contains(value)) value,
    };
  }

  static MiniSudokuAnalysis analyzeBoard(List<int> source, {int limit = 2}) {
    if (source.length != cellCount ||
        source.any((int value) => value < 0 || value > size) ||
        !_partialBoardIsValid(source)) {
      return const MiniSudokuAnalysis(
        solutionCount: 0,
        solution: null,
        searchNodes: 0,
      );
    }

    final List<int> board = List<int>.from(source);
    List<int>? firstSolution;
    int solutionCount = 0;
    int searchNodes = 0;

    void search() {
      if (solutionCount >= limit) return;
      searchNodes++;
      int selectedIndex = -1;
      Set<int>? selectedCandidates;
      for (int index = 0; index < cellCount; index++) {
        if (board[index] != 0) continue;
        final Set<int> candidates = _candidates(board, index);
        if (candidates.isEmpty) return;
        if (selectedCandidates == null ||
            candidates.length < selectedCandidates.length) {
          selectedIndex = index;
          selectedCandidates = candidates;
          if (candidates.length == 1) break;
        }
      }

      if (selectedIndex == -1) {
        solutionCount++;
        firstSolution ??= List<int>.unmodifiable(board);
        return;
      }

      for (final int value in selectedCandidates!) {
        board[selectedIndex] = value;
        search();
        board[selectedIndex] = 0;
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

  static bool _partialBoardIsValid(List<int> board) {
    for (int index = 0; index < cellCount; index++) {
      final int value = board[index];
      if (value == 0) continue;
      final int row = index ~/ size;
      final int column = index % size;
      for (int other = 0; other < index; other++) {
        if (board[other] != value) continue;
        final int otherRow = other ~/ size;
        final int otherColumn = other % size;
        if (row == otherRow || column == otherColumn) return false;
        if (row ~/ boxHeight == otherRow ~/ boxHeight &&
            column ~/ boxWidth == otherColumn ~/ boxWidth) {
          return false;
        }
      }
    }
    return true;
  }

  static Set<int> _candidates(List<int> board, int index) {
    final int row = index ~/ size;
    final int column = index % size;
    final Set<int> used = <int>{};
    for (int offset = 0; offset < size; offset++) {
      used.add(board[row * size + offset]);
      used.add(board[offset * size + column]);
    }
    final int firstRow = (row ~/ boxHeight) * boxHeight;
    final int firstColumn = (column ~/ boxWidth) * boxWidth;
    for (int boxRow = firstRow; boxRow < firstRow + boxHeight; boxRow++) {
      for (
        int boxColumn = firstColumn;
        boxColumn < firstColumn + boxWidth;
        boxColumn++
      ) {
        used.add(board[boxRow * size + boxColumn]);
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
    final int targetGivenCount = targetGivenCountForStage(stage);
    for (int attempt = 0; attempt < 24000; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'mini_sudoku',
        level: level,
        attempt: attempt,
      );
      final List<int> solved = _randomSolvedBoard(random);
      final List<int> board = List<int>.from(solved);
      final List<int> removalOrder = List<int>.generate(
        cellCount,
        (int index) => index,
      )..shuffle(random);
      MiniSudokuAnalysis analysis = analyzeBoard(board);
      int remaining = cellCount;

      for (final int index in removalOrder) {
        if (remaining == targetGivenCount) break;
        board[index] = 0;
        analysis = analyzeBoard(board);
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
      final String signature = board.join();
      if (usedSignatures.contains(signature)) continue;

      return MiniSudokuPuzzle(
        level: level,
        localStage: stage,
        givens: List<int>.unmodifiable(board),
        solution: List<int>.unmodifiable(analysis.solution!),
        searchNodes: analysis.searchNodes,
      );
    }
    throw StateError(
      'Could not create a unique 6×6 Sudoku for level $level '
      'with $targetGivenCount clues.',
    );
  }

  static List<int> _randomSolvedBoard(math.Random random) {
    final List<int> rowOrder = <int>[];
    final List<int> rowBands = <int>[0, 1, 2]..shuffle(random);
    for (final int band in rowBands) {
      final List<int> insideBand = <int>[0, 1]..shuffle(random);
      rowOrder.addAll(insideBand.map((int row) => band * boxHeight + row));
    }

    final List<int> columnOrder = <int>[];
    final List<int> columnStacks = <int>[0, 1]..shuffle(random);
    for (final int stack in columnStacks) {
      final List<int> insideStack = <int>[0, 1, 2]..shuffle(random);
      columnOrder.addAll(
        insideStack.map((int column) => stack * boxWidth + column),
      );
    }
    final List<int> symbols = <int>[1, 2, 3, 4, 5, 6]..shuffle(random);

    return <int>[
      for (int newRow = 0; newRow < size; newRow++)
        for (int newColumn = 0; newColumn < size; newColumn++)
          symbols[(rowOrder[newRow] * boxWidth +
                  rowOrder[newRow] ~/ boxHeight +
                  columnOrder[newColumn]) %
              size],
    ];
  }
}
