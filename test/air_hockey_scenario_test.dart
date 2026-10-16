import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/air_hockey_arena/air_hockey_scenario.dart';

void main() {
  test('20 arenas ramp goal pressure and introduce bank-shot bumpers', () {
    final List<AirHockeyScenario> scenarios = List<AirHockeyScenario>.generate(
      AirHockeyScenario.campaignLevels,
      (int index) => AirHockeyScenario.forLevel(index + 1),
    );
    expect(scenarios.first.goalsToWin, 3);
    expect(scenarios.last.goalsToWin, 6);
    expect(scenarios.first.puckSpeed, lessThan(scenarios.last.puckSpeed));
    expect(scenarios.first.goalWidth, greaterThan(scenarios.last.goalWidth));
    expect(scenarios.first.bumpers, isEmpty);
    expect(scenarios[8].bumpers, hasLength(2));
    expect(scenarios.last.bumpers, hasLength(3));
  });

  test('300 practice arenas have unique reproducible physics signatures', () {
    final Set<String> signatures = <String>{};
    for (int index = 1; index <= AirHockeyScenario.practiceArenas; index++) {
      final AirHockeyScenario first = AirHockeyScenario.forPracticeArena(index);
      final AirHockeyScenario replay = AirHockeyScenario.forPracticeArena(
        index,
      );
      expect(first.signature, replay.signature);
      expect(
        signatures.add(first.signature),
        isTrue,
        reason: 'arena $index repeated',
      );
      expect(
        first.signature,
        isNot(AirHockeyScenario.forLevel(first.level).signature),
      );
    }
    expect(signatures, hasLength(300));
  });

  test(
    'arena factories reject indexes outside the campaign and practice range',
    () {
      expect(() => AirHockeyScenario.forLevel(0), throwsRangeError);
      expect(() => AirHockeyScenario.forLevel(21), throwsRangeError);
      expect(() => AirHockeyScenario.forPracticeArena(0), throwsRangeError);
      expect(() => AirHockeyScenario.forPracticeArena(301), throwsRangeError);
    },
  );
}
