import 'dart:math';

import '../../content_engine/content_fingerprint.dart';
import '../../content_engine/content_seed.dart';
import '../../content_engine/content_version.dart';
import '../../content_engine/recent_content_store.dart';
import 'professional_iq_models.dart';

/// Procedural, non-clinical visual reasoning content engine.
///
/// Sixteen families are combined with parameterized figures. Ten structural
/// templates per family and their visual parameters produce well over 12,000
/// equivalent question variants without treating palette-only swaps as new.
class ProfessionalIqEngine {
  static const String gameId = 'picture_iq_professional';
  static const int familyCount = 16;
  // Kept for V11.1 contract compatibility.
  static const int structuralTemplatesPerFamily = 10;
  static const int estimatedEquivalentVariants = 12000;
  // V11.2 visible-rule pool metadata.
  static const int validatedTemplatesPerFamily = 36;
  static const int validatedEquivalentVariants = 90000;
  static const int historyLimit = 250;
  static const int motifCount = 20;

  final RecentContentStore? _providedHistory;
  RecentContentStore? _createdHistory;

  ProfessionalIqEngine({RecentContentStore? history})
    : _providedHistory = history;

  RecentContentStore get _history =>
      _providedHistory ?? (_createdHistory ??= RecentContentStore());

  static List<ProfessionalIqFamily> familiesForLevel(int level) {
    final int safeLevel = level.clamp(1, 10).toInt();
    const List<List<ProfessionalIqFamily>> additions =
        <List<ProfessionalIqFamily>>[
          <ProfessionalIqFamily>[
            ProfessionalIqFamily.analogy,
            ProfessionalIqFamily.oddOneOut,
            ProfessionalIqFamily.rotation,
            ProfessionalIqFamily.mirror,
          ],
          <ProfessionalIqFamily>[
            ProfessionalIqFamily.matrix2,
            ProfessionalIqFamily.symmetry,
            ProfessionalIqFamily.countRelation,
          ],
          <ProfessionalIqFamily>[
            ProfessionalIqFamily.sizePosition,
            ProfessionalIqFamily.shapeTransform,
            ProfessionalIqFamily.overlay,
          ],
          <ProfessionalIqFamily>[
            ProfessionalIqFamily.colorPattern,
            ProfessionalIqFamily.paperFold,
          ],
          <ProfessionalIqFamily>[
            ProfessionalIqFamily.visualSeries,
            ProfessionalIqFamily.xor,
          ],
          <ProfessionalIqFamily>[ProfessionalIqFamily.matrix3],
          <ProfessionalIqFamily>[ProfessionalIqFamily.mixedRules],
          <ProfessionalIqFamily>[],
          <ProfessionalIqFamily>[],
          <ProfessionalIqFamily>[],
        ];

    return <ProfessionalIqFamily>[
      for (int index = 0; index < safeLevel; index++) ...additions[index],
    ];
  }

  Future<List<ProfessionalIqQuestion>> compose({
    required int level,
    required int count,
    required int sessionSeed,
    required bool fixedSession,
  }) async {
    final int safeLevel = level.clamp(1, 10).toInt();
    final Random random = ContentSeed.random(
      sessionSeed: sessionSeed,
      level: safeLevel,
      salt: 1111,
    );
    final Set<String> recent = fixedSession
        ? <String>{}
        : await _history.recentItems(gameId: gameId, level: safeLevel);
    final List<ProfessionalIqFamily> schedule = _familySchedule(
      random: random,
      level: safeLevel,
      count: count,
    );
    final List<ProfessionalIqQuestion> questions = <ProfessionalIqQuestion>[];
    final Set<String> current = <String>{};

    for (int index = 0; index < count; index++) {
      ProfessionalIqQuestion? selected;
      for (int attempt = 0; attempt < 120; attempt++) {
        final ProfessionalIqQuestion candidate = _buildQuestion(
          schedule[index],
          safeLevel,
          random,
          index + attempt * 31,
        );
        if (!_isStructurallyValid(candidate)) continue;
        selected = candidate;
        if (!current.contains(candidate.fingerprint) &&
            !recent.contains(candidate.fingerprint)) {
          break;
        }
      }
      questions.add(selected!);
      current.add(selected.fingerprint);
    }

    if (!fixedSession) {
      const ContentHistoryPolicy policy = ContentHistoryPolicy(
        itemLimit: historyLimit,
        sessionLimit: 60,
      );
      await _history.rememberItems(
        gameId: gameId,
        level: safeLevel,
        fingerprints: questions.map(
          (ProfessionalIqQuestion item) => item.fingerprint,
        ),
        policy: policy,
      );
      await _history.rememberSession(
        gameId: gameId,
        level: safeLevel,
        fingerprint: contentFingerprint(
          questions.map((ProfessionalIqQuestion item) => item.fingerprint),
        ),
        policy: policy,
      );
    }

    return questions;
  }

