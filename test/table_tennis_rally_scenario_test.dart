import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/table_tennis_rally/table_tennis_scenario.dart';

void main() {
  test('20 matches progress from coaching pace to expert rally pressure', () {
    final List<TableTennisScenario> scenarios =
        List<TableTennisScenario>.generate(
          TableTennisScenario.campaignLevels,
          (int index) => TableTennisScenario.forLevel(index + 1),
        );
    expect(
      scenarios.map((TableTennisScenario item) => item.seed).toSet(),
      hasLength(20),
    );
    expect(scenarios.first.pointsToWin, 3);
    expect(scenarios.last.pointsToWin, 6);
    expect(scenarios.first.ballSpeed, lessThan(scenarios.last.ballSpeed));
    expect(
      scenarios.first.reactionSeconds,
      greaterThan(scenarios.last.reactionSeconds),
    );
    expect(
      scenarios.first.opponentErrorChance,
      greaterThan(scenarios.last.opponentErrorChance),
    );
  });

  test(
    'all 300 practice rallies have unique reproducible match signatures',
    () {
      final Set<String> signatures = <String>{};
      for (
        int index = 1;
        index <= TableTennisScenario.practiceRallies;
        index++
      ) {
        final TableTennisScenario first = TableTennisScenario.forPracticeRally(
          index,
        );
        final TableTennisScenario replay = TableTennisScenario.forPracticeRally(
          index,
        );
        expect(
          first.signature,
          replay.signature,
          reason: 'rally $index seed replay',
        );
        expect(
          signatures.add(first.signature),
          isTrue,
          reason: 'rally $index duplicated',
        );
        expect(
          first.signature,
          isNot(TableTennisScenario.forLevel(first.level).signature),
          reason: 'practice rally $index reused a campaign match',
        );
      }
      expect(signatures, hasLength(300));
    },
  );

  test('campaign and practice factories reject invalid indexes', () {
    expect(() => TableTennisScenario.forLevel(0), throwsRangeError);
    expect(() => TableTennisScenario.forLevel(21), throwsRangeError);
    expect(() => TableTennisScenario.forPracticeRally(0), throwsRangeError);
    expect(() => TableTennisScenario.forPracticeRally(301), throwsRangeError);
  });
}
