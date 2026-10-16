import 'dart:math' as math;

import '../shared/content_seed.dart';

class MassObjectToken {
  const MassObjectToken({
    required this.index,
    required this.glyphIndex,
    required this.isDecoy,
  });

  final int index;
  final int glyphIndex;
  final bool isDecoy;

  String get label => String.fromCharCode(65 + index);

  String get signature => '$index:$glyphIndex:${isDecoy ? 1 : 0}';
}

class MassEquation {
  const MassEquation({required this.objectIndices, required this.grams});

  /// Repeated indices represent repeated objects, for example `[5, 5, 0]`.
  final List<int> objectIndices;
  final int grams;

  String get signature => '${objectIndices.join(',')}=$grams';

  int evaluate(List<int> masses) => objectIndices.fold<int>(
    0,
    (int total, int index) => total + masses[index],
  );

  List<double> coefficientRow(int variableCount) {
    final List<double> row = List<double>.filled(variableCount + 1, 0);
    for (final int index in objectIndices) {
      if (index < variableCount) row[index]++;
    }
    row[variableCount] = grams.toDouble();
    return row;
  }
}

/// A fixed, auditable campaign of object-mass deduction puzzles.
///
/// The board presents sums from balanced scales. Levels 1–6 use three unknowns,
/// 7–8 introduce a fourth and 9–10 a fifth. The second chapter adds an unused
/// visual decoy, then expands the deduction chain to six unknowns. Its final
/// pair includes a repeated-object calibration clue. Every active value is
/// uniquely determined by the visible equations.
class HiddenMassPuzzle {
  const HiddenMassPuzzle({
    required this.level,
    required this.chapter,
    required this.stageInChapter,
    required this.activeObjectCount,
    required this.objects,
    required this.equations,
    required this.targetObjectIndex,
    required this.answerGrams,
    required this.answerChoices,
  });

  static const int maximumLevels = 20;
  static const int poolSize = 300;
  static final Map<int, HiddenMassPuzzle> _pool = {};
  static final Set<String> _poolSignatures = {};

  static HiddenMassPuzzle forPool(int index) {
    RangeError.checkValueInInterval(index, 1, poolSize, 'index');
    final templates = List<HiddenMassPuzzle>.generate(maximumLevels, (i) => forLevel(i + 1))
      ..sort((a, b) {
        final comparison = (a.activeObjectCount * 10 + a.decoyCount).compareTo(b.activeObjectCount * 10 + b.decoyCount);
        return comparison != 0 ? comparison : a.level.compareTo(b.level);
      });
    for (int next = _pool.length + 1; next <= index; next++) {
      final native = templates[(next - 1) % maximumLevels].level;
      int variant = (next - 1) ~/ maximumLevels;
      HiddenMassPuzzle candidate;
      do { candidate = _generate(native, variant: variant++); }
      while (!_poolSignatures.add(candidate.boardSignature));
      _pool[next] = candidate;
    }
    return _pool[index]!;
  }
  static final Map<int, HiddenMassPuzzle> _cache = <int, HiddenMassPuzzle>{};

  static const List<List<int>> _solutions = <List<int>>[
    <int>[4, 6, 8],
    <int>[5, 9, 4],
    <int>[8, 3, 7],
    <int>[11, 6, 13],
    <int>[9, 14, 7],
    <int>[16, 8, 12],
    <int>[9, 6, 12, 8],
    <int>[14, 7, 10, 11],
    <int>[11, 8, 13, 6, 9],
    <int>[16, 11, 7, 13, 8],
    <int>[8, 13, 9, 6],
    <int>[12, 7, 15, 10],
    <int>[17, 11, 8, 13],
    <int>[13, 7, 16, 9, 12],
    <int>[19, 14, 8, 11, 15],
    <int>[16, 9, 17, 12, 8],
    <int>[14, 6, 11, 8, 13, 10],
    <int>[18, 11, 7, 14, 9, 16],
    <int>[16, 10, 13, 7, 12, 9],
    <int>[21, 13, 17, 9, 14, 11],
  ];

  final int level;
  final int chapter;
  final int stageInChapter;
  final int activeObjectCount;
  final List<MassObjectToken> objects;
  final List<MassEquation> equations;
  final int targetObjectIndex;
  final int answerGrams;
  final List<int> answerChoices;

  int get decoyCount => objects.length - activeObjectCount;
  int get difficultyStage => stageInChapter;

  String get difficultyTier => switch (stageInChapter) {
    <= 6 => chapter == 1 ? 'MASTERY' : 'ADVANCED',
    <= 8 => 'EXPERT',
    _ => 'EXPERT+',
  };

