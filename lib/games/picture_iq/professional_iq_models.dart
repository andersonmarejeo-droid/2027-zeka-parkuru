enum ProfessionalIqFamily {
  colorPattern,
  shapeTransform,
  rotation,
  mirror,
  countRelation,
  sizePosition,
  analogy,
  visualSeries,
  oddOneOut,
  matrix2,
  matrix3,
  symmetry,
  overlay,
  xor,
  paperFold,
  mixedRules,
}

enum ProfessionalIqSkill {
  visualPattern,
  spatialReasoning,
  attention,
  transformation,
  logicalCombination,
  speed,
}

enum ProfessionalIqLayout {
  analogy,
  transform,
  series,
  matrix2,
  matrix3,
  relation,
  oddOneOut,
}

/// Visual grammar used by the renderer. Families no longer share one generic
/// card: the same compact data can be presented as geometry, a fold sheet,
/// layered panes, a balance/equation, or a spatial tile.
enum ProfessionalIqScene {
  symbols,
  arrows,
  matrix,
  mirror,
  layers,
  fold,
  balance,
  parts,
  spatialGrid,
}

class ProfessionalIqFigure {
  final int shape;
  final int color;
  final int rotation;
  final int count;
  final int size;
  final int pattern;
  final int position;
  final int dotMask;
  final bool mirrored;

  const ProfessionalIqFigure({
    required this.shape,
    required this.color,
    required this.rotation,
    required this.count,
    required this.size,
    required this.pattern,
    required this.position,
    this.dotMask = 0,
    this.mirrored = false,
  });

  bool get isDotPattern => dotMask != 0;

  /// Everything the player can actually distinguish in the renderer.
  /// Symmetric motifs normalize transformations that are not perceptible.
  bool get rotationMatters => !const <int>{0, 2, 8, 10}.contains(shape);
  bool get mirrorMatters => !const <int>{0, 1, 2, 3, 8, 10}.contains(shape);

  String get visibleSignature {
    if (isDotPattern) return 'dots:$color:${pattern.isEven}:$dotMask';
    final int visibleRotation = rotationMatters ? rotation : 0;
    final bool visibleMirror = mirrorMatters && mirrored;
    return '$shape:$color:$visibleRotation:$count:$size:$position:$visibleMirror';
  }

  String get signature =>
      '$shape:$color:$rotation:$count:$size:$pattern:$position:$dotMask:$mirrored';

  /// Cosmetic palette identity is deliberately omitted. A question that only
  /// swaps colors is not counted as fresh content. Invisible state must also
  /// be normalized here, otherwise two questions can look identical while
  /// receiving different fingerprints (for example a rotated circle/square).
  String get logicSignature {
    if (isDotPattern) return 'dots:${pattern.isEven}:$dotMask';
    final int logicalRotation = rotationMatters ? rotation : 0;
    final bool logicalMirror = mirrorMatters && mirrored;
    return '$shape:$logicalRotation:$count:$size:$position:$logicalMirror';
  }

  ProfessionalIqFigure copyWith({
    int? shape,
    int? color,
    int? rotation,
    int? count,
    int? size,
    int? pattern,
    int? position,
    int? dotMask,
    bool? mirrored,
  }) {
    return ProfessionalIqFigure(
      shape: shape ?? this.shape,
      color: color ?? this.color,
      rotation: rotation ?? this.rotation,
      count: count ?? this.count,
      size: size ?? this.size,
      pattern: pattern ?? this.pattern,
      position: position ?? this.position,
      dotMask: dotMask ?? this.dotMask,
      mirrored: mirrored ?? this.mirrored,
    );
  }
}

class ProfessionalIqQuestion {
  final ProfessionalIqFamily family;
  final ProfessionalIqSkill skill;
  final ProfessionalIqLayout layout;
  final List<ProfessionalIqFigure?> board;
  final List<ProfessionalIqFigure> options;
  final int correctIndex;
  final String promptKey;
  final String explanationKey;
  final String fingerprint;
  final double difficulty;
  final int operationCode;

  const ProfessionalIqQuestion({
    required this.family,
    required this.skill,
    required this.layout,
    required this.board,
    required this.options,
    required this.correctIndex,
    required this.promptKey,
    required this.explanationKey,
    required this.fingerprint,
    required this.difficulty,
    this.operationCode = 0,
  });

  ProfessionalIqFigure get answer => options[correctIndex];

