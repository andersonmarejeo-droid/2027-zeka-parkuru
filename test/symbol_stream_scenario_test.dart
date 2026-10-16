import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/symbol_stream/symbol_stream_scenario.dart';

void main() {
  group('Symbol Stream content contract', () {
    test('campaign grows from simple N-back to a two-shift expert stream', () {
      final List<SymbolStreamScenario> campaign = <SymbolStreamScenario>[
        for (
          int level = 1;
          level <= SymbolStreamScenario.campaignLevels;
          level++
        )
          SymbolStreamScenario.forCampaignLevel(level),
      ];
      expect(
        campaign.map((SymbolStreamScenario item) => item.length),
        orderedEquals(<int>[
          7,
          7,
          8,
          8,
          9,
          9,
          10,
          10,
          10,
          10,
          12,
          12,
          12,
          13,
          13,
          13,
          14,
          14,
          15,
          16,
        ]),
      );
      expect(
        campaign
            .take(6)
            .every((SymbolStreamScenario item) => item.nBackMax == 1),
        isTrue,
      );
      expect(campaign[6].nBackMax, 2);
      expect(campaign[10].nBackMax, 2);
      expect(campaign[16].nBackMax, 3);
      expect(campaign.last.nBackMax, 3);
      expect(campaign.last.ruleChangeCount, 2);
      expect(campaign.last.decisionCount, 14);
      expect(campaign.last.mistakeLimit, 1);
      expect(
        campaign.every(
          (SymbolStreamScenario item) =>
              item.expectedMatches > 0 &&
              item.expectedMatches < item.decisionCount,
        ),
        isTrue,
      );
      expect(
        campaign.map((SymbolStreamScenario item) => item.signature).toSet(),
        hasLength(20),
      );
    });

    test(
      'first 300 practice streams are distinct from campaign and each other',
      () {
        final Set<String> campaign = <String>{
          for (int level = 1; level <= 20; level++)
            SymbolStreamScenario.forCampaignLevel(level).signature,
        };
        final Set<String> practice = <String>{
          for (int round = 1; round <= 300; round++)
            SymbolStreamScenario.forPracticeRound(round).signature,
        };
        expect(practice, hasLength(300));
        expect(practice.intersection(campaign), isEmpty);
      },
    );

    test('every generated judgment points to the correct N-back source', () {
      for (int level = 1; level <= 20; level++) {
        final SymbolStreamScenario scenario =
            SymbolStreamScenario.forCampaignLevel(level);
        for (int index = 0; index < scenario.length; index++) {
          final SymbolStreamItem item = scenario.items[index];
          if (!item.hasDecision) {
            expect(index, lessThan(item.nBackDistance));
            continue;
          }
          expect(item.targetIndex, index - item.nBackDistance);
          final StreamSymbol target = scenario.items[item.targetIndex!].symbol;
          final bool actual = switch (item.mode) {
            SymbolCompareMode.shape => item.symbol.shape == target.shape,
            SymbolCompareMode.shapeAndColor =>
              item.symbol.shape == target.shape &&
                  item.symbol.color == target.color,
            SymbolCompareMode.exact =>
              item.symbol.signature == target.signature,
          };
          expect(item.matches, actual, reason: 'Level $level, item $index');
        }
      }
    });

    test(
      'scenario bounds reject out-of-range campaign and practice values',
      () {
        expect(
          () => SymbolStreamScenario.forCampaignLevel(0),
          throwsRangeError,
        );
        expect(
          () => SymbolStreamScenario.forCampaignLevel(21),
          throwsRangeError,
        );
        expect(
          () => SymbolStreamScenario.forPracticeRound(0),
          throwsRangeError,
        );
        expect(
          () => SymbolStreamScenario.forPracticeRound(301),
          throwsRangeError,
        );
      },
    );
  });
}
