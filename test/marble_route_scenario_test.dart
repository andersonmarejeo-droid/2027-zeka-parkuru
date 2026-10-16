import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/marble_route/marble_route_scenario.dart';

void main() {
  test('ten routes add gates, moving apertures and expert hazard layers', () {
    final List<MarbleRouteScenario> courses =
        List<MarbleRouteScenario>.generate(
          MarbleRouteScenario.maximumLevels,
          (int index) => MarbleRouteScenario.forLevel(index + 1),
        );
    expect(
      courses.map((MarbleRouteScenario course) => course.gates.length),
      orderedEquals(<int>[1, 1, 2, 2, 2, 3, 3, 3, 4, 5]),
    );
    expect(courses[0].gates.single.amplitude, 0);
    expect(courses[6].pits, isNotEmpty);
    expect(courses[9].pits, hasLength(2));
    expect(courses[9].missLimit, 1);
    expect(
      courses[9].gates.last.width,
      lessThan(courses[0].gates.single.width),
    );
    expect(
      courses[9].gates.every(
        (MarbleGate gate) =>
            gate.center - gate.amplitude > .17 &&
            gate.center + gate.amplitude < .83,
      ),
      isTrue,
    );
  });

  test('first 300 replay boards differ from campaign and each other', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= MarbleRouteScenario.maximumLevels; level++)
        MarbleRouteScenario.forLevel(level).signature,
    };
    for (
      int round = 1;
      round <= MarbleRouteScenario.maximumPracticeRounds;
      round++
    ) {
      final MarbleRouteScenario course = MarbleRouteScenario.forPracticeRound(
        round,
      );
      expect(
        signatures.add(course.signature),
        isTrue,
        reason: 'round $round repeats',
      );
      expect(course.gates, isNotEmpty);
    }
    expect(signatures, hasLength(310));
  });

  test('course and practice indexes stay inside the contract', () {
    expect(() => MarbleRouteScenario.forLevel(0), throwsRangeError);
    expect(() => MarbleRouteScenario.forLevel(11), throwsRangeError);
    expect(() => MarbleRouteScenario.forPracticeRound(0), throwsRangeError);
    expect(() => MarbleRouteScenario.forPracticeRound(301), throwsRangeError);
  });
}