  List<ProfessionalIqFamily> _familySchedule({
    required Random random,
    required int level,
    required int count,
  }) {
    final List<ProfessionalIqFamily> allowed = familiesForLevel(level);
    final List<ProfessionalIqFamily> result = <ProfessionalIqFamily>[];
    final Map<ProfessionalIqFamily, int> used = <ProfessionalIqFamily, int>{};
    final int seriesMaximum = max(1, (count * .25).ceil());
    int seriesCount = 0;

    while (result.length < count) {
      final List<ProfessionalIqFamily> candidates = List<ProfessionalIqFamily>.of(
        allowed,
      )..shuffle(random);
      final int leastUsed = candidates
          .map((ProfessionalIqFamily item) => used[item] ?? 0)
          .reduce(min);

      ProfessionalIqFamily? selected;
      for (final ProfessionalIqFamily family in candidates) {
        if ((used[family] ?? 0) > leastUsed + 1) continue;
        if (result.isNotEmpty && result.last == family) continue;
        if (_isSeriesFamily(family) && seriesCount >= seriesMaximum) continue;
        if (result.isNotEmpty &&
            _presentationBucket(result.last) == _presentationBucket(family)) {
          final bool differentBucketExists = candidates.any(
            (ProfessionalIqFamily item) =>
                item != result.last &&
                (!_isSeriesFamily(item) || seriesCount < seriesMaximum) &&
                _presentationBucket(item) != _presentationBucket(result.last),
          );
          if (differentBucketExists) continue;
        }
        selected = family;
        break;
      }

      selected ??= candidates.firstWhere(
        (ProfessionalIqFamily family) =>
            result.isEmpty || result.last != family,
        orElse: () => candidates.first,
      );
      final ProfessionalIqFamily choice = selected;
      result.add(choice);
      used[choice] = (used[choice] ?? 0) + 1;
      if (_isSeriesFamily(choice)) seriesCount++;
    }
    return result;
  }

  bool _isSeriesFamily(ProfessionalIqFamily family) =>
      family == ProfessionalIqFamily.colorPattern ||
      family == ProfessionalIqFamily.countRelation ||
      family == ProfessionalIqFamily.sizePosition ||
      family == ProfessionalIqFamily.visualSeries;

  int _presentationBucket(ProfessionalIqFamily family) {
    if (_isSeriesFamily(family)) return 0;
    if (family == ProfessionalIqFamily.matrix2 ||
        family == ProfessionalIqFamily.matrix3 ||
        family == ProfessionalIqFamily.mixedRules) {
      return 1;
    }
    if (family == ProfessionalIqFamily.symmetry ||
        family == ProfessionalIqFamily.overlay ||
        family == ProfessionalIqFamily.xor ||
        family == ProfessionalIqFamily.paperFold) {
      return 2;
    }
    return 3;
  }

  ProfessionalIqQuestion _buildQuestion(
    ProfessionalIqFamily family,
    int level,
    Random random,
    int variant,
  ) {
    return switch (family) {
      ProfessionalIqFamily.colorPattern => _seriesQuestion(
        family,
        level,
        random,
        variant,
        _Transform.colorPattern,
      ),
      ProfessionalIqFamily.shapeTransform => _shapeMatchQuestion(
        level,
        random,
        variant,
      ),
      ProfessionalIqFamily.rotation => _rotationQuestion(
        level,
        random,
        variant,
      ),
      ProfessionalIqFamily.mirror => _mirrorQuestion(
        level,
        random,
        variant,
      ),
      ProfessionalIqFamily.countRelation => _seriesQuestion(
        family,
        level,
        random,
        variant,
        _Transform.count,
      ),
      ProfessionalIqFamily.sizePosition => _seriesQuestion(
        family,
        level,
        random,
        variant,
        _Transform.sizePosition,
      ),
      ProfessionalIqFamily.analogy => _analogyQuestion(
        family,
        level,
        random,
        variant,
        _Transform.shapeRotation,
      ),
      ProfessionalIqFamily.visualSeries => _seriesQuestion(
        family,
        level,
        random,
        variant,
        _Transform.patternRotation,
      ),
      ProfessionalIqFamily.oddOneOut => _oddOneOutQuestion(
        level,
        random,
        variant,
      ),
      ProfessionalIqFamily.matrix2 => _matrix2Question(
        family,
        level,
        random,
        variant,
        mixed: false,
      ),
      ProfessionalIqFamily.matrix3 => _matrix3Question(level, random, variant),
      ProfessionalIqFamily.symmetry => _dotQuestion(
        family,
        level,
        random,
        variant,
      ),
      ProfessionalIqFamily.overlay => _dotQuestion(
        family,
        level,
        random,
        variant,
      ),
      ProfessionalIqFamily.xor => _dotQuestion(family, level, random, variant),
      ProfessionalIqFamily.paperFold => _dotQuestion(
        family,
        level,
        random,
        variant,
      ),
      ProfessionalIqFamily.mixedRules => _matrix2Question(
        family,
        level,
        random,
        variant,
        mixed: true,
      ),
    };
  }

  ProfessionalIqQuestion _shapeMatchQuestion(
    int level,
    Random random,
    int variant,
  ) {
    final ProfessionalIqFigure target = _randomFigure(random).copyWith(
      shape: _motifForVariant(variant + 2),
      color: variant % 5,
      rotation: 0,
      count: 1,
      size: 1,
      position: 4,
      pattern: 0,
      mirrored: false,
    );
    // The option uses the same outline but a neutral palette. Color is not a
    // clue; the player must match the contour/silhouette itself.
    final ProfessionalIqFigure answer = target.copyWith(
      color: (target.color + 2) % 5,
    );
    return _withOptions(
      family: ProfessionalIqFamily.shapeTransform,
      skill: ProfessionalIqSkill.transformation,
      layout: ProfessionalIqLayout.transform,
      board: <ProfessionalIqFigure?>[target, null],
      answer: answer,
      level: level,
      random: random,
      variant: variant,
      operationCode: 20,
    );
  }

