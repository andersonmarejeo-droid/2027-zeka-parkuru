import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/museum_after_hours/museum_scenario.dart';

void main() {
  test('20 shifts increase patrol, artifact and laser pressure', () {
    final List<MuseumScenario> shifts = List<MuseumScenario>.generate(
      MuseumScenario.campaignLevels,
      (int index) => MuseumScenario.forLevel(index + 1),
    );
    expect(shifts.first.guards, hasLength(1));
    expect(shifts[7].guards, hasLength(2));
    expect(shifts.last.guards, hasLength(3));
    expect(shifts.first.lasers, isEmpty);
    expect(shifts.last.lasers, hasLength(3));
    expect(shifts.first.artifacts, hasLength(1));
    expect(shifts.last.artifacts, hasLength(3));
    for (final MuseumScenario scenario in shifts) {
      expect(scenario.shadows, contains(MuseumScenario.start));
      expect(scenario.shadows, contains(MuseumScenario.exit));
      expect(scenario.walls, isNot(contains(MuseumScenario.start)));
      expect(scenario.walls, isNot(contains(MuseumScenario.exit)));
      expect(scenario.walls, isNot(contains(scenario.lureTarget)));
    }
  });

  test('300 practice galleries are deterministic and unique', () {
    final Set<String> signatures = <String>{};
    for (int index = 1; index <= MuseumScenario.practiceMaps; index++) {
      final MuseumScenario scenario = MuseumScenario.forPracticeMap(index);
      expect(
        scenario.signature,
        MuseumScenario.forPracticeMap(index).signature,
      );
      expect(
        signatures.add(scenario.signature),
        isTrue,
        reason: 'map $index repeated',
      );
      expect(
        scenario.signature,
        isNot(MuseumScenario.forLevel(scenario.level).signature),
      );
    }
    expect(signatures, hasLength(MuseumScenario.practiceMaps));
  });

  test('scenario factories enforce campaign and practice limits', () {
    expect(() => MuseumScenario.forLevel(0), throwsRangeError);
    expect(() => MuseumScenario.forLevel(21), throwsRangeError);
    expect(() => MuseumScenario.forPracticeMap(0), throwsRangeError);
    expect(() => MuseumScenario.forPracticeMap(301), throwsRangeError);
  });
}
