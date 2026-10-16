import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/meaning_match/meaning_match_scenario.dart';

void main() {
  group('Meaning Match content contract', () {
    test('campaign has 20 stable, distinct, progressively deeper boards', () {
      final Set<String> signatures = <String>{};
      const List<int> expectedTiers = <int>[
        1,
        1,
        1,
        3,
        3,
        3,
        5,
        5,
        5,
        7,
        7,
        7,
        9,
        9,
        9,
        10,
        10,
        10,
        10,
        10,
      ];

      for (
        int level = 1;
        level <= MeaningMatchScenario.campaignLevels;
        level++
      ) {
        final MeaningMatchScenario scenario =
            MeaningMatchScenario.forCampaignLevel(level);
        expect(scenario.categories, hasLength(4));
        expect(scenario.tiles, hasLength(16));
        expect(
          scenario.tiles.map((MeaningTile tile) => tile.word).toSet(),
          hasLength(16),
        );
        expect(scenario.stage, level);
        expect(
          scenario.categories
              .map((MeaningCategory category) => category.minimumStage)
              .reduce((int a, int b) => a > b ? a : b),
          expectedTiers[level - 1],
        );
        expect(signatures.add(scenario.groupSignature), isTrue);
        expect(
          MeaningMatchScenario.forCampaignLevel(level).boardSignature,
          scenario.boardSignature,
          reason: 'A campaign board must be reproducible for QA.',
        );
      }

      final MeaningMatchScenario finalLevel =
          MeaningMatchScenario.forCampaignLevel(20);
      expect(
        finalLevel.categories.where(
          (MeaningCategory category) => category.minimumStage == 10,
        ),
        hasLength(4),
        reason: 'The expert finale must require four top-tier categories.',
      );
    });

    test(
      'first 300 practice boards are unique and do not repeat campaign groups',
      () {
        final Set<String> campaignGroups = <String>{
          for (
            int level = 1;
            level <= MeaningMatchScenario.campaignLevels;
            level++
          )
            MeaningMatchScenario.forCampaignLevel(level).groupSignature,
        };
        final Set<String> practiceGroups = <String>{};

        for (
          int round = 1;
          round <= MeaningMatchScenario.uniquePracticeRounds;
          round++
        ) {
          final MeaningMatchScenario scenario =
              MeaningMatchScenario.forPracticeRound(round);
          expect(scenario.isPractice, isTrue);
          expect(scenario.round, round);
          expect(scenario.categories, hasLength(4));
          expect(scenario.tiles, hasLength(16));
          expect(
            scenario.tiles.map((MeaningTile tile) => tile.word).toSet(),
            hasLength(16),
          );
          expect(campaignGroups.contains(scenario.groupSignature), isFalse);
          expect(practiceGroups.add(scenario.groupSignature), isTrue);
        }
      },
    );

    test('English boards retain four unambiguous words per group', () {
      for (final MeaningMatchScenario scenario in <MeaningMatchScenario>[
        MeaningMatchScenario.forCampaignLevel(20, languageCode: 'en'),
        MeaningMatchScenario.forPracticeRound(217, languageCode: 'en'),
      ]) {
        expect(scenario.tiles, hasLength(16));
        expect(
          scenario.tiles.map((MeaningTile tile) => tile.word).toSet(),
          hasLength(16),
        );
        for (final MeaningCategory category in scenario.categories) {
          expect(
            scenario.tiles.where(
              (MeaningTile tile) => tile.categoryId == category.id,
            ),
            hasLength(4),
          );
        }
      }
    });

    test('scenario factories reject invalid campaign and practice ranges', () {
      expect(() => MeaningMatchScenario.forCampaignLevel(0), throwsRangeError);
      expect(() => MeaningMatchScenario.forCampaignLevel(21), throwsRangeError);
      expect(() => MeaningMatchScenario.forPracticeRound(0), throwsRangeError);
      expect(
        () => MeaningMatchScenario.forPracticeRound(301),
        throwsRangeError,
      );
    });
  });
}