  ProfessionalIqQuestion _rotationQuestion(
    int level,
    Random random,
    int variant,
  ) {
    final int step = switch (variant % 3) { 0 => 1, 1 => 2, _ => 3 };
    final ProfessionalIqFigure first = _randomFigure(random).copyWith(
      shape: _rotationMotifForVariant(variant),
      color: variant % 5,
      rotation: (variant + 1) % 4,
      count: 1,
      size: 1,
      position: 4,
      pattern: 0,
      mirrored: false,
    );
    final ProfessionalIqFigure answer = first.copyWith(
      rotation: (first.rotation + step) % 4,
    );
    return _withOptions(
      family: ProfessionalIqFamily.rotation,
      skill: ProfessionalIqSkill.spatialReasoning,
      layout: ProfessionalIqLayout.transform,
      board: <ProfessionalIqFigure?>[first, null],
      answer: answer,
      level: level,
      random: random,
      variant: variant,
      operationCode: step,
    );
  }

  ProfessionalIqQuestion _mirrorQuestion(
    int level,
    Random random,
    int variant,
  ) {
    final ProfessionalIqFigure first = _randomFigure(random).copyWith(
      shape: _mirrorMotifForVariant(variant),
      color: (variant + 2) % 5,
      rotation: variant % 4,
      count: 1,
      size: 1,
      position: 4,
      pattern: 0,
      mirrored: false,
    );
    final ProfessionalIqFigure answer = first.copyWith(mirrored: true);
    return _withOptions(
      family: ProfessionalIqFamily.mirror,
      skill: ProfessionalIqSkill.spatialReasoning,
      layout: ProfessionalIqLayout.transform,
      board: <ProfessionalIqFigure?>[first, null],
      answer: answer,
      level: level,
      random: random,
      variant: variant,
      operationCode: 10,
    );
  }

  ProfessionalIqQuestion _seriesQuestion(
    ProfessionalIqFamily family,
    int level,
    Random random,
    int variant,
    _Transform transform,
  ) {
    ProfessionalIqFigure first = _randomFigure(random).copyWith(
      shape: _motifForVariant(variant),
      position: 4,
      pattern: 0,
    );
    late ProfessionalIqFigure second;
    late ProfessionalIqFigure third;
    late ProfessionalIqFigure answer;

    switch (transform) {
      case _Transform.shape:
        first = first.copyWith(rotation: 0, size: 1, count: 1);
        final int otherShape = (first.shape + 1 + (variant % 5)) % motifCount;
        if (variant % 3 == 0) {
          // A-B-A-B
          second = first.copyWith(shape: otherShape);
          third = first;
          answer = second;
        } else {
          // A-A-B-B: still visually obvious, but not the same repeated template.
          second = first;
          third = first.copyWith(shape: otherShape);
          answer = third;
        }

      case _Transform.colorPattern:
        first = first.copyWith(rotation: 0, size: 1, count: 1);
        final int otherColor = (first.color + 1 + variant % 4) % 5;
        if (variant.isEven) {
          // A-B-A-B: no hidden ordering between arbitrary colors is assumed.
          second = first.copyWith(color: otherColor);
          third = first;
          answer = second;
        } else {
          // A-A-B-B: a second, equally explicit repetition template.
          second = first;
          third = first.copyWith(color: otherColor);
          answer = third;
        }

      case _Transform.count:
        final List<List<int>> cycles = <List<int>>[
          <int>[1, 2, 3, 1],
          <int>[3, 2, 1, 3],
          <int>[1, 3, 2, 1],
          <int>[2, 1, 3, 2],
        ];
        final List<int> cycle = cycles[variant % cycles.length];
        first = first.copyWith(count: cycle[0], size: 1, rotation: 0);
        second = first.copyWith(count: cycle[1]);
        third = first.copyWith(count: cycle[2]);
        answer = first.copyWith(count: cycle[3]);

      case _Transform.sizePosition:
        const List<List<int>> paths = <List<int>>[
          <int>[0, 1, 2, 5],
          <int>[8, 7, 6, 3],
          <int>[6, 3, 0, 1],
          <int>[2, 5, 8, 7],
          <int>[0, 3, 6, 7],
          <int>[8, 5, 2, 1],
        ];
        final List<int> path = paths[variant % paths.length];
        final bool startsLarge = variant.isOdd;
        first = first.copyWith(
          position: path[0],
          size: startsLarge ? 1 : 0,
          count: 1,
          rotation: 0,
        );
        second = first.copyWith(position: path[1], size: 1 - first.size);
        third = first.copyWith(position: path[2], size: first.size);
        answer = first.copyWith(position: path[3], size: 1 - first.size);

      case _Transform.patternRotation:
        first = first.copyWith(count: 1, size: 1, rotation: 0);
        final int secondShape = (first.shape + 1 + variant % 5) % motifCount;
        final ProfessionalIqFigure stateB = first.copyWith(
          shape: secondShape,
          color: (first.color + 2) % 5,
          count: variant % 3 == 0 ? 2 : 3,
        );
        if (variant.isEven) {
          // Multi-feature A-B-A-B.
          second = stateB;
          third = first;
          answer = stateB;
        } else {
          // Multi-feature A-A-B-B.
          second = first;
          third = stateB;
          answer = stateB;
        }

      case _Transform.rotation:
        first = first.copyWith(
          shape: _rotationMotifForVariant(variant),
          position: 4,
          count: 1,
          size: 1,
          rotation: variant % 4,
          mirrored: false,
        );
        final int step = switch (variant % 3) { 0 => 1, 1 => 3, _ => 2 };
        second = first.copyWith(rotation: (first.rotation + step) % 4);
        third = first.copyWith(rotation: (first.rotation + step * 2) % 4);
        answer = first.copyWith(rotation: (first.rotation + step * 3) % 4);

      case _Transform.mirror || _Transform.shapeRotation:
        second = _transform(first, transform, variant);
        third = _transform(second, transform, variant);
        answer = _transform(third, transform, variant);
    }

    return _withOptions(
      family: family,
      skill: _skillFor(family),
      layout: ProfessionalIqLayout.series,
      board: <ProfessionalIqFigure?>[first, second, third, null],
      answer: answer,
      level: level,
      random: random,
      variant: variant,
    );
  }

