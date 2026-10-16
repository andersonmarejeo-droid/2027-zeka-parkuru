import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/color_reactor/color_reactor_scenario.dart';

void main() {
  group('Color Reactor content certificate', () {
    test(
      '10 pulse courses are distinct, feasible and increase channel pressure',
      () {
        final Set<String> signatures = <String>{};
        ReactorScenario? previous;
        for (int level = 1; level <= ReactorScenario.maximumLevels; level++) {
          final ReactorScenario scenario = ReactorScenario.forLevel(level);
          expect(
            signatures.add(scenario.signature),
            isTrue,
            reason: 'level $level',
          );
          expect(scenario.pulses, hasLength(7 + level));
          expect(scenario.requiredHits, greaterThan(0));
          expect(
            scenario.requiredHits,
            lessThanOrEqualTo(scenario.pulses.length),
          );
          expect(scenario.pulses.first.destination, 0);
          if (previous != null) {
            expect(
              scenario.channelCount,
              greaterThanOrEqualTo(previous.channelCount),
            );
            expect(
              scenario.pulses.first.speed,
              greaterThan(previous.pulses.first.speed),
            );
          }
          if (level == 1) expect(scenario.channelCount, 1);
          if (level == 4) expect(scenario.channelCount, 3);
          if (level == 10) {
            expect(scenario.channelCount, 3);
            expect(
              scenario.pulses
                  .map((ReactorPulseSpec pulse) => pulse.destination)
                  .toSet(),
              hasLength(3),
            );
          }
          previous = scenario;
        }
      },
    );

    test(
      'first 300 practice sequences never repeat campaign or one another',
      () {
        final Set<String> signatures = <String>{
          for (int level = 1; level <= ReactorScenario.maximumLevels; level++)
            ReactorScenario.forLevel(level).signature,
        };
        for (
          int index = 1;
          index <= ReactorScenario.maximumPracticeRounds;
          index++
        ) {
          expect(
            signatures.add(ReactorScenario.forPracticeRound(index).signature),
            isTrue,
            reason: 'reactor sequence $index',
          );
        }
      },
    );

    test('invalid course and replay indices are rejected', () {
      expect(() => ReactorScenario.forLevel(0), throwsRangeError);
      expect(
        () => ReactorScenario.forPracticeRound(
          ReactorScenario.maximumPracticeRounds + 1,
        ),
        throwsRangeError,
      );
    });
  });
}
