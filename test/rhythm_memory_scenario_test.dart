import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/rhythm_memory/rhythm_memory_scenario.dart';

void main() {
  group('Rhythm Memory content contract', () {
    test('twenty levels introduce rhythm, accents, reverse recall and dense finale', () {
      final List<RhythmMemoryScenario> campaign = <RhythmMemoryScenario>[
        for (
          int level = 1;
          level <= RhythmMemoryScenario.campaignLevels;
          level++
        )
          RhythmMemoryScenario.forCampaignLevel(level),
      ];

      expect(
        campaign.map((RhythmMemoryScenario item) => item.length),
        orderedEquals(<int>[
          3,
          3,
          4,
          4,
          5,
          5,
          6,
          6,
          6,
          7,
          7,
          7,
          7,
          8,
          8,
          8,
          9,
          9,
          10,
          11,
        ]),
      );
      expect(
        campaign
            .take(6)
            .every((RhythmMemoryScenario item) => !item.reverseRecall),
        isTrue,
      );
      expect(
        campaign
            .skip(10)
            .every((RhythmMemoryScenario item) => item.reverseRecall),
        isTrue,
      );
      expect(
        campaign
            .skip(6)
            .every((RhythmMemoryScenario item) => item.accentCount > 0),
        isTrue,
      );
      expect(campaign.last.mistakeLimit, 1);
      expect(campaign.last.gaps, contains(4));
      expect(
        campaign
            .map((RhythmMemoryScenario item) => item.signature)
            .toSet()
            .length,
        20,
      );
    });

    test('first 300 practice rhythms are unique and campaign-disjoint', () {
      final Set<String> campaign = <String>{
        for (int level = 1; level <= 20; level++)
          RhythmMemoryScenario.forCampaignLevel(level).signature,
      };
      final List<RhythmMemoryScenario> practice = <RhythmMemoryScenario>[
        for (int round = 1; round <= 300; round++)
          RhythmMemoryScenario.forPracticeRound(round),
      ];
      final Set<String> signatures = practice
          .map((RhythmMemoryScenario item) => item.signature)
          .toSet();

      expect(signatures, hasLength(300));
      expect(signatures.intersection(campaign), isEmpty);
      expect(
        practice.every((RhythmMemoryScenario item) => item.isPractice),
        isTrue,
      );
    });

    test('recall checks note order, accents and relative silence lengths', () {
      final RhythmMemoryScenario scenario =
          RhythmMemoryScenario.forCampaignLevel(20);
      final List<RhythmBeat> answer = scenario.answer;
      final List<int> intervals = <int>[
        for (final int gap in scenario.answerGaps) gap * 420,
      ];

      expect(
        scenario.accepts(
          notes: answer.map((RhythmBeat beat) => beat.note).toList(),
          accents: answer.map((RhythmBeat beat) => beat.accent).toList(),
          intervalsMs: intervals,
        ),
        isTrue,
      );
      expect(
        scenario.accepts(
          notes: <int>[
            ...answer
                .map((RhythmBeat beat) => beat.note)
                .take(answer.length - 1),
            (answer.last.note + 1) % 8,
          ],
          accents: answer.map((RhythmBeat beat) => beat.accent).toList(),
          intervalsMs: intervals,
        ),
        isFalse,
      );
      expect(
        scenario.accepts(
          notes: answer.map((RhythmBeat beat) => beat.note).toList(),
          accents: List<bool>.filled(answer.length, false),
          intervalsMs: intervals,
        ),
        isFalse,
      );
    });

    test('content factories reject values outside the 20 / 300 limits', () {
      expect(() => RhythmMemoryScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => RhythmMemoryScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => RhythmMemoryScenario.forPracticeRound(0), throwsRangeError);
      expect(
        () => RhythmMemoryScenario.forPracticeRound(301),
        throwsRangeError,
      );
    });
  });
}