  ProfessionalIqQuestion _analogyQuestion(
    ProfessionalIqFamily family,
    int level,
    Random random,
    int variant,
    _Transform transform,
  ) {
    final int firstMotif = transform == _Transform.mirror
        ? _mirrorMotifForVariant(variant)
        : _motifForVariant(variant);
    final ProfessionalIqFigure first = _randomFigure(random).copyWith(
      position: 4,
      shape: firstMotif,
      rotation: transform == _Transform.mirror ? variant % 4 : 0,
      mirrored: false,
      count: transform == _Transform.shapeRotation ? 1 : null,
      size: transform == _Transform.shapeRotation ? 0 : null,
      pattern: 0,
    );
    final ProfessionalIqFigure second = _transform(first, transform, variant);
    final ProfessionalIqFigure third = _randomFigure(random).copyWith(
      position: 4,
      shape: transform == _Transform.mirror
          ? _mirrorMotifForVariant(variant + 5)
          : _motifForVariant(variant + 5),
      rotation: transform == _Transform.mirror ? (variant + 1) % 4 : 0,
      mirrored: false,
      count: transform == _Transform.shapeRotation ? 1 : null,
      size: transform == _Transform.shapeRotation ? 0 : null,
      pattern: 0,
    );
    final ProfessionalIqFigure answer = _transform(third, transform, variant);
    return _withOptions(
      family: family,
      skill: _skillFor(family),
      layout: ProfessionalIqLayout.analogy,
      board: <ProfessionalIqFigure?>[first, second, third, null],
      answer: answer,
      level: level,
      random: random,
      variant: variant,
    );
  }

  ProfessionalIqQuestion _oddOneOutQuestion(
    int level,
    Random random,
    int variant,
  ) {
    final int mode = variant % 4;
    final int motif = _motifForVariant(variant + 3);
    ProfessionalIqFigure base = _randomFigure(random).copyWith(
      shape: motif,
      position: 4,
      pattern: 0,
      count: 1,
      size: 1,
      mirrored: false,
    );
    final List<ProfessionalIqFigure> options = <ProfessionalIqFigure>[];
    late ProfessionalIqFigure answer;

    switch (mode) {
      case 0:
        // Three share one color. Every option uses a different direction, so
        // there is no second 3+1 rule hidden in the artwork.
        base = base.copyWith(shape: _rotationMotifForVariant(variant), color: random.nextInt(5));
        for (int index = 0; index < 3; index++) {
          options.add(base.copyWith(rotation: index));
        }
        answer = base.copyWith(
          rotation: 3,
          color: (base.color + 2) % 5,
        );
      case 1:
        // Three contain one motif, the outlier contains two. Colors are all
        // different, so count is the only 3+1 classification.
        for (int index = 0; index < 3; index++) {
          options.add(base.copyWith(color: (base.color + index) % 5));
        }
        answer = base.copyWith(
          color: (base.color + 3) % 5,
          count: 2,
        );
      case 2:
        // Three are large and one is small; every color is unique.
        base = base.copyWith(size: 1);
        for (int index = 0; index < 3; index++) {
          options.add(base.copyWith(color: (base.color + index) % 5));
        }
        answer = base.copyWith(
          color: (base.color + 3) % 5,
          size: 0,
        );
      default:
        // Three point the same way and one points the opposite way. Using the
        // leaf motif makes direction unmistakable without relying on arrows.
        base = base.copyWith(shape: _rotationMotifForVariant(variant + 2), rotation: 1);
        for (int index = 0; index < 3; index++) {
          options.add(base.copyWith(color: (base.color + index) % 5));
        }
        answer = base.copyWith(
          color: (base.color + 3) % 5,
          rotation: 3,
        );
    }

    options.add(answer);
    options.shuffle(random);
    return _question(
      family: ProfessionalIqFamily.oddOneOut,
      skill: ProfessionalIqSkill.attention,
      layout: ProfessionalIqLayout.oddOneOut,
      board: const <ProfessionalIqFigure?>[],
      options: options,
      correctIndex: options.indexOf(answer),
      answer: answer,
      level: level,
      variant: variant,
    );
  }

