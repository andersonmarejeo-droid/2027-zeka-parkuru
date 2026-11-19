import 'dart:math' as math;

import '../shared/content_seed.dart';

enum CardPairsRule { exactTwin, sameShape, sameColor, semanticLink }

class CardPairCard {
  const CardPairCard({
    required this.id,
    required this.pairId,
    required this.label,
    required this.iconKey,
    required this.colorIndex,
    required this.patternIndex,
    required this.isDecoy,
  });

  final String id;
  final String? pairId;
  final String label;
  final String iconKey;
  final int colorIndex;
  final int patternIndex;
  final bool isDecoy;
}

class _SemanticPair {
  const _SemanticPair(
    this.leftTr,
    this.leftEn,
    this.rightTr,
    this.rightEn,
    this.leftIcon,
    this.rightIcon,
  );
  final String leftTr;
  final String leftEn;
  final String rightTr;
  final String rightEn;
  final String leftIcon;
  final String rightIcon;
}

/// Memory cards whose relationship changes as the campaign advances.
class CardPairsScenario {
  const CardPairsScenario({
    required this.stage,
    required this.rule,
    required this.pairCount,
    required this.cards,
    required this.isPractice,
    required this.round,
    required this.variant,
    required this.english,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;

  final int stage;
  final CardPairsRule rule;
  final int pairCount;
  final List<CardPairCard> cards;
  final bool isPractice;
  final int round;
  final int variant;
  final bool english;

  int get decoyCount => cards.where((CardPairCard card) => card.isDecoy).length;

  String get ruleTitle => english ? 'IDENTICAL IMAGE' : 'AYNI GÖRSEL';

  String get instruction => english
      ? 'Find cards with the exact same image.'
      : 'Görseli tamamen aynı olan kartları bul.';

  String get boardSignature {
    final List<String> faces =
        cards
            .map(
              (CardPairCard card) => <String>[
                card.pairId ?? 'decoy',
                card.label,
                card.iconKey,
                '${card.colorIndex}',
                '${card.patternIndex}',
              ].join(':'),
            )
            .toList()
          ..sort();
    return <String>[rule.name, ...faces].join('|');
  }

  List<CardPairCard> cardsForPair(String pairId) => cards
      .where((CardPairCard card) => card.pairId == pairId)
      .toList(growable: false);

  static const List<_SemanticPair> _semanticPairs = <_SemanticPair>[
    _SemanticPair('Harita', 'Map', 'Pusula', 'Compass', 'map', 'compass'),
    _SemanticPair('Kilit', 'Lock', 'Anahtar', 'Key', 'lock', 'key'),
    _SemanticPair('Tohum', 'Seed', 'Filiz', 'Sprout', 'grain', 'eco'),
    _SemanticPair(
      'Mercek',
      'Lens',
      'Odak',
      'Focus',
      'lens',
      'center_focus_strong',
    ),
    _SemanticPair('Gezegen', 'Planet', 'Yörünge', 'Orbit', 'public', 'orbit'),
    _SemanticPair(
      'Saat',
      'Clock',
      'Akrep',
      'Clock hand',
      'schedule',
      'rotate_right',
    ),
    _SemanticPair('Dalga', 'Wave', 'Kıyı', 'Shore', 'waves', 'beach_access'),
    _SemanticPair(
      'Kitap',
      'Book',
      'Ayraç',
      'Bookmark',
      'menu_book',
      'bookmark',
    ),
    _SemanticPair(
      'Nota',
      'Note',
      'Ritim',
      'Rhythm',
      'music_note',
      'graphic_eq',
    ),
    _SemanticPair('Yağmur', 'Rain', 'Şemsiye', 'Umbrella', 'rainy', 'umbrella'),
    _SemanticPair('Fırça', 'Brush', 'Renk', 'Color', 'brush', 'palette'),
    _SemanticPair('Kupa', 'Cup', 'Tabak', 'Saucer', 'coffee', 'circle'),
    _SemanticPair('Ampul', 'Bulb', 'Işık', 'Light', 'lightbulb', 'wb_sunny'),
    _SemanticPair('Dağ', 'Mountain', 'Patika', 'Trail', 'landscape', 'route'),
    _SemanticPair(
      'Mektup',
      'Letter',
      'Zarf',
      'Envelope',
      'mail',
      'forward_to_inbox',
    ),
    _SemanticPair(
      'Düğme',
      'Button',
      'İlik',
      'Buttonhole',
      'radio_button_checked',
      'grid_3x3',
    ),
  ];

  static CardPairsScenario forCampaignLevel(int level, {bool english = false}) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      stage: level,
      variant: 0,
      english: english,
      practice: false,
      round: level,
      seed: ContentSeed.forLevel(gameId: 'card_pairs:campaign', level: level),
    );
  }

