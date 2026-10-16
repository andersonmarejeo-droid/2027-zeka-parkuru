import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kite_runner/kite_runner_scenario.dart';

void main() {
  test(
    'ten kite courses add gates, crosswind, live wires and tighter slack',
    () {
      final List<KiteRunnerScenario> courses =
          List<KiteRunnerScenario>.generate(
            KiteRunnerScenario.campaignLevels,
            (int index) => KiteRunnerScenario.forLevel(index + 1),
          );
      expect(
        courses.map((KiteRunnerScenario course) => course.gates.length),
        orderedEquals(List<int>.generate(10, (int index) => index + 3)),
      );
      expect(courses.first.wires, isEmpty);
      expect(courses[3].wires, isNotEmpty);
      expect(courses[6].crosswind, greaterThan(courses[1].crosswind));
      expect(courses[9].snapThreshold, lessThan(courses[0].snapThreshold));
      expect(courses[9].missLimit, 1);
      expect(
        courses.every(
          (KiteRunnerScenario course) => course.gates.every(
            (KiteGate gate) =>
                gate.centerX - gate.sway - gate.width / 2 > .06 &&
                gate.centerX + gate.sway + gate.width / 2 < .94 &&
                gate.altitude - gate.height / 2 > .14,
          ),
        ),
        isTrue,
      );
    },
  );

  test('first 300 practice routes differ from campaign and each other', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= KiteRunnerScenario.campaignLevels; level++)
        KiteRunnerScenario.forLevel(level).signature,
    };
    for (int route = 1; route <= KiteRunnerScenario.practiceRoutes; route++) {
      final KiteRunnerScenario course = KiteRunnerScenario.forPracticeRoute(
        route,
      );
      expect(
        signatures.add(course.signature),
        isTrue,
        reason: 'route $route repeats',
      );
      expect(course.gates.length, greaterThanOrEqualTo(3));
      expect(course.gates.length, lessThanOrEqualTo(12));
    }
    expect(signatures, hasLength(310));
  });

  test('campaign and practice route indexes reject invalid bounds', () {
    expect(() => KiteRunnerScenario.forLevel(0), throwsRangeError);
    expect(() => KiteRunnerScenario.forLevel(11), throwsRangeError);
    expect(() => KiteRunnerScenario.forPracticeRoute(0), throwsRangeError);
    expect(() => KiteRunnerScenario.forPracticeRoute(301), throwsRangeError);
  });
}
