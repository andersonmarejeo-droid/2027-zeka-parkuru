import 'dart:math' as math;

import '../../l10n/app_localizations.dart';
import '../shared/content_seed.dart';

enum FocusFilterRule {
  holdShape,
  holdColor,
  shapeAndColor,
  shiftingShape,
  rareSignal,
  repeatShape,
}

class FocusStimulus {
  const FocusStimulus({
    required this.index,
    required this.shapeIndex,
    required this.colorIndex,
    required this.patternIndex,
    required this.hasRing,
    required this.isTarget,
  });

  final int index;
  final int shapeIndex;
  final int colorIndex;
  final int patternIndex;
  final bool hasRing;
  final bool isTarget;

  String get signature =>
      '$shapeIndex:$colorIndex:$patternIndex:${hasRing ? 1 : 0}:${isTarget ? 1 : 0}';
}

/// A no-go visual-attention filter with carefully controlled near misses.
class FocusFilterScenario {
  const FocusFilterScenario({
    required this.stage,
    required this.rule,
    required this.stimuli,
    required this.targetShape,
    required this.secondTargetShape,
    required this.targetColor,
    required this.isPractice,
    required this.round,
    required this.variant,
    required this.english,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static const int shapeCount = 12;
  static const int colorCount = 8;

  final int stage;
  final FocusFilterRule rule;
  final List<FocusStimulus> stimuli;
  final int targetShape;
  final int secondTargetShape;
  final int targetColor;
  final bool isPractice;
  final int round;
  final int variant;
  final bool english;

  int get targetCount =>
      stimuli.where((FocusStimulus stimulus) => stimulus.isTarget).length;

  int get decoyCount => stimuli.length - targetCount;

  String get ruleTitle => switch (rule) {
    FocusFilterRule.holdShape => english ? 'HOLD THE SHAPE' : 'ŞEKLİ İZLE',
    FocusFilterRule.holdColor => english ? 'HOLD THE COLOR' : 'RENGİ İZLE',
    FocusFilterRule.shapeAndColor =>
      english ? 'TWO-FACTOR FILTER' : 'İKİLİ FİLTRE',
    FocusFilterRule.shiftingShape => english ? 'RULE SHIFT' : 'KURAL DEĞİŞİMİ',
    FocusFilterRule.rareSignal => english ? 'RARE SIGNAL' : 'NADİR SİNYAL',
    FocusFilterRule.repeatShape =>
      english ? 'SEQUENCE FILTER' : 'DİZİ FİLTRESİ',
  };

  String get instruction => switch (rule) {
    FocusFilterRule.holdShape =>
      english
          ? 'Tap only the named shape. Ignore its color and surface.'
          : 'Yalnız adı verilen şekle dokun. Rengi ve yüzeyini önemseme.',
    FocusFilterRule.holdColor =>
      english
          ? 'Tap only the named color. Symbols may change.'
          : 'Yalnız belirtilen renge dokun. Semboller değişebilir.',
    FocusFilterRule.shapeAndColor =>
      english
          ? 'Both conditions must be true: the named shape AND the named color.'
          : 'İki koşul birlikte doğru olmalı: belirtilen şekil VE belirtilen renk.',
    FocusFilterRule.shiftingShape =>
      english
          ? 'The target shape changes halfway through. Re-read the phase marker.'
          : 'Hedef şekil yarıda değişir. Evre işaretini yeniden kontrol et.',
    FocusFilterRule.rareSignal =>
      english
          ? 'Tap a ringed signal in the target color. Plain shapes are near-misses.'
          : 'Hedef renkte, halkalı işarete dokun. Düz şekiller yakın yanıltıcıdır.',
    FocusFilterRule.repeatShape =>
      english
          ? 'Tap only when this shape repeats the previous shape.'
          : 'Yalnız bu şekil bir önceki şekli tekrarladığında dokun.',
  };

  String get targetLabel => switch (rule) {
    FocusFilterRule.holdShape => _shapeName(targetShape),
    FocusFilterRule.holdColor => _colorName(targetColor),
    FocusFilterRule.shapeAndColor =>
      '${_shapeName(targetShape)} + ${_colorName(targetColor)}',
    FocusFilterRule.shiftingShape =>
      '${_shapeName(targetShape)}  →  ${_shapeName(secondTargetShape)}',
    FocusFilterRule.rareSignal => _colorName(targetColor),
    FocusFilterRule.repeatShape =>
      english ? 'REPEATED SHAPE' : 'TEKRAR EDEN ŞEKİL',
  };

  String get boardSignature => <String>[
    rule.name,
    '$targetShape:$secondTargetShape:$targetColor',
    ...stimuli.map((FocusStimulus stimulus) => stimulus.signature),
  ].join('|');

  bool isTargetAt(int index) => stimuli[index].isTarget;

  static const List<String> _shapeNamesTr = <String>[
    'Üçgen',
    'Daire',
    'Kare',
    'Yıldız',
    'Elmas',
    'Hilal',
    'Altıgen',
    'Çiçek',
    'Damla',
    'Bulut',
    'Yaprak',
    'Şimşek',
  ];

  static const List<String> _shapeNamesEn = <String>[
    'Triangle',
    'Circle',
    'Square',
    'Star',
    'Diamond',
    'Crescent',
    'Hexagon',
    'Flower',
    'Drop',
    'Cloud',
    'Leaf',
    'Bolt',
  ];

  static const List<String> _colorNamesTr = <String>[
    'Kehribar',
    'Mavi',
    'Turkuaz',
    'Mercan',
    'Mor',
    'Yeşil',
    'Kırmızı',
    'Lacivert',
  ];

  static const List<String> _colorNamesEn = <String>[
    'Amber',
    'Blue',
    'Teal',
    'Coral',
    'Violet',
    'Green',
    'Red',
    'Navy',
  ];

  String _shapeName(int index) => uppercaseUiText(
    (english ? _shapeNamesEn : _shapeNamesTr)[index % shapeCount],
    english: english,
  );

  String _colorName(int index) => uppercaseUiText(
    (english ? _colorNamesEn : _colorNamesTr)[index % colorCount],
    english: english,
  );

  static FocusFilterScenario forCampaignLevel(
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
      seed: ContentSeed.forLevel(gameId: 'focus_filter:campaign', level: level),
    );
  }

  static FocusFilterScenario forPracticeRound(
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
      seed: ContentSeed.forLevel(gameId: 'focus_filter:practice', level: round),
    );
  }

