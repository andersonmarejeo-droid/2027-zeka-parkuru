import 'dart:math' as math;

import '../shared/content_seed.dart';

enum SpotChangeKind { shape, color, rotation, pattern, scale, marker }

class SpotChangeObject {
  const SpotChangeObject({
    required this.shapeIndex,
    required this.colorIndex,
    required this.rotationStep,
    required this.patternIndex,
    required this.scaleIndex,
    required this.hasMarker,
  });

  final int shapeIndex;
  final int colorIndex;
  final int rotationStep;
  final int patternIndex;
  final int scaleIndex;
  final bool hasMarker;

  String get visualSignature =>
      '$shapeIndex:$colorIndex:$rotationStep:$patternIndex:$scaleIndex:${hasMarker ? 1 : 0}';

  SpotChangeObject copyWith({
    int? shapeIndex,
    int? colorIndex,
    int? rotationStep,
    int? patternIndex,
    int? scaleIndex,
    bool? hasMarker,
  }) => SpotChangeObject(
    shapeIndex: shapeIndex ?? this.shapeIndex,
    colorIndex: colorIndex ?? this.colorIndex,
    rotationStep: rotationStep ?? this.rotationStep,
    patternIndex: patternIndex ?? this.patternIndex,
    scaleIndex: scaleIndex ?? this.scaleIndex,
    hasMarker: hasMarker ?? this.hasMarker,
  );
}

/// Two restrained visual panels with controlled, content-level changes.
class SpotChangeScenario {
  const SpotChangeScenario({
    required this.stage,
    required this.before,
    required this.after,
    required this.isPractice,
    required this.round,
    required this.variant,
    required this.english,
    required this.includesRelationSwap,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static const int shapeCount = 12;
  static const int colorCount = 8;

  final int stage;
  final List<SpotChangeObject> before;
  final List<SpotChangeObject> after;
  final bool isPractice;
  final int round;
  final int variant;
  final bool english;
  final bool includesRelationSwap;

  int get cellCount => before.length;

  int get columns => 4;

  Set<int> get changedIndices => <int>{
    for (int index = 0; index < cellCount; index++)
      if (before[index].visualSignature != after[index].visualSignature) index,
  };

  int get changeCount => changedIndices.length;

  String get instruction {
    final String count = english
        ? '$changeCount changed ${changeCount == 1 ? 'position' : 'positions'}'
        : '$changeCount değişen konum';
    return english
        ? 'Compare each BEFORE → AFTER tile. Select exactly $count.'
        : 'ÖNCE → SONRA kutularını karşılaştır. Tam $count konumu seç.';
  }

  String get stageTheme => switch (stage) {
    <= 3 => english ? 'FORM & COLOUR' : 'ŞEKİL VE RENK',
    <= 6 => english ? 'DETAIL SHIFT' : 'AYRINTI KAYMASI',
    <= 10 => english ? 'MULTI-CHANGE' : 'ÇOKLU DEĞİŞİM',
    <= 16 => english ? 'RELATION SHIFT' : 'İLİŞKİ DEĞİŞİMİ',
    <= 19 => english ? 'DENSE SCENE' : 'YOĞUN SAHNE',
    _ => english ? 'MASTER COMPARISON' : 'USTA KIYASLAMASI',
  };

  String get boardSignature => <String>[
    '$cellCount:$changeCount:$includesRelationSwap',
    for (int index = 0; index < cellCount; index++)
      '${before[index].visualSignature}>${after[index].visualSignature}',
  ].join('|');

  static SpotChangeScenario forCampaignLevel(
    int level, {
    bool english = false,
  }) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      stage: level,
      variant: 0,
      english: english,
      practice: false,
      round: level,
      seed: ContentSeed.forLevel(gameId: 'spot_change:campaign', level: level),
    );
  }