  static CardPairsScenario forPracticeRound(int round, {bool english = false}) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _build(
      stage: ((round - 1) % campaignLevels) + 1,
      variant: ((round - 1) ~/ campaignLevels) + 1,
      english: english,
      practice: true,
      round: round,
      seed: ContentSeed.forLevel(gameId: 'card_pairs:practice', level: round),
    );
  }

  static CardPairsScenario _build({
    required int stage,
    required int variant,
    required bool english,
    required bool practice,
    required int round,
    required int seed,
  }) {
    final CardPairsRule rule = stage <= 3
        ? CardPairsRule.exactTwin
        : stage <= 6
        ? CardPairsRule.sameShape
        : stage <= 10
        ? CardPairsRule.sameColor
        : CardPairsRule.semanticLink;
    final int pairCount = stage <= 3
        ? 3
        : stage <= 6
        ? 4
        : stage <= 10
        ? 6
        : stage <= 16
        ? 8
        : 10;
    final int decoys = stage < 7
        ? 0
        : stage < 11
        ? 2
        : stage < 17
        ? 4
        : 6;
    final List<CardPairCard> deck = <CardPairCard>[];
    final math.Random random = math.Random(seed);
    for (int index = 0; index < pairCount; index++) {
      final int contentIndex =
          (stage * 3 + variant * 2 + index * 5) % _semanticPairs.length;
      final String pairId = 'pair_${index}_content_$contentIndex';
      final int color = (stage + variant * 3 + index * 5) % 8;
      final int pattern = (variant + index * 3) % 15;
      final String cardLabel =
          english ? 'Card ${contentIndex + 1}' : 'Kart ${contentIndex + 1}';
      final String pairIcon =
          _shapeKeys[(contentIndex + variant) % _shapeKeys.length];

      deck.add(
        CardPairCard(
          id: '${pairId}_a',
          pairId: pairId,
          label: cardLabel,
          iconKey: pairIcon,
          colorIndex: color,
          patternIndex: pattern,
          isDecoy: false,
        ),
      );
      deck.add(
        CardPairCard(
          id: '${pairId}_b',
          pairId: pairId,
          label: cardLabel,
          iconKey: pairIcon,
          colorIndex: color,
          patternIndex: pattern,
          isDecoy: false,
        ),
      );
    }
    final Set<String> pairIcons = deck.map((c) => c.iconKey).toSet();
    final List<String> availableDecoyIcons =
        _shapeKeys.where((k) => !pairIcons.contains(k)).toList();

    for (int index = 0; index < decoys; index++) {
      final int contentIndex =
          (stage + variant + index + 7) % _semanticPairs.length;
      final int color = (stage * 2 + variant + index) % 8;
      final String decoyIcon = availableDecoyIcons.isNotEmpty
          ? availableDecoyIcons[index % availableDecoyIcons.length]
          : _shapeKeys[(contentIndex + 7) % _shapeKeys.length];
      deck.add(
        CardPairCard(
          id: 'decoy_${stage}_${variant}_$index',
          pairId: null,
          label: english ? 'Decoy ${index + 1}' : 'Tuzak ${index + 1}',
          iconKey: decoyIcon,
          colorIndex: color,
          patternIndex: (variant + index * 2) % 15,
          isDecoy: true,
        ),
      );
    }
    deck.shuffle(random);
    return CardPairsScenario(
      stage: stage,
      rule: rule,
      pairCount: pairCount,
      cards: List<CardPairCard>.unmodifiable(deck),
      isPractice: practice,
      round: round,
      variant: variant,
      english: english,
    );
  }

  static const List<String> _shapeKeys = <String>[
    'change_history',
    'hexagon',
    'diamond',
    'flare',
    'cloud',
    'star',
    'lens',
    'water_drop',
    'sailing',
    'park',
    'extension',
    'circle',
    'polyline',
    'pets',
    'pentagon',
    'ac_unit',
    'local_florist',
    'bolt',
  ];
}
