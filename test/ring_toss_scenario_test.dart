import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/ring_toss/ring_toss_scenario.dart';

void main() {
  test('ten courses add target motion, wind, bank hazards and precision', () {
    final List<RingTossScenario> courses = List<RingTossScenario>.generate(
      RingTossScenario.maximumLevels,
      (int index) => RingTossScenario.forLevel(index + 1),
    );
    expect(
      courses.map((RingTossScenario course) => course.targetCount),
      orderedEquals(List<int>.generate(10, (int index) => index + 6)),
    );
    expect(
      courses
          .take(2)
          .every(
            (RingTossScenario course) => course.targets.every(
              (RingTarget target) => target.motionX == 0,
            ),
          ),
      isTrue,
    );
    expect(courses[6].bumpers, isNotEmpty);
    expect(
      courses[9].targets.first.radius,
      lessThan(courses[0].targets.first.radius),
    );
    expect(courses[9].missLimit, 1);
    expect(
      courses[9].targets.first.captureSpeed,
      lessThan(courses[6].targets.first.captureSpeed),
    );
  });

  test(
    'first 300 practice fairgrounds differ from campaign and each other',
    () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= RingTossScenario.maximumLevels; level++)
          RingTossScenario.forLevel(level).signature,
      };
      for (
        int round = 1;
        round <= RingTossScenario.maximumPracticeRounds;
        round++
      ) {
        final RingTossScenario course = RingTossScenario.forPracticeRound(
          round,
        );
        expect(
          signatures.add(course.signature),
          isTrue,
          reason: 'round $round repeats',
        );
        expect(
          course.targets.every(
            (RingTarget target) =>
                target.radius >= .034 && target.captureSpeed >= .40,
          ),
          isTrue,
        );
      }
      expect(signatures, hasLength(310));
    },
  );

  test('course and practice range are validated', () {
    expect(() => RingTossScenario.forLevel(0), throwsRangeError);
    expect(() => RingTossScenario.forLevel(11), throwsRangeError);
    expect(() => RingTossScenario.forPracticeRound(0), throwsRangeError);
    expect(() => RingTossScenario.forPracticeRound(301), throwsRangeError);
  });
}