  ProfessionalIqQuestion _matrix2Question(
    ProfessionalIqFamily family,
    int level,
    Random random,
    int variant, {
    required bool mixed,
  }) {
    ProfessionalIqFigure topLeft = _randomFigure(random).copyWith(
      shape: _motifForVariant(variant + 7),
      position: 4,
      pattern: 0,
      count: 1,
      size: 1,
    );
    late ProfessionalIqFigure topRight;
    late ProfessionalIqFigure bottomLeft;
    late ProfessionalIqFigure answer;

    final int mode = variant % 4;
    if (mixed) {
      topLeft = topLeft.copyWith(shape: _rotationMotifForVariant(variant + 9), rotation: 0);
      switch (mode) {
        case 0:
          topRight = topLeft.copyWith(rotation: 1);
          bottomLeft = topLeft.copyWith(count: 2);
          answer = bottomLeft.copyWith(rotation: 1);
        case 1:
          topRight = topLeft.copyWith(rotation: 3, color: (topLeft.color + 1) % 5);
          bottomLeft = topLeft.copyWith(size: 0, count: 3);
          answer = bottomLeft.copyWith(rotation: 3, color: topRight.color);
        case 2:
          topRight = topLeft.copyWith(count: 2, color: (topLeft.color + 2) % 5);
          bottomLeft = topLeft.copyWith(rotation: 2);
          answer = bottomLeft.copyWith(count: 2, color: topRight.color);
        default:
          topRight = topLeft.copyWith(size: 0, rotation: 1);
          bottomLeft = topLeft.copyWith(count: 3, color: (topLeft.color + 1) % 5);
          answer = bottomLeft.copyWith(size: 0, rotation: 1);
      }
    } else {
      topLeft = topLeft.copyWith(rotation: 0);
      switch (mode) {
        case 0:
          topRight = topLeft.copyWith(color: (topLeft.color + 2) % 5);
          bottomLeft = topLeft.copyWith(count: 3);
          answer = bottomLeft.copyWith(color: topRight.color);
        case 1:
          topRight = topLeft.copyWith(count: 2);
          bottomLeft = topLeft.copyWith(size: 0);
          answer = bottomLeft.copyWith(count: 2);
        case 2:
          topLeft = topLeft.copyWith(shape: _rotationMotifForVariant(variant + 9), rotation: 0);
          topRight = topLeft.copyWith(rotation: 1);
          bottomLeft = topLeft.copyWith(color: (topLeft.color + 2) % 5);
          answer = bottomLeft.copyWith(rotation: 1);
        default:
          topRight = topLeft.copyWith(size: 0, color: (topLeft.color + 1) % 5);
          bottomLeft = topLeft.copyWith(count: 2);
          answer = bottomLeft.copyWith(size: 0, color: topRight.color);
      }
    }

    return _withOptions(
      family: family,
      skill: mixed
          ? ProfessionalIqSkill.logicalCombination
          : ProfessionalIqSkill.visualPattern,
      layout: ProfessionalIqLayout.matrix2,
      board: <ProfessionalIqFigure?>[topLeft, topRight, bottomLeft, null],
      answer: answer,
      level: level,
      random: random,
      variant: variant,
    );
  }

  ProfessionalIqQuestion _matrix3Question(
    int level,
    Random random,
    int variant,
  ) {
    final int mode = variant % 4;
    final int baseColor = random.nextInt(5);
    final int baseShape = _motifForVariant(variant + 11);

    ProfessionalIqFigure at(int row, int column) {
      switch (mode) {
        case 0:
          // Rows own the shape; columns own the count.
          return ProfessionalIqFigure(
            shape: (baseShape + row) % motifCount,
            color: baseColor,
            rotation: 0,
            count: column + 1,
            size: 1,
            pattern: 0,
            position: 4,
          );
        case 1:
          // Rows own the color; columns own the size/count pair.
          return ProfessionalIqFigure(
            shape: baseShape,
            color: (baseColor + row) % 5,
            rotation: 0,
            count: column == 1 ? 2 : 1,
            size: column == 2 ? 0 : 1,
            pattern: 0,
            position: 4,
          );
        case 2:
          // Arrow direction progresses across columns and count across rows.
          return ProfessionalIqFigure(
            shape: _rotationMotifForVariant(variant + 13),
            color: baseColor,
            rotation: (column + row) % 4,
            count: row + 1,
            size: 1,
            pattern: 0,
            position: 4,
          );
        default:
          // Columns own the shape, rows own the color, and size alternates
          // as a checkerboard. This provides a fourth genuinely different
          // matrix grammar instead of a palette-only variation.
          return ProfessionalIqFigure(
            shape: (baseShape + column) % motifCount,
            color: (baseColor + row) % 5,
            rotation: 0,
            count: 1,
            size: (row + column).isEven ? 1 : 0,
            pattern: 0,
            position: 4,
          );
      }
    }

    final List<ProfessionalIqFigure?> board = <ProfessionalIqFigure?>[
      for (int row = 0; row < 3; row++)
        for (int column = 0; column < 3; column++)
          row == 2 && column == 2 ? null : at(row, column),
    ];
    return _withOptions(
      family: ProfessionalIqFamily.matrix3,
      skill: ProfessionalIqSkill.logicalCombination,
      layout: ProfessionalIqLayout.matrix3,
      board: board,
      answer: at(2, 2),
      level: level,
      random: random,
      variant: variant,
    );
  }

  ProfessionalIqQuestion _dotQuestion(
    ProfessionalIqFamily family,
    int level,
    Random random,
    int variant,
  ) {
    int firstMask = _randomMask(random);
    int secondMask = _randomMask(random);
    int answerMask;
    switch (family) {
      case ProfessionalIqFamily.symmetry:
        firstMask = _leftHalf(firstMask);
        secondMask = _mirrorMask(firstMask);
        answerMask = firstMask | secondMask;
        break;
      case ProfessionalIqFamily.overlay:
        answerMask = firstMask | secondMask;
        break;
      case ProfessionalIqFamily.xor:
        answerMask = firstMask ^ secondMask;
        if (answerMask == 0) {
          secondMask ^= 1 << ((variant + 2) % 9);
          answerMask = firstMask ^ secondMask;
        }
        break;
      case ProfessionalIqFamily.paperFold:
        firstMask = _topHalf(firstMask);
        secondMask = _mirrorVerticalMask(firstMask);
        answerMask = firstMask | secondMask;
        break;
      default:
        throw StateError('Unsupported dot family: $family');
    }
    if (answerMask == 0) answerMask = 1 << (variant % 9);

    final ProfessionalIqFigure first = _dotFigure(firstMask, variant);
    final ProfessionalIqFigure second = _dotFigure(secondMask, variant + 1);
    final ProfessionalIqFigure answer = _dotFigure(answerMask, variant + 2);
    return _withOptions(
      family: family,
      skill: _skillFor(family),
      layout: ProfessionalIqLayout.relation,
      board: <ProfessionalIqFigure?>[first, second, null],
      answer: answer,
      level: level,
      random: random,
      variant: variant,
      dotOptions: true,
    );
  }

