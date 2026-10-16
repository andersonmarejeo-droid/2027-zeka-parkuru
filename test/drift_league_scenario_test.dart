import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/drift_league/drift_league_scenario.dart';

void main() {
  test('20 campaign tracks widen their mastery curve', () {
    final List<DriftLeagueScenario> routes = List<DriftLeagueScenario>.generate(
      DriftLeagueScenario.campaignLevels,
      (int index) => DriftLeagueScenario.forLevel(index + 1),
    );

    expect(routes, hasLength(20));
    expect(routes.first.checkpointCount, 4);
    expect(routes[6].checkpointCount, 5);
    expect(routes[8].checkpointRadius, lessThan(routes.first.checkpointRadius));
    expect(routes[16].checkpointCount, 8);
    expect(
      routes.last.targetDriftScore,
      greaterThan(routes.first.targetDriftScore),
    );
    expect(
      routes.last.maximumRecoveries,
      lessThan(routes.first.maximumRecoveries),
    );
    expect(routes.last.trackWidth, lessThan(routes.first.trackWidth));
    expect(
      routes.every(
        (DriftLeagueScenario route) =>
            route.centerline.length >= 80 &&
            route.centerline.every(
              (point) =>
                  point.dx > .10 &&
                  point.dx < .90 &&
                  point.dy > .10 &&
                  point.dy < .90,
            ),
      ),
      isTrue,
    );
  });

  test(
    'first 300 practice circuits are distinct from campaign and each other',
    () {
      final Set<String> signatures = <String>{
        for (
          int level = 1;
          level <= DriftLeagueScenario.campaignLevels;
          level++
        )
          DriftLeagueScenario.forLevel(level).signature,
      };

      for (
        int index = 1;
        index <= DriftLeagueScenario.practiceRoutes;
        index++
      ) {
        final DriftLeagueScenario route = DriftLeagueScenario.forPracticeRoute(
          index,
        );
        expect(
          signatures.add(route.signature),
          isTrue,
          reason: 'practice circuit $index repeated',
        );
        expect(route.centerline, hasLength(96));
        expect(route.checkpointCount, inInclusiveRange(4, 8));
      }
      expect(signatures, hasLength(320));
    },
  );

  test('campaign and practice indexes enforce their bounds', () {
    expect(() => DriftLeagueScenario.forLevel(0), throwsRangeError);
    expect(() => DriftLeagueScenario.forLevel(21), throwsRangeError);
    expect(() => DriftLeagueScenario.forPracticeRoute(0), throwsRangeError);
    expect(() => DriftLeagueScenario.forPracticeRoute(301), throwsRangeError);
  });
}
