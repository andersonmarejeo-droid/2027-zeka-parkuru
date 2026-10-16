import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/skate_combo/skate_combo_scenario.dart';

void main() {
  test('ten routes add ramps, rotations and a tighter landing window', () {
    final List<SkateComboScenario> routes = List<SkateComboScenario>.generate(
      SkateComboScenario.campaignLevels,
      (int index) => SkateComboScenario.forLevel(index + 1),
    );
    expect(
      routes.map((SkateComboScenario route) => route.jumps.length),
      orderedEquals(<int>[4, 4, 5, 5, 6, 6, 7, 7, 8, 8]),
    );
    expect(routes.first.jumps.last.targetRotation, lessThanOrEqualTo(540));
    expect(routes[6].jumps.first.targetRotation, greaterThanOrEqualTo(720));
    expect(routes.last.jumps.last.targetRotation, 1440);
    expect(
      routes.last.jumps.last.airtimeSeconds,
      lessThan(routes.first.jumps.first.airtimeSeconds),
    );
    expect(
      routes.last.jumps.last.balanceTolerance,
      lessThan(routes.first.jumps.first.balanceTolerance),
    );
    expect(routes.last.missLimit, 1);
    expect(
      routes.every(
        (SkateComboScenario route) => route.jumps.every(
          (SkateJump jump) =>
              jump.minimumSpeed > .4 &&
              jump.minimumSpeed < 1 &&
              jump.balanceTolerance >= .105 &&
              jump.rotationTolerance >= 55,
        ),
      ),
      isTrue,
    );
  });

  test(
    'first 300 seeded practice routes differ from campaign and each other',
    () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= SkateComboScenario.campaignLevels; level++)
          SkateComboScenario.forLevel(level).signature,
      };
      for (int index = 1; index <= SkateComboScenario.practiceRoutes; index++) {
        final SkateComboScenario route = SkateComboScenario.forPracticeRoute(
          index,
        );
        expect(
          signatures.add(route.signature),
          isTrue,
          reason: 'practice route $index repeats',
        );
        expect(route.jumps, isNotEmpty);
        for (int i = 1; i < route.jumps.length; i++) {
          expect(
            route.jumps[i].takeoffSeconds,
            greaterThan(route.jumps[i - 1].landingSeconds),
          );
        }
      }
      expect(signatures, hasLength(310));
    },
  );

  test('campaign and practice indexes reject invalid bounds', () {
    expect(() => SkateComboScenario.forLevel(0), throwsRangeError);
    expect(() => SkateComboScenario.forLevel(11), throwsRangeError);
    expect(() => SkateComboScenario.forPracticeRoute(0), throwsRangeError);
    expect(() => SkateComboScenario.forPracticeRoute(301), throwsRangeError);
  });
}