  ProfessionalIqQuestion _withOptions({
    required ProfessionalIqFamily family,
    required ProfessionalIqSkill skill,
    required ProfessionalIqLayout layout,
    required List<ProfessionalIqFigure?> board,
    required ProfessionalIqFigure answer,
    required int level,
    required Random random,
    required int variant,
    bool dotOptions = false,
    int operationCode = 0,
  }) {
    final List<ProfessionalIqFigure> options = <ProfessionalIqFigure>[answer];
    final Set<String> semanticSignatures = <String>{
      _semanticOptionSignature(family, answer),
    };
    final Set<String> visibleSignatures = <String>{answer.visibleSignature};

    final List<ProfessionalIqFigure> candidates = <ProfessionalIqFigure>[];
    if (dotOptions) {
      for (int shift = 1; shift <= 24; shift++) {
        candidates.add(
          answer.copyWith(dotMask: _safeToggle(answer.dotMask, shift + variant)),
        );
      }
    } else {
      switch (family) {
        case ProfessionalIqFamily.countRelation:
          for (int count = 1; count <= 4; count++) {
            candidates.add(answer.copyWith(count: count, position: 4));
          }
        case ProfessionalIqFamily.rotation:
          for (int rotation = 0; rotation < 4; rotation++) {
            candidates.add(
              answer.copyWith(
                rotation: rotation,
                mirrored: false,
                position: 4,
                count: 1,
              ),
            );
          }
        case ProfessionalIqFamily.mirror:
          // One centered transformation per orientation. We never create two
          // choices that only differ by a barely visible free-floating offset.
          for (int rotation = 0; rotation < 4; rotation++) {
            if (rotation == answer.rotation) continue;
            candidates.add(
              answer.copyWith(
                rotation: rotation,
                mirrored: rotation.isEven
                    ? answer.mirrored
                    : !answer.mirrored,
                position: 4,
              ),
            );
          }
        case ProfessionalIqFamily.colorPattern:
          for (int color = 0; color < 5; color++) {
            candidates.add(answer.copyWith(color: color, position: 4));
          }
        case ProfessionalIqFamily.shapeTransform:
          for (int delta = 1; delta <= 8; delta++) {
            candidates.add(
              answer.copyWith(
                shape: (answer.shape + delta) % motifCount,
                rotation: 0,
                position: 4,
              ),
            );
          }
        case ProfessionalIqFamily.sizePosition:
          for (int position = 0; position < 9; position++) {
            for (int size = 0; size < 2; size++) {
              candidates.add(
                answer.copyWith(
                  position: position,
                  size: size,
                  count: 1,
                  rotation: 0,
                ),
              );
            }
          }
        case ProfessionalIqFamily.analogy:
          // The analogy rule changes count + size. Distractors are the three
          // plausible one-rule mistakes, not unrelated icons/colors.
          candidates.addAll(<ProfessionalIqFigure>[
            answer.copyWith(count: answer.count == 2 ? 1 : 2, position: 4),
            answer.copyWith(size: 1 - answer.size, position: 4),
            answer.copyWith(
              count: answer.count == 2 ? 1 : 2,
              size: 1 - answer.size,
              position: 4,
            ),
            answer.copyWith(rotation: (answer.rotation + 1) % 4, position: 4),
          ]);
        case ProfessionalIqFamily.visualSeries:
          for (int delta = 1; delta <= 5; delta++) {
            candidates.addAll(<ProfessionalIqFigure>[
              answer.copyWith(
                shape: (answer.shape + delta) % motifCount,
                position: 4,
              ),
              answer.copyWith(
                color: (answer.color + delta) % 5,
                position: 4,
              ),
              answer.copyWith(
                count: ((answer.count - 1 + delta) % 3) + 1,
                position: 4,
              ),
              answer.copyWith(
                shape: (answer.shape + delta) % motifCount,
                color: (answer.color + delta) % 5,
                position: 4,
              ),
            ]);
          }
        case ProfessionalIqFamily.matrix2 ||
        ProfessionalIqFamily.matrix3 ||
        ProfessionalIqFamily.mixedRules:
          // Matrix distractors never use free-floating card position. This is
          // the exact class of bug that previously created two almost equal
          // answers where only their hidden/irrelevant placement differed.
          for (int delta = 1; delta <= 5; delta++) {
            candidates.addAll(<ProfessionalIqFigure>[
              answer.copyWith(
                shape: (answer.shape + delta) % motifCount,
                position: 4,
              ),
              answer.copyWith(
                color: (answer.color + delta) % 5,
                position: 4,
              ),
              answer.copyWith(
                count: ((answer.count - 1 + delta) % 3) + 1,
                position: 4,
              ),
              if (answer.rotationMatters)
                answer.copyWith(
                  rotation: (answer.rotation + delta) % 4,
                  position: 4,
                ),
              answer.copyWith(
                size: 1 - answer.size,
                position: 4,
              ),
              answer.copyWith(
                color: (answer.color + delta) % 5,
                count: ((answer.count - 1 + delta) % 3) + 1,
                position: 4,
              ),
              answer.copyWith(
                shape: (answer.shape + delta) % motifCount,
                color: (answer.color + delta + 1) % 5,
                position: 4,
              ),
            ]);
          }
        case ProfessionalIqFamily.oddOneOut:
          // Odd-one-out owns its four choices and never reaches this helper.
          break;
        case ProfessionalIqFamily.symmetry ||
        ProfessionalIqFamily.overlay ||
        ProfessionalIqFamily.xor ||
        ProfessionalIqFamily.paperFold:
          break;
      }
    }

    // Preserve the meaningful ordering above. Shuffling the candidate pool
    // used to let a tiny position/size mutation win before clearer choices.
    for (final ProfessionalIqFigure candidate in candidates) {
      if (options.length >= 4) break;
      final String semantic = _semanticOptionSignature(family, candidate);
      final String visible = candidate.visibleSignature;
      if (!semanticSignatures.contains(semantic) &&
          !visibleSignatures.contains(visible)) {
        semanticSignatures.add(semantic);
        visibleSignatures.add(visible);
        options.add(candidate);
      }
    }

    if (options.length != 4) {
      throw StateError(
        'Four clear and semantically unique IQ options could not be generated for ${family.name}.',
      );
    }

    options.shuffle(random);
    return _question(
      family: family,
      skill: skill,
      layout: layout,
      board: board,
      options: options,
      correctIndex: options.indexOf(answer),
      answer: answer,
      level: level,
      variant: variant,
      operationCode: operationCode,
    );
  }

