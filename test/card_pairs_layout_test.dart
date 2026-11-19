import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_game_page.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_scenario.dart';

void main() {
  test('Audit card counts across all 20 campaign levels and practice rounds', () {
    final Map<int, int> stageCardCounts = {};
    for (int lvl = 1; lvl <= 20; lvl++) {
      final scenario = CardPairsScenario.forCampaignLevel(lvl);
      stageCardCounts[lvl] = scenario.cards.length;
      print('Level $lvl: ${scenario.cards.length} cards (${scenario.pairCount} pairs, ${scenario.decoyCount} decoys) - rule: ${scenario.rule.name}');
    }

    // Also check max practice rounds
    int maxCards = 0;
    for (int r = 1; r <= 300; r++) {
      final scenario = CardPairsScenario.forPracticeRound(r);
      if (scenario.cards.length > maxCards) {
        maxCards = scenario.cards.length;
      }
    }
    print('Max cards across all practice rounds: $maxCards');

    // Test grid layout fitting for various card counts up to 32 on a small phone (width: 360, height: 420)
    final testCounts = [6, 8, 12, 14, 16, 20, 24, 26, 32];
    const availableWidth = 336.0;
    const availableHeight = 440.0; // Typical expanded grid height on a 360x640 phone

    for (final count in testCounts) {
      final columns = CardPairsGridLayout.bestColumnsFor(count, availableWidth, availableHeight, gap: 6);
      final rows = (count / columns).ceil();
      final fitWidth = (availableWidth - 6 * (columns - 1)) / columns;
      final fitHeight = (availableHeight - 6 * (rows - 1)) / rows;
      final cardWidth = fitWidth < fitHeight / 1.15 ? fitWidth : fitHeight / 1.15;
      final extent = cardWidth * 1.15;
      final totalGridHeight = extent * rows + 6 * (rows - 1);
      final totalGridWidth = cardWidth * columns + 6 * (columns - 1);

      print('Cards: $count -> ${columns}x$rows | Card: ${cardWidth.toStringAsFixed(1)} x ${extent.toStringAsFixed(1)} | TotalGrid: ${totalGridWidth.toStringAsFixed(1)} x ${totalGridHeight.toStringAsFixed(1)} (avail: $availableWidth x $availableHeight)');

      expect(totalGridHeight, lessThanOrEqualTo(availableHeight + 0.01), reason: 'Card count $count overflows height!');
      expect(totalGridWidth, lessThanOrEqualTo(availableWidth + 0.01), reason: 'Card count $count overflows width!');
    }
  });
}