  /// Decorative scene wrappers are used only when they do not hide or
  /// duplicate the rule-bearing information. In particular, overlay/XOR and
  /// symmetry must show the raw dot boards; drawing each operand twice makes
  /// the puzzle visually ambiguous. Mirror and mixed-rule questions likewise
  /// need the actual figure orientation to remain visible.
  ProfessionalIqScene get scene => switch (family) {
    ProfessionalIqFamily.rotation => ProfessionalIqScene.arrows,
    // Shape transformation is now a real A→B / C→? analogy. Keep the
    // original colours visible so the player can compare the silhouettes;
    // applying a dark silhouette filter to every tile hid the rule.
    ProfessionalIqFamily.shapeTransform => ProfessionalIqScene.symbols,
    ProfessionalIqFamily.sizePosition => ProfessionalIqScene.spatialGrid,
    ProfessionalIqFamily.matrix2 ||
    ProfessionalIqFamily.matrix3 ||
    ProfessionalIqFamily.mixedRules => ProfessionalIqScene.matrix,
    ProfessionalIqFamily.paperFold => ProfessionalIqScene.fold,
    ProfessionalIqFamily.countRelation => ProfessionalIqScene.balance,
    _ => ProfessionalIqScene.symbols,
  };

  int get boardColumns {
    return switch (layout) {
      ProfessionalIqLayout.analogy => 2,
      ProfessionalIqLayout.transform => 2,
      ProfessionalIqLayout.series => 4,
      ProfessionalIqLayout.matrix2 => 2,
      ProfessionalIqLayout.matrix3 => 3,
      ProfessionalIqLayout.relation => 3,
      ProfessionalIqLayout.oddOneOut => 1,
    };
  }
}

class ProfessionalIqAnswerRecord {
  final ProfessionalIqSkill skill;
  final bool correct;
  final int responseMillis;

  const ProfessionalIqAnswerRecord({
    required this.skill,
    required this.correct,
    required this.responseMillis,
  });
}

class ProfessionalIqSkillResult {
  final ProfessionalIqSkill skill;
  final int correct;
  final int total;
  final int averageMillis;
  final int performance;

  const ProfessionalIqSkillResult({
    required this.skill,
    required this.correct,
    required this.total,
    required this.averageMillis,
    required this.performance,
  });
}

class ProfessionalIqSessionProfile {
  final List<ProfessionalIqSkillResult> skills;

  const ProfessionalIqSessionProfile(this.skills);

  ProfessionalIqSkillResult? get strongest {
    final List<ProfessionalIqSkillResult> measured = skills
        .where((ProfessionalIqSkillResult item) => item.total > 0)
        .toList();
    if (measured.isEmpty) return null;
    measured.sort(
      (ProfessionalIqSkillResult a, ProfessionalIqSkillResult b) =>
          b.performance.compareTo(a.performance),
    );
    return measured.first;
  }

  ProfessionalIqSkillResult? get growthArea {
    final List<ProfessionalIqSkillResult> measured = skills
        .where((ProfessionalIqSkillResult item) => item.total > 0)
        .toList();
    if (measured.isEmpty) return null;
    measured.sort(
      (ProfessionalIqSkillResult a, ProfessionalIqSkillResult b) =>
          a.performance.compareTo(b.performance),
    );
    return measured.first;
  }
}

ProfessionalIqSessionProfile buildProfessionalIqProfile(
  Iterable<ProfessionalIqAnswerRecord> answers,
) {
  final List<ProfessionalIqAnswerRecord> records = answers.toList();
  final List<ProfessionalIqSkillResult> results = <ProfessionalIqSkillResult>[];

  for (final ProfessionalIqSkill skill in ProfessionalIqSkill.values) {
    if (skill == ProfessionalIqSkill.speed) continue;
    final List<ProfessionalIqAnswerRecord> measured = records
        .where((ProfessionalIqAnswerRecord item) => item.skill == skill)
        .toList();
    final int correct = measured
        .where((ProfessionalIqAnswerRecord item) => item.correct)
        .length;
    final int averageMillis = measured.isEmpty
        ? 0
        : measured
                  .map((ProfessionalIqAnswerRecord item) => item.responseMillis)
                  .reduce((int a, int b) => a + b) ~/
              measured.length;
    final int accuracy = measured.isEmpty
        ? 0
        : (correct * 100 / measured.length).round();
    final int pace = measured.isEmpty
        ? 0
        : (100 - ((averageMillis - 2500).clamp(0, 12500) * 100 ~/ 12500));
    results.add(
      ProfessionalIqSkillResult(
        skill: skill,
        correct: correct,
        total: measured.length,
        averageMillis: averageMillis,
        performance: measured.isEmpty
            ? 0
            : (accuracy * 0.78 + pace * 0.22).round(),
      ),
    );
  }

  final int overallAverage = records.isEmpty
      ? 0
      : records
                .map((ProfessionalIqAnswerRecord item) => item.responseMillis)
                .reduce((int a, int b) => a + b) ~/
            records.length;
  final int speedPerformance = records.isEmpty
      ? 0
      : (100 - ((overallAverage - 2000).clamp(0, 13000) * 100 ~/ 13000));
  results.add(
    ProfessionalIqSkillResult(
      skill: ProfessionalIqSkill.speed,
      correct: records
          .where((ProfessionalIqAnswerRecord item) => item.correct)
          .length,
      total: records.length,
      averageMillis: overallAverage,
      performance: speedPerformance,
    ),
  );

  return ProfessionalIqSessionProfile(results);
}