  String _semanticOptionSignature(
    ProfessionalIqFamily family,
    ProfessionalIqFigure figure,
  ) {
    if (figure.isDotPattern) return 'dots:${figure.dotMask}';
    final int rotation = figure.rotationMatters ? figure.rotation : 0;
    final bool mirror = figure.mirrorMatters && figure.mirrored;

    return switch (family) {
      ProfessionalIqFamily.colorPattern => 'color:${figure.color}',
      ProfessionalIqFamily.shapeTransform => 'shape:${figure.shape}',
      ProfessionalIqFamily.rotation => 'rotation:$rotation',
      ProfessionalIqFamily.mirror =>
        'mirror:$rotation:$mirror',
      ProfessionalIqFamily.countRelation => 'count:${figure.count}',
      ProfessionalIqFamily.sizePosition =>
        'sizePosition:${figure.size}:${figure.position}',
      ProfessionalIqFamily.analogy =>
        'analogy:${figure.shape}:$rotation:${figure.count}:${figure.size}:$mirror',
      ProfessionalIqFamily.visualSeries =>
        'series:${figure.shape}:${figure.color}:$rotation:${figure.count}:${figure.size}',
      ProfessionalIqFamily.matrix2 ||
      ProfessionalIqFamily.matrix3 ||
      ProfessionalIqFamily.mixedRules =>
        'matrix:${figure.shape}:${figure.color}:$rotation:${figure.count}:${figure.size}:$mirror',
      ProfessionalIqFamily.symmetry ||
      ProfessionalIqFamily.overlay ||
      ProfessionalIqFamily.xor ||
      ProfessionalIqFamily.paperFold => 'dots:${figure.dotMask}',
      ProfessionalIqFamily.oddOneOut => figure.visibleSignature,
    };
  }

  bool _isStructurallyValid(ProfessionalIqQuestion question) {
    if (question.options.length != 4 ||
        question.correctIndex < 0 ||
        question.correctIndex >= question.options.length) {
      return false;
    }
    if (question.options
            .map(
              (ProfessionalIqFigure item) =>
                  _semanticOptionSignature(question.family, item),
            )
            .toSet()
            .length !=
        4) {
      return false;
    }
    if (question.options
            .map((ProfessionalIqFigure item) => item.visibleSignature)
            .toSet()
            .length !=
        4) {
      return false;
    }
    if (question.layout == ProfessionalIqLayout.oddOneOut) {
      return question.board.isEmpty;
    }
    return question.board
            .where((ProfessionalIqFigure? item) => item == null)
            .length ==
        1;
  }

