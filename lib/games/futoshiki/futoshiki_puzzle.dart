import 'dart:math' as math;

import '../shared/content_seed.dart';

class FutoshikiRelation {
  const FutoshikiRelation({required this.lessCell, required this.greaterCell});

  final int lessCell;
  final int greaterCell;

  String get signature => '$lessCell<$greaterCell';

  @override
  bool operator ==(Object other) =>
      other is FutoshikiRelation &&
      other.lessCell == lessCell &&
      other.greaterCell == greaterCell;

  @override
  int get hashCode => Object.hash(lessCell, greaterCell);
}

class FutoshikiSolveResult {
  const FutoshikiSolveResult({
    required this.solutionCount,
    required this.visitedNodes,
    required this.limitReached,
  });

  final int solutionCount;
  final int visitedNodes;
  final bool limitReached;
}

class FutoshikiPuzzle {
  FutoshikiPuzzle._({
    required this.level,
    required this.seed,
    required this.size,
    required List<int?> givens,
    required List<int> solution,
    required List<FutoshikiRelation> relations,
    required this.certificationNodes,
  }) : givens = List<int?>.unmodifiable(givens),
       solution = List<int>.unmodifiable(solution),
       relations = List<FutoshikiRelation>.unmodifiable(relations);

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static const int _nodeBudget = 160000;
  static final Map<int, FutoshikiPuzzle> _campaign = <int, FutoshikiPuzzle>{};
  static final Map<int, FutoshikiPuzzle> _practice = <int, FutoshikiPuzzle>{};

  final int level;
  final int seed;
  final int size;
  final List<int?> givens;
  final List<int> solution;
  final List<FutoshikiRelation> relations;
  final int certificationNodes;

  int get givenCount => givens.whereType<int>().length;
  int get blankCount => givens.length - givenCount;
  int get horizontalAndVerticalRelations => relations.length;

  String get difficultyTier => switch (level) {
    <= 4 => 'FOUNDATION',
    5 || 6 => 'BUILDING',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP READING',
    _ => 'MASTER FUTOSHIKI',
  };

  String get signature => _boardSignature(size, givens, relations);

  bool get solutionRespectsRules =>
      solution.length == size * size &&
      solution.every((int value) => value >= 1 && value <= size) &&
      _isCompleteLatinSquare(size, solution) &&
      _respectsRelations(solution, relations);

  bool matches(List<int?> cells) =>
      cells.length == solution.length &&
      cells.asMap().entries.every(
        (MapEntry<int, int?> entry) => entry.value == solution[entry.key],
      );

  FutoshikiRelation? relationBetween(int firstCell, int secondCell) {
    for (final FutoshikiRelation relation in relations) {
      if ((relation.lessCell == firstCell &&
              relation.greaterCell == secondCell) ||
          (relation.lessCell == secondCell &&
              relation.greaterCell == firstCell)) {
        return relation;
      }
    }
    return null;
  }

  bool get isCertified {
    if (!solutionRespectsRules || givens.length != size * size) return false;
    for (int cell = 0; cell < givens.length; cell++) {
      final int? value = givens[cell];
      if (value != null && value != solution[cell]) return false;
    }
    final FutoshikiSolveResult result = countSolutions(
      size: size,
      givens: givens,
      relations: relations,
      limit: 2,
      nodeBudget: _nodeBudget,
    );
    return result.solutionCount == 1 && !result.limitReached;
  }

  static int sizeForLevel(int level) => switch (level) {
    >= 1 && <= 4 => 4,
    >= 5 && <= 8 => 5,
    >= 9 && <= maximumLevels => 6,
    _ => throw RangeError.range(level, 1, maximumLevels, 'level'),
  };