  static FocusFilterScenario _build({
    required int stage,
    required int variant,
    required bool english,
    required bool practice,
    required int round,
    required int seed,
  }) {
    final FocusFilterRule rule = switch (stage) {
      <= 3 => FocusFilterRule.holdShape,
      <= 6 => FocusFilterRule.holdColor,
      <= 10 => FocusFilterRule.shapeAndColor,
      <= 16 => FocusFilterRule.shiftingShape,
      <= 19 => FocusFilterRule.rareSignal,
      _ => FocusFilterRule.repeatShape,
    };
    final int trialCount = switch (stage) {
      <= 3 => 12,
      <= 6 => 14,
      <= 10 => 16,
      <= 16 => 18,
      <= 19 => 22,
      _ => 24,
    };
    final math.Random random = math.Random(seed);
    final int targetShape = random.nextInt(shapeCount);
    int secondTargetShape = random.nextInt(shapeCount);
    while (secondTargetShape == targetShape) {
      secondTargetShape = random.nextInt(shapeCount);
    }
    final int targetColor = random.nextInt(colorCount);
    final List<FocusStimulus> stimuli = <FocusStimulus>[];
    int previousShape = random.nextInt(shapeCount);

    for (int index = 0; index < trialCount; index++) {
      bool wantsTarget = switch (rule) {
        FocusFilterRule.holdShape => (index + variant) % 4 == 0,
        FocusFilterRule.holdColor => (index + variant) % 4 == 1,
        FocusFilterRule.shapeAndColor => (index + variant) % 5 == 0,
        FocusFilterRule.shiftingShape => (index + variant) % 4 == 2,
        FocusFilterRule.rareSignal => (index + variant) % 6 == 0,
        FocusFilterRule.repeatShape => (index + variant) % 3 == 0,
      };
      if (rule == FocusFilterRule.repeatShape && index == 0) {
        wantsTarget = false;
      }
      final int phaseTarget = index < trialCount ~/ 2
          ? targetShape
          : secondTargetShape;
      int shape = random.nextInt(shapeCount);
      int color = random.nextInt(colorCount);
      bool hasRing = random.nextBool();

      switch (rule) {
        case FocusFilterRule.holdShape:
          shape = wantsTarget
              ? targetShape
              : shape == targetShape
              ? (shape + 1 + random.nextInt(shapeCount - 1)) % shapeCount
              : shape;
        case FocusFilterRule.holdColor:
          color = wantsTarget
              ? targetColor
              : color == targetColor
              ? (color + 1 + random.nextInt(colorCount - 1)) % colorCount
              : color;
        case FocusFilterRule.shapeAndColor:
          if (wantsTarget) {
            shape = targetShape;
            color = targetColor;
          } else if (random.nextBool()) {
            shape = targetShape;
            color =
                (targetColor + 1 + random.nextInt(colorCount - 1)) % colorCount;
          } else {
            shape =
                (targetShape + 1 + random.nextInt(shapeCount - 1)) % shapeCount;
            color = targetColor;
          }
        case FocusFilterRule.shiftingShape:
          shape = wantsTarget
              ? phaseTarget
              : shape == phaseTarget
              ? (shape + 1 + random.nextInt(shapeCount - 1)) % shapeCount
              : shape;
        case FocusFilterRule.rareSignal:
          color = targetColor;
          hasRing = wantsTarget;
          if (!wantsTarget && random.nextBool()) {
            color =
                (targetColor + 1 + random.nextInt(colorCount - 1)) % colorCount;
          }
        case FocusFilterRule.repeatShape:
          shape = wantsTarget
              ? previousShape
              : (previousShape + 1 + random.nextInt(shapeCount - 1)) %
                    shapeCount;
      }
      stimuli.add(
        FocusStimulus(
          index: index,
          shapeIndex: shape,
          colorIndex: color,
          patternIndex: random.nextInt(6),
          hasRing: hasRing,
          isTarget: wantsTarget,
        ),
      );
      previousShape = shape;
    }

    return FocusFilterScenario(
      stage: stage,
      rule: rule,
      stimuli: List<FocusStimulus>.unmodifiable(stimuli),
      targetShape: targetShape,
      secondTargetShape: secondTargetShape,
      targetColor: targetColor,
      isPractice: practice,
      round: round,
      variant: variant,
      english: english,
    );
  }
}