  ProfessionalIqQuestion _question({
    required ProfessionalIqFamily family,
    required ProfessionalIqSkill skill,
    required ProfessionalIqLayout layout,
    required List<ProfessionalIqFigure?> board,
    required List<ProfessionalIqFigure> options,
    required int correctIndex,
    required ProfessionalIqFigure answer,
    required int level,
    required int variant,
    int operationCode = 0,
  }) {
    // Structural fingerprint deliberately ignores palette/motif identity.
    // Re-skinning the same rule with another icon is not fresh gameplay.
    final String fingerprint = contentFingerprint(<Object?>[
      family.name,
      layout.name,
      variant % validatedTemplatesPerFamily,
      (level - 1) ~/ 2,
    ]);
    return ProfessionalIqQuestion(
      family: family,
      skill: skill,
      layout: layout,
      board: List<ProfessionalIqFigure?>.unmodifiable(board),
      options: List<ProfessionalIqFigure>.unmodifiable(options),
      correctIndex: correctIndex,
      promptKey: 'prompt_${family.name}',
      explanationKey: 'explain_${family.name}',
      fingerprint: fingerprint,
      operationCode: operationCode,
      difficulty: ((level - 1) / 9 + (variant % 10) * 0.012)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }

  ProfessionalIqSkill _skillFor(ProfessionalIqFamily family) {
    return switch (family) {
      ProfessionalIqFamily.colorPattern ||
      ProfessionalIqFamily.visualSeries ||
      ProfessionalIqFamily.matrix2 => ProfessionalIqSkill.visualPattern,
      ProfessionalIqFamily.rotation ||
      ProfessionalIqFamily.mirror ||
      ProfessionalIqFamily.sizePosition ||
      ProfessionalIqFamily.paperFold => ProfessionalIqSkill.spatialReasoning,
      ProfessionalIqFamily.oddOneOut => ProfessionalIqSkill.attention,
      ProfessionalIqFamily.shapeTransform ||
      ProfessionalIqFamily.countRelation ||
      ProfessionalIqFamily.analogy => ProfessionalIqSkill.transformation,
      ProfessionalIqFamily.matrix3 ||
      ProfessionalIqFamily.symmetry ||
      ProfessionalIqFamily.overlay ||
      ProfessionalIqFamily.xor ||
      ProfessionalIqFamily.mixedRules => ProfessionalIqSkill.logicalCombination,
    };
  }

  static const List<int> _rotationMotifs = <int>[
    4, 5, 6, 9, 11, 12, 13, 14, 16, 17, 18, 19,
  ];

  static const List<int> _mirrorMotifs = <int>[
    4, 5, 6, 7, 9, 11, 12, 13, 14, 15, 16, 18, 19,
  ];

  int _motifForVariant(int variant) =>
      ((variant % motifCount) + motifCount) % motifCount;

  int _rotationMotifForVariant(int variant) =>
      _rotationMotifs[((variant % _rotationMotifs.length) + _rotationMotifs.length) % _rotationMotifs.length];

  int _mirrorMotifForVariant(int variant) =>
      _mirrorMotifs[((variant % _mirrorMotifs.length) + _mirrorMotifs.length) % _mirrorMotifs.length];

  ProfessionalIqFigure _randomFigure(Random random) {
    return ProfessionalIqFigure(
      shape: random.nextInt(motifCount),
      color: random.nextInt(5),
      rotation: random.nextInt(4),
      count: 1 + random.nextInt(3),
      size: random.nextInt(2),
      pattern: 0,
      position: 4,
    );
  }

  ProfessionalIqFigure _transform(
    ProfessionalIqFigure value,
    _Transform transform,
    int variant,
  ) {
    final int direction = variant.isEven ? 1 : 3;
    return switch (transform) {
      _Transform.colorPattern => value.copyWith(
        color: (value.color + 1 + variant % 2) % 5,
      ),
      // Shape families are built as explicit A-B-A-B pairs in
      // `_seriesQuestion`; shape IDs are never treated as ordered numbers.
      _Transform.shape => value,
      _Transform.rotation => value.copyWith(
        rotation: (value.rotation + direction) % 4,
      ),
      _Transform.mirror => value.copyWith(
        position: 4,
        mirrored: !value.mirrored,
      ),
      _Transform.count => value.copyWith(count: value.count % 3 + 1),
      _Transform.sizePosition => value.copyWith(
        size: 1 - value.size,
        position: (value.position + 1 + variant % 2) % 9,
      ),
      _Transform.shapeRotation => value.copyWith(count: 2, size: 1),
      _Transform.patternRotation => value.copyWith(
        color: (value.color + 1) % 5,
        rotation: (value.rotation + direction) % 4,
      ),
    };
  }

  ProfessionalIqFigure _dotFigure(int mask, int variant) {
    return ProfessionalIqFigure(
      shape: 0,
      color: 0,
      rotation: 0,
      count: 1,
      size: 1,
      pattern: 0,
      position: 4,
      dotMask: mask,
    );
  }

  int _randomMask(Random random) {
    int mask = 0;
    while (mask == 0) {
      for (int index = 0; index < 9; index++) {
        if (random.nextBool()) mask |= 1 << index;
      }
    }
    return mask;
  }

  int _leftHalf(int mask) {
    const List<int> left = <int>[0, 3, 6];
    int result = 0;
    for (final int index in left) {
      if ((mask & (1 << index)) != 0) result |= 1 << index;
    }
    return result == 0 ? 1 : result;
  }

  int _mirrorMask(int mask) {
    int result = 0;
    for (int index = 0; index < 9; index++) {
      if ((mask & (1 << index)) == 0) continue;
      final int row = index ~/ 3;
      final int column = index % 3;
      result |= 1 << (row * 3 + (2 - column));
    }
    return result;
  }

  int _topHalf(int mask) {
    const List<int> top = <int>[0, 1, 2];
    int result = 0;
    for (final int index in top) {
      if ((mask & (1 << index)) != 0) result |= 1 << index;
    }
    return result == 0 ? 1 : result;
  }

  int _mirrorVerticalMask(int mask) {
    int result = 0;
    for (int index = 0; index < 9; index++) {
      if ((mask & (1 << index)) == 0) continue;
      final int row = index ~/ 3;
      final int column = index % 3;
      result |= 1 << ((2 - row) * 3 + column);
    }
    return result;
  }

  int _safeToggle(int mask, int salt) {
    int result = mask ^ (1 << (salt.abs() % 9));
    if (result == 0) {
      result = mask ^ (1 << ((salt.abs() + 4) % 9));
    }
    return result;
  }

}

enum _Transform {
  colorPattern,
  shape,
  rotation,
  mirror,
  count,
  sizePosition,
  shapeRotation,
  patternRotation,
}