  static int minimumGivenCountForLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return switch (level) {
      1 => 10,
      2 => 9,
      3 => 8,
      4 => 7,
      5 => 14,
      6 => 12,
      7 => 11,
      8 => 10,
      9 => 15,
      10 => 13,
      11 => 12,
      12 => 11,
      13 => 10,
      14 => 9,
      15 => 8,
      16 => 8,
      17 => 8,
      18 => 7,
      19 || 20 => 6,
      _ => throw RangeError.range(level, 1, maximumLevels, 'level'),
    };
  }

  static int targetRelationCountForLevel(int level) {
    final int size = sizeForLevel(level);
    final int total = 2 * size * (size - 1);
    final int target = switch (level) {
      <= 4 => 5 + level * 2,
      5 || 6 => 11 + (level - 5) * 3,
      7 || 8 => 19 + (level - 7) * 3,
      9 || 10 => 27 + (level - 9) * 4,
      <= 16 => 34 + (level - 11) * 2,
      _ => 45 + (level - 17) * 3,
    };
    return target.clamp(4, total);
  }

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'seed': seed,
    'size': size,
    'certificationNodes': certificationNodes,
    'solution': solution,
    'givens': givens,
    'relations': relations.map((r) => [r.lessCell, r.greaterCell]).toList(),
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) throw FormatException('Invalid futoshiki bank');
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _practice[i + 1] = FutoshikiPuzzle._(
        level: m['level'] as int,
        seed: m['seed'] as int,
        size: m['size'] as int,
        certificationNodes: m['certificationNodes'] as int,
        solution: List<int>.from(m['solution'] as List),
        givens: List<int?>.from(m['givens'] as List),
        relations: (m['relations'] as List)
            .map(
              (e) => FutoshikiRelation(
                lessCell: e[0] as int,
                greaterCell: e[1] as int,
              ),
            )
            .toList(),
      );
    }
  }

  static FutoshikiPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    for (int next = 1; next <= level; next++) {
      if (_campaign.containsKey(next)) continue;
      _campaign[next] = _generate(
        next,
        contentCycle: 0,
        usedSignatures: _usedSignatures,
      );
    }
    return _campaign[level]!;
  }

  static FutoshikiPuzzle forPracticeBoard(int index) {
    final cached = _practice[index];
    if (cached != null) return cached;
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
    ..._campaign.values.map((FutoshikiPuzzle puzzle) => puzzle.signature),
    ..._practice.values.map((FutoshikiPuzzle puzzle) => puzzle.signature),
  };

  static FutoshikiSolveResult countSolutions({
    required int size,
    required List<int?> givens,
    required List<FutoshikiRelation> relations,
    int limit = 2,
    int nodeBudget = _nodeBudget,
  }) {
    if (size < 2 || size > 9 || givens.length != size * size || limit < 1) {
      throw ArgumentError('Invalid Futoshiki solver dimensions or limit.');
    }
    final List<int> cells = List<int>.filled(size * size, 0);
    final List<int> rowMasks = List<int>.filled(size, 0);
    final List<int> columnMasks = List<int>.filled(size, 0);
    for (int cell = 0; cell < givens.length; cell++) {
      final int? value = givens[cell];
      if (value == null) continue;
      if (value < 1 || value > size) {
        return const FutoshikiSolveResult(
          solutionCount: 0,
          visitedNodes: 0,
          limitReached: false,
        );
      }
      final int row = cell ~/ size;
      final int column = cell % size;
      final int bit = 1 << (value - 1);
      if ((rowMasks[row] & bit) != 0 || (columnMasks[column] & bit) != 0) {
        return const FutoshikiSolveResult(
          solutionCount: 0,
          visitedNodes: 0,
          limitReached: false,
        );
      }
      cells[cell] = value;
      rowMasks[row] |= bit;
      columnMasks[column] |= bit;
    }
    if (!_partialRelationsValid(cells, relations)) {
      return const FutoshikiSolveResult(
        solutionCount: 0,
        visitedNodes: 0,
        limitReached: false,
      );
    }

    int solutions = 0;
    int nodes = 0;
    bool budgetReached = false;
    final int fullMask = (1 << size) - 1;

    List<int> candidatesFor(int cell) {
      final int row = cell ~/ size;
      final int column = cell % size;
      int available = fullMask & ~(rowMasks[row] | columnMasks[column]);
      final List<int> candidates = <int>[];
      while (available != 0) {
        final int bit = available & -available;
        available ^= bit;
        final int value = bit.bitLength;
        bool valid = true;
        for (final FutoshikiRelation relation in relations) {
          if (relation.lessCell == cell && cells[relation.greaterCell] != 0) {
            if (value >= cells[relation.greaterCell]) valid = false;
          } else if (relation.greaterCell == cell &&
              cells[relation.lessCell] != 0) {
            if (value <= cells[relation.lessCell]) valid = false;
          }
          if (!valid) break;
        }
        if (valid) candidates.add(value);
      }
      return candidates;
    }

    void search() {
      if (solutions >= limit || budgetReached) return;
      if (nodes >= nodeBudget) {
        budgetReached = true;
        return;
      }
      nodes++;
      int selected = -1;
      List<int>? selectedCandidates;
      for (int cell = 0; cell < cells.length; cell++) {
        if (cells[cell] != 0) continue;
        final List<int> candidates = candidatesFor(cell);
        if (candidates.isEmpty) return;
        if (selectedCandidates == null ||
            candidates.length < selectedCandidates.length) {
          selected = cell;
          selectedCandidates = candidates;
          if (candidates.length == 1) break;
        }
      }
      if (selected < 0) {
        solutions++;
        return;
      }
      final int row = selected ~/ size;
      final int column = selected % size;
      for (final int value in selectedCandidates!) {
        final int bit = 1 << (value - 1);
        cells[selected] = value;
        rowMasks[row] |= bit;
        columnMasks[column] |= bit;
        search();
        cells[selected] = 0;
        rowMasks[row] ^= bit;
        columnMasks[column] ^= bit;
        if (solutions >= limit || budgetReached) return;
      }
    }

    search();
    return FutoshikiSolveResult(
      solutionCount: solutions,
      visitedNodes: nodes,
      limitReached: budgetReached,
    );
  }

  static FutoshikiPuzzle _generate(
    int level, {
    required int contentCycle,
    required Set<String> usedSignatures,
  }) {
    final int size = sizeForLevel(level);
    final int givenTarget = minimumGivenCountForLevel(level);
    final int relationTarget = targetRelationCountForLevel(level);
    for (int attempt = 0; attempt < 1800; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'futoshiki:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final List<int> rowOrder = List<int>.generate(size, (int i) => i)
        ..shuffle(random);
      final List<int> columnOrder = List<int>.generate(size, (int i) => i)
        ..shuffle(random);
      final List<int> symbols = List<int>.generate(size, (int i) => i + 1)
        ..shuffle(random);
      final List<int> solution = List<int>.generate(size * size, (int cell) {
        final int row = cell ~/ size;
        final int column = cell % size;
        return symbols[(rowOrder[row] + columnOrder[column]) % size];
      });
      final List<FutoshikiRelation> availableRelations = _allRelations(size)
        ..shuffle(random);
      final List<FutoshikiRelation> relations = availableRelations
          .take(relationTarget)
          .map((FutoshikiRelation candidate) {
            final int lesser = solution[candidate.lessCell];
            final int greater = solution[candidate.greaterCell];
            return lesser < greater
                ? candidate
                : FutoshikiRelation(
                    lessCell: candidate.greaterCell,
                    greaterCell: candidate.lessCell,
                  );
          })
          .toList(growable: false);
      final List<int> clueCells = List<int>.generate(size * size, (int i) => i)
        ..shuffle(random);
      final List<int?> givens = List<int?>.filled(size * size, null);
      for (final int cell in clueCells.take(givenTarget)) {
        givens[cell] = solution[cell];
      }
      final String signature = _boardSignature(size, givens, relations);
      if (usedSignatures.contains(signature)) continue;
      final FutoshikiSolveResult certification = countSolutions(
        size: size,
        givens: givens,
        relations: relations,
        limit: 2,
        nodeBudget: _nodeBudget,
      );
      if (certification.solutionCount != 1 || certification.limitReached) {
        continue;
      }
      return FutoshikiPuzzle._(
        level: level,
        seed: seed,
        size: size,
        givens: givens,
        solution: solution,
        relations: relations,
        certificationNodes: certification.visitedNodes,
      );
    }
    throw StateError(
      'Could not certify a distinct unique Futoshiki board for level $level.',
    );
  }

  static List<FutoshikiRelation> _allRelations(int size) => <FutoshikiRelation>[
    for (int row = 0; row < size; row++)
      for (int column = 0; column < size; column++) ...<FutoshikiRelation>[
        if (column + 1 < size)
          FutoshikiRelation(
            lessCell: row * size + column,
            greaterCell: row * size + column + 1,
          ),
        if (row + 1 < size)
          FutoshikiRelation(
            lessCell: row * size + column,
            greaterCell: (row + 1) * size + column,
          ),
      ],
  ];

  static String _boardSignature(
    int size,
    List<int?> givens,
    List<FutoshikiRelation> relations,
  ) {
    final List<String> signatures =
        relations
            .map((FutoshikiRelation relation) => relation.signature)
            .toList()
          ..sort();
    return '$size:${givens.map((int? value) => value ?? 0).join()}:${signatures.join(',')}';
  }

  static bool _isCompleteLatinSquare(int size, List<int> cells) {
    final int fullMask = (1 << size) - 1;
    for (int row = 0; row < size; row++) {
      int mask = 0;
      for (int column = 0; column < size; column++) {
        final int bit = 1 << (cells[row * size + column] - 1);
        if ((mask & bit) != 0) return false;
        mask |= bit;
      }
      if (mask != fullMask) return false;
    }
    for (int column = 0; column < size; column++) {
      int mask = 0;
      for (int row = 0; row < size; row++) {
        final int bit = 1 << (cells[row * size + column] - 1);
        if ((mask & bit) != 0) return false;
        mask |= bit;
      }
      if (mask != fullMask) return false;
    }
    return true;
  }

  static bool _respectsRelations(
    List<int> values,
    List<FutoshikiRelation> relations,
  ) => relations.every(
    (FutoshikiRelation relation) =>
        values[relation.lessCell] < values[relation.greaterCell],
  );

  static bool _partialRelationsValid(
    List<int> values,
    List<FutoshikiRelation> relations,
  ) => relations.every((FutoshikiRelation relation) {
    final int lesser = values[relation.lessCell];
    final int greater = values[relation.greaterCell];
    return lesser == 0 || greater == 0 || lesser < greater;
  });
}