  static SpotChangeScenario forPracticeRound(
    int round, {
    bool english = false,
  }) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _build(
      stage: ((round - 1) % campaignLevels) + 1,
      variant: ((round - 1) ~/ campaignLevels) + 1,
      english: english,
      practice: true,
      round: round,
      seed: ContentSeed.forLevel(gameId: 'spot_change:practice', level: round),
    );
  }

  static SpotChangeScenario _build({
    required int stage,
    required int variant,
    required bool english,
    required bool practice,
    required int round,
    required int seed,
  }) {
    final int cellCount = stage <= 3
        ? 6
        : stage <= 6
        ? 8
        : stage <= 10
        ? 8
        : stage <= 16
        ? 10
        : 12;
    final int requestedChanges = stage <= 6
        ? 1
        : stage <= 10
        ? 2
        : stage <= 16
        ? 2
        : stage <= 19
        ? 3
        : 4;
    final bool relationSwap = stage >= 11;
    final math.Random random = math.Random(seed);
    final List<SpotChangeObject> before = List<SpotChangeObject>.generate(
      cellCount,
      (int index) => SpotChangeObject(
        shapeIndex: random.nextInt(shapeCount),
        colorIndex: random.nextInt(colorCount),
        rotationStep: random.nextInt(8),
        patternIndex: random.nextInt(5),
        scaleIndex: random.nextInt(3),
        hasMarker: random.nextInt(4) == 0,
      ),
      growable: false,
    );
    final List<SpotChangeObject> after = List<SpotChangeObject>.from(before);
    final List<int> targets = List<int>.generate(
      cellCount,
      (int index) => index,
    )..shuffle(random);
    final List<int> selectedTargets = targets.take(requestedChanges).toList();
    bool usedRelationSwap = false;

    if (relationSwap && selectedTargets.length >= 2) {
      final int left = selectedTargets[0];
      final int right = selectedTargets[1];
      if (before[left].visualSignature == before[right].visualSignature) {
        before[left] = before[left].copyWith(
          shapeIndex: (before[left].shapeIndex + 1) % shapeCount,
        );
        after[left] = before[left];
      }
      final SpotChangeObject leftObject = after[left];
      after[left] = after[right];
      after[right] = leftObject;
      usedRelationSwap = true;
    }

    final List<SpotChangeKind> kinds = stage <= 3
        ? <SpotChangeKind>[
            SpotChangeKind.shape,
            SpotChangeKind.color,
            SpotChangeKind.scale,
          ]
        : stage <= 6
        ? <SpotChangeKind>[
            SpotChangeKind.rotation,
            SpotChangeKind.pattern,
            SpotChangeKind.marker,
          ]
        : stage <= 10
        ? <SpotChangeKind>[
            SpotChangeKind.shape,
            SpotChangeKind.color,
            SpotChangeKind.pattern,
          ]
        : <SpotChangeKind>[
            SpotChangeKind.rotation,
            SpotChangeKind.pattern,
            SpotChangeKind.scale,
            SpotChangeKind.marker,
            SpotChangeKind.shape,
            SpotChangeKind.color,
          ];

    for (
      int slot = usedRelationSwap ? 2 : 0;
      slot < selectedTargets.length;
      slot++
    ) {
      final int index = selectedTargets[slot];
      final SpotChangeObject object = after[index];
      final SpotChangeKind kind =
          kinds[(stage + slot + variant) % kinds.length];
      after[index] = switch (kind) {
        SpotChangeKind.shape => object.copyWith(
          shapeIndex:
              (object.shapeIndex + 1 + random.nextInt(shapeCount - 1)) %
              shapeCount,
        ),
        SpotChangeKind.color => object.copyWith(
          colorIndex:
              (object.colorIndex + 1 + random.nextInt(colorCount - 1)) %
              colorCount,
        ),
        SpotChangeKind.rotation => object.copyWith(
          shapeIndex: <int>[0, 4, 11][random.nextInt(3)],
          rotationStep: (object.rotationStep + 1 + random.nextInt(3)) % 8,
        ),
        SpotChangeKind.pattern => object.copyWith(
          patternIndex: (object.patternIndex + 1 + random.nextInt(4)) % 5,
        ),
        SpotChangeKind.scale => object.copyWith(
          scaleIndex: (object.scaleIndex + 1 + random.nextInt(2)) % 3,
        ),
        SpotChangeKind.marker => object.copyWith(hasMarker: !object.hasMarker),
      };
    }

    return SpotChangeScenario(
      stage: stage,
      before: List<SpotChangeObject>.unmodifiable(before),
      after: List<SpotChangeObject>.unmodifiable(after),
      isPractice: practice,
      round: round,
      variant: variant,
      english: english,
      includesRelationSwap: usedRelationSwap,
    );
  }
}
