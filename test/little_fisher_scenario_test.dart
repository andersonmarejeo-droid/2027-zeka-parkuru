import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/little_fisher/little_fisher_scenario.dart';

void main() {
  test(
    'ten fishing routes add schools, stronger pulls and layered current',
    () {
      final List<LittleFisherScenario> courses =
          List<LittleFisherScenario>.generate(
            LittleFisherScenario.maximumLevels,
            (int index) => LittleFisherScenario.forLevel(index + 1),
          );
      expect(
        courses.map((LittleFisherScenario course) => course.fishCount),
        orderedEquals(List<int>.generate(10, (int index) => index + 5)),
      );
      expect(
        courses.every(
          (LittleFisherScenario course) =>
              course.fish.first.preferredBait == 0 &&
              course.fish.first.preferredDepth == 1,
        ),
        isTrue,
      );
      expect(courses[6].currentGust, greaterThan(courses[5].currentGust));
      expect(
        courses[9].fish.first.stamina,
        greaterThan(courses[0].fish.first.stamina),
      );
      expect(courses[9].missLimit, 1);
      expect(courses[9].maxLineSeconds, lessThan(courses[6].maxLineSeconds));
    },
  );

  test('first 300 practice schools differ from campaign and each other', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= LittleFisherScenario.maximumLevels; level++)
        LittleFisherScenario.forLevel(level).signature,
    };
    for (
      int round = 1;
      round <= LittleFisherScenario.maximumPracticeRounds;
      round++
    ) {
      final LittleFisherScenario course = LittleFisherScenario.forPracticeRound(
        round,
      );
      expect(
        signatures.add(course.signature),
        isTrue,
        reason: 'round $round repeats',
      );
      expect(
        course.fish.every(
          (FishPlan fish) =>
              fish.preferredBait >= 0 &&
              fish.preferredBait < 3 &&
              fish.preferredDepth >= 0 &&
              fish.preferredDepth < 3,
        ),
        isTrue,
      );
    }
    expect(signatures, hasLength(310));
  });

  test('course and practice index limits are checked', () {
    expect(() => LittleFisherScenario.forLevel(0), throwsRangeError);
    expect(() => LittleFisherScenario.forLevel(11), throwsRangeError);
    expect(() => LittleFisherScenario.forPracticeRound(0), throwsRangeError);
    expect(() => LittleFisherScenario.forPracticeRound(301), throwsRangeError);
  });
}
