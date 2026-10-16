import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/paper_flight/paper_flight_scenario.dart';

void main() {
  test(
    'ten routes layer more hoops, crosswind and a narrower landing flare',
    () {
      final List<PaperFlightScenario> courses =
          List<PaperFlightScenario>.generate(
            PaperFlightScenario.maximumLevels,
            (int index) => PaperFlightScenario.forLevel(index + 1),
          );
      expect(
        courses.map((PaperFlightScenario course) => course.gates.length),
        orderedEquals(List<int>.generate(10, (int index) => index + 3)),
      );
      expect(courses.first.windGust, 0);
      expect(courses[6].thermals, isNotEmpty);
      expect(courses[9].missLimit, 1);
      expect(
        courses[9].gates.last.width,
        lessThan(courses[0].gates.last.width),
      );
      expect(
        courses.every(
          (PaperFlightScenario course) => course.gates.every(
            (FlightGate gate) =>
                gate.centerX - gate.drift - gate.width / 2 > .16 &&
                gate.centerX + gate.drift + gate.width / 2 < .84,
          ),
        ),
        isTrue,
      );
    },
  );

  test('first 300 flight plans differ from campaign and each other', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= PaperFlightScenario.maximumLevels; level++)
        PaperFlightScenario.forLevel(level).signature,
    };
    for (
      int round = 1;
      round <= PaperFlightScenario.maximumPracticeRounds;
      round++
    ) {
      final PaperFlightScenario course = PaperFlightScenario.forPracticeRound(
        round,
      );
      expect(
        signatures.add(course.signature),
        isTrue,
        reason: 'round $round repeats',
      );
      expect(course.gates.length, greaterThanOrEqualTo(3));
      expect(course.landing.width, greaterThanOrEqualTo(.2));
    }
    expect(signatures, hasLength(310));
  });

  test('campaign and practice indexes are checked', () {
    expect(() => PaperFlightScenario.forLevel(0), throwsRangeError);
    expect(() => PaperFlightScenario.forLevel(11), throwsRangeError);
    expect(() => PaperFlightScenario.forPracticeRound(0), throwsRangeError);
    expect(() => PaperFlightScenario.forPracticeRound(301), throwsRangeError);
  });
}
