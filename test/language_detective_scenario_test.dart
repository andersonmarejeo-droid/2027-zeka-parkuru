import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/language_detective/language_detective_scenario.dart';

void main() {
  group('Language Detective content contract', () {
    test('20 campaign files progress to advanced and expert evidence', () {
      for (final bool english in <bool>[false, true]) {
        final Set<String> signatures = <String>{};
        for (
          int level = 1;
          level <= LanguageDetectiveScenario.campaignLevels;
          level++
        ) {
          final LanguageDetectiveScenario board =
              LanguageDetectiveScenario.forCampaignLevel(
                level,
                english: english,
              );
          expect(board.stage, level);
          expect(board.cases, hasLength(4));
          expect(signatures.add(board.boardSignature), isTrue);
          if (level >= 7 && level <= 10) {
            expect(
              board.cases.every(
                (DetectiveBoardCase item) => item.caseFile.minimumStage >= 7,
              ),
              isTrue,
            );
          }
          if (level >= 17) {
            expect(
              board.cases.every(
                (DetectiveBoardCase item) => item.caseFile.minimumStage == 10,
              ),
              isTrue,
            );
          }
          for (final DetectiveBoardCase item in board.cases) {
            expect(item.optionOrder.toSet(), <int>{0, 1, 2, 3});
            expect(item.correctOptionIndex, inInclusiveRange(0, 3));
            expect(item.caseFile.passageTr, isNotEmpty);
            expect(item.caseFile.passageEn, isNotEmpty);
            expect(item.caseFile.evidenceTr, isNotEmpty);
            expect(item.caseFile.evidenceEn, isNotEmpty);
          }
        }
      }
    });

    test(
      'first 300 practice evidence sets are unique and campaign-disjoint',
      () {
        for (final bool english in <bool>[false, true]) {
          final Set<String> campaign = <String>{
            for (
              int level = 1;
              level <= LanguageDetectiveScenario.campaignLevels;
              level++
            )
              LanguageDetectiveScenario.forCampaignLevel(
                level,
                english: english,
              ).boardSignature,
          };
          final Set<String> practice = <String>{};
          for (
            int round = 1;
            round <= LanguageDetectiveScenario.uniquePracticeRounds;
            round++
          ) {
            final LanguageDetectiveScenario board =
                LanguageDetectiveScenario.forPracticeRound(
                  round,
                  english: english,
                );
            expect(board.isPractice, isTrue);
            expect(board.cases, hasLength(4));
            expect(campaign.contains(board.boardSignature), isFalse);
            expect(
              practice.add(board.boardSignature),
              isTrue,
              reason: '$round',
            );
          }
        }
      },
    );

    test('factories reject out-of-range campaign and practice rounds', () {
      expect(
        () => LanguageDetectiveScenario.forCampaignLevel(0),
        throwsRangeError,
      );
      expect(
        () => LanguageDetectiveScenario.forCampaignLevel(21),
        throwsRangeError,
      );
      expect(
        () => LanguageDetectiveScenario.forPracticeRound(0),
        throwsRangeError,
      );
      expect(
        () => LanguageDetectiveScenario.forPracticeRound(301),
        throwsRangeError,
      );
    });
  });
}