  String get boardSignature =>
      '${objects.map((MassObjectToken object) => object.signature).join('|')}'
      '#${equations.map((MassEquation equation) => equation.signature).join('|')}'
      '#$targetObjectIndex';

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static HiddenMassPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  /// Solves the overdetermined integer system. A null result means the clues
  /// are inconsistent or do not determine every active object uniquely.
  List<int>? solveUniqueMasses() {
    final int variables = activeObjectCount;
    final List<List<double>> matrix = equations
        .map((MassEquation equation) => equation.coefficientRow(variables))
        .toList(growable: false);
    int pivotRow = 0;
    final List<int> pivotForColumn = List<int>.filled(variables, -1);

    for (int column = 0; column < variables; column++) {
      int candidate = pivotRow;
      while (candidate < matrix.length &&
          matrix[candidate][column].abs() < 1e-9) {
        candidate++;
      }
      if (candidate == matrix.length) continue;
      final List<double> swap = matrix[pivotRow];
      matrix[pivotRow] = matrix[candidate];
      matrix[candidate] = swap;

      final double divisor = matrix[pivotRow][column];
      for (int cell = column; cell <= variables; cell++) {
        matrix[pivotRow][cell] /= divisor;
      }
      for (int row = 0; row < matrix.length; row++) {
        if (row == pivotRow) continue;
        final double factor = matrix[row][column];
        if (factor.abs() < 1e-9) continue;
        for (int cell = column; cell <= variables; cell++) {
          matrix[row][cell] -= matrix[pivotRow][cell] * factor;
        }
      }
      pivotForColumn[column] = pivotRow;
      pivotRow++;
      if (pivotRow == matrix.length) break;
    }

    for (final List<double> row in matrix) {
      final bool hasCoefficient = row
          .take(variables)
          .any((double value) => value.abs() >= 1e-8);
      if (!hasCoefficient && row[variables].abs() >= 1e-8) return null;
    }
    if (pivotForColumn.any((int row) => row < 0)) return null;

    final List<int> solution = List<int>.generate(variables, (int column) {
      final double value = matrix[pivotForColumn[column]][variables];
      return value.round();
    }, growable: false);
    if (equations.any(
      (MassEquation equation) => equation.evaluate(solution) != equation.grams,
    )) {
      return null;
    }
    return solution;
  }

  static HiddenMassPuzzle _generate(int level, {int variant = 0}) {
    final int stage = stageForLevel(level);
    final int chapter = ((level - 1) ~/ 10) + 1;
    final int activeCount = switch (chapter) {
      1 when stage <= 6 => 3,
      1 when stage <= 8 => 4,
      1 => 5,
      2 when stage <= 3 => 4,
      2 when stage <= 6 => 5,
      _ => 6,
    };
    final List<int> masses = _solutions[level - 1].map((value) => value + variant * 3).toList(growable: false);
    final bool hasDecoy = chapter == 2;
    final math.Random random = ContentSeed.randomFor(
      gameId: 'hidden_masses',
      level: level + variant * maximumLevels,
    );

    final List<MassObjectToken> objects = List<MassObjectToken>.generate(
      activeCount + (hasDecoy ? 1 : 0),
      (int index) => MassObjectToken(
        index: index,
        glyphIndex: (level * 3 + index * 5) % 9,
        isDecoy: index >= activeCount,
      ),
      growable: false,
    );

    final List<List<int>> terms = <List<int>>[
      <int>[0, 1],
      <int>[0, 2],
      <int>[1, 2],
      if (activeCount >= 4) <int>[2, 3],
      if (activeCount >= 5) <int>[3, 4],
      if (activeCount >= 6) <int>[4, 5],
      if (stage >= 9 && activeCount == 6) <int>[5, 5, 0],
    ];
    final List<MassEquation> equations = terms
        .map(
          (List<int> indices) => MassEquation(
            objectIndices: List<int>.unmodifiable(indices),
            grams: indices.fold<int>(
              0,
              (int total, int index) => total + masses[index],
            ),
          ),
        )
        .toList();
    equations.shuffle(random);

    final int targetIndex = activeCount == 3 ? level % 3 : activeCount - 1;
    final int answer = masses[targetIndex];
    final Set<int> choices = <int>{answer};
    for (int offset = 1; choices.length < 5; offset++) {
      final int high = answer + offset;
      final int low = answer - offset;
      choices.add(high);
      if (low > 0) choices.add(low);
    }
    final List<int> answerChoices = choices.toList()..shuffle(random);

    return HiddenMassPuzzle(
      level: level,
      chapter: chapter,
      stageInChapter: stage,
      activeObjectCount: activeCount,
      objects: List<MassObjectToken>.unmodifiable(objects),
      equations: List<MassEquation>.unmodifiable(equations),
      targetObjectIndex: targetIndex,
      answerGrams: answer,
      answerChoices: List<int>.unmodifiable(answerChoices),
    );
  }
}
