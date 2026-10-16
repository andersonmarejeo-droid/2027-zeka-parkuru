import 'dart:math' as math;

import '../shared/content_seed.dart';

enum SymbolCompareMode { shape, shapeAndColor, exact }

class StreamSymbol {
  const StreamSymbol({
    required this.shape,
    required this.color,
    required this.marker,
  });

  final int shape;
  final int color;
  final int marker;

  String get signature => '$shape:$color:$marker';
}

class SymbolStreamItem {
  const SymbolStreamItem({
    required this.symbol,
    required this.nBackDistance,
    required this.mode,
    required this.matches,
    required this.targetIndex,
  });

  final StreamSymbol symbol;
  final int nBackDistance;
  final SymbolCompareMode mode;
  final bool? matches;
  final int? targetIndex;

  bool get hasDecision => matches != null;
}

/// Continuous working-memory stream. The participant judges each item against
/// the rule's N-back target; late levels change both distance and feature set.
class SymbolStreamScenario {
  const SymbolStreamScenario({
    required this.stage,
    required this.items,
    required this.isPractice,
    required this.round,
    required this.variant,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static const int shapeCount = 9;
  static const int colorCount = 8;
  static const int markerCount = 4;
  static final List<SymbolStreamScenario> _practiceDeck = _buildPracticeDeck();

  final int stage;
  final List<SymbolStreamItem> items;
  final bool isPractice;
  final int round;
  final int variant;

  int get length => items.length;
  int get decisionCount =>
      items.where((SymbolStreamItem item) => item.hasDecision).length;
  int get expectedMatches =>
      items.where((SymbolStreamItem item) => item.matches == true).length;
  int get nBackMax => items.fold<int>(
    1,
    (int max, SymbolStreamItem item) => math.max(max, item.nBackDistance),
  );
  int get ruleChangeCount =>
      <String>{
        for (final SymbolStreamItem item in items)
          '${item.nBackDistance}:${item.mode.name}',
      }.length -
      1;
  int get mistakeLimit => stage <= 3
      ? 5
      : stage <= 6
      ? 4
      : stage <= 10
      ? 3
      : stage <= 16
      ? 2
      : 1;

  String get signature => <String>[
    '$stage:$length:$nBackMax:$ruleChangeCount',
    for (int index = 0; index < items.length; index++)
      '${items[index].symbol.signature}/${items[index].nBackDistance}/${items[index].mode.name}/${items[index].matches ?? '-'}',
  ].join('|');

  static SymbolStreamScenario forCampaignLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      stage: level,
      isPractice: false,
      round: level,
      variant: 0,
      seed: ContentSeed.forLevel(
        gameId: 'symbol_stream:campaign',
        level: level,
      ),
    );
  }

  static SymbolStreamScenario forPracticeRound(int round) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _practiceDeck[round - 1];
  }

  static List<SymbolStreamScenario> _buildPracticeDeck() {
    final Set<String> used = <String>{
      for (int level = 1; level <= campaignLevels; level++)
        forCampaignLevel(level).signature,
    };
    final List<SymbolStreamScenario> deck = <SymbolStreamScenario>[];
    for (int round = 1; round <= uniquePracticeRounds; round++) {
      final int stage = ((round - 1) % campaignLevels) + 1;
      SymbolStreamScenario? selected;
      for (int attempt = 0; attempt < 10000; attempt++) {
        final SymbolStreamScenario candidate = _build(
          stage: stage,
          isPractice: true,
          round: round,
          variant: attempt,
          seed: ContentSeed.forLevel(
            gameId: 'symbol_stream:practice:$attempt',
            level: round,
          ),
        );
        if (used.add(candidate.signature)) {
          selected = candidate;
          break;
        }
      }
      if (selected == null) {
        throw StateError('Could not generate unique symbol stream $round.');
      }
      deck.add(selected);
    }
    return List<SymbolStreamScenario>.unmodifiable(deck);
  }

  static SymbolStreamScenario _build({
    required int stage,
    required bool isPractice,
    required int round,
    required int variant,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final int length = switch (stage) {
      <= 2 => 7,
      <= 4 => 8,
      <= 6 => 9,
      <= 10 => 10,
      <= 13 => 12,
      <= 16 => 13,
      <= 18 => 14,
      19 => 15,
      _ => 16,
    };
    final List<StreamSymbol> symbols = <StreamSymbol>[];
    final List<SymbolStreamItem> items = <SymbolStreamItem>[];
    for (int index = 0; index < length; index++) {
      final int distance = _distanceFor(stage, index, length);
      final SymbolCompareMode mode = _modeFor(stage, index, length);
      StreamSymbol symbol = StreamSymbol(
        shape: random.nextInt(shapeCount),
        color: random.nextInt(colorCount),
        marker: random.nextInt(markerCount),
      );
      bool? matches;
      int? targetIndex;
      if (index >= distance) {
        targetIndex = index - distance;
        matches = ((index + variant) % 3) == 0;
        symbol = _fitComparison(
          symbol: symbol,
          target: symbols[targetIndex],
          mode: mode,
          shouldMatch: matches,
        );
      }
      symbols.add(symbol);
      items.add(
        SymbolStreamItem(
          symbol: symbol,
          nBackDistance: distance,
          mode: mode,
          matches: matches,
          targetIndex: targetIndex,
        ),
      );
    }
    return SymbolStreamScenario(
      stage: stage,
      items: List<SymbolStreamItem>.unmodifiable(items),
      isPractice: isPractice,
      round: round,
      variant: variant,
    );
  }

  static int _distanceFor(int stage, int index, int length) {
    if (stage <= 6) return 1;
    if (stage <= 10) return index < length ~/ 2 ? 1 : 2;
    if (stage <= 16) return 2;
    if (stage == 20) return index < length ~/ 3 ? 2 : 3;
    return 3;
  }

  static SymbolCompareMode _modeFor(int stage, int index, int length) {
    if (stage <= 10) return SymbolCompareMode.shapeAndColor;
    if (stage <= 16) {
      return index < length ~/ 2
          ? SymbolCompareMode.shape
          : SymbolCompareMode.exact;
    }
    return index < length ~/ 2
        ? SymbolCompareMode.shapeAndColor
        : SymbolCompareMode.exact;
  }

  static StreamSymbol _fitComparison({
    required StreamSymbol symbol,
    required StreamSymbol target,
    required SymbolCompareMode mode,
    required bool shouldMatch,
  }) {
    if (mode == SymbolCompareMode.shape) {
      return symbol.copyWith(
        shape: shouldMatch
            ? target.shape
            : _different(target.shape, shapeCount),
      );
    }
    if (mode == SymbolCompareMode.shapeAndColor) {
      if (shouldMatch) {
        return symbol.copyWith(shape: target.shape, color: target.color);
      }
      // Preserve the shape as a near-match and alter colour only.
      return symbol.copyWith(
        shape: target.shape,
        color: _different(target.color, colorCount),
      );
    }
    return shouldMatch
        ? target
        : symbol.copyWith(
            shape: target.shape,
            color: target.color,
            marker: _different(target.marker, markerCount),
          );
  }

  static int _different(int value, int count) => (value + 1) % count;
}

extension on StreamSymbol {
  StreamSymbol copyWith({int? shape, int? color, int? marker}) => StreamSymbol(
    shape: shape ?? this.shape,
    color: color ?? this.color,
    marker: marker ?? this.marker,
  );
}
