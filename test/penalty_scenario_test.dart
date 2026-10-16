import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/penalty_mindgame/penalty_scenario.dart';

void main() {
  test('20 shootouts ramp speed and tighten the dive window', () {
    final List<PenaltyScenario> scenarios = List<PenaltyScenario>.generate(
      PenaltyScenario.campaignLevels,
      (int index) => PenaltyScenario.forLevel(index + 1),
    );
    expect(scenarios.first.roundCount, 3);
    expect(scenarios.last.roundCount, 5);
    expect(scenarios.first.shotSpeed, lessThan(scenarios.last.shotSpeed));
    expect(
      scenarios.first.diveTimingWindow,
      greaterThan(scenarios.last.diveTimingWindow),
    );
    expect(
      scenarios.first.runUpSeconds,
      greaterThan(scenarios.last.runUpSeconds),
    );
  });

  test(
    'visible body-language majority remains truthful with one decoy cue',
    () {
      for (int level = 1; level <= PenaltyScenario.campaignLevels; level++) {
        final PenaltyScenario scenario = PenaltyScenario.forLevel(level);
        for (int round = 0; round < scenario.kickLanes.length; round++) {
          expect(
            scenario.cueAt(round).majority,
            scenario.kickAt(round),
            reason: 'level $level round ${round + 1}',
          );
        }
      }
    },
  );

  test('300 deterministic practice shootouts are all signature-unique', () {
    final Set<String> signatures = <String>{};
    for (int index = 1; index <= PenaltyScenario.practiceShootouts; index++) {
      final PenaltyScenario first = PenaltyScenario.forPracticeShootout(index);
      final PenaltyScenario replay = PenaltyScenario.forPracticeShootout(index);
      expect(first.signature, replay.signature);
      expect(
        signatures.add(first.signature),
        isTrue,
        reason: 'shootout $index duplicated',
      );
      expect(
        first.signature,
        isNot(PenaltyScenario.forLevel(first.level).signature),
      );
    }
    expect(signatures, hasLength(300));
  });

  test('scenario factories reject indexes outside their documented limits', () {
    expect(() => PenaltyScenario.forLevel(0), throwsRangeError);
    expect(() => PenaltyScenario.forLevel(21), throwsRangeError);
    expect(() => PenaltyScenario.forPracticeShootout(0), throwsRangeError);
    expect(() => PenaltyScenario.forPracticeShootout(301), throwsRangeError);
  });
}
