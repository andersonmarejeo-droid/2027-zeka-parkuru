import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/snowboard_slalom/snowboard_slalom_scenario.dart';

void main() {
  test('ten snow runs add gates, ice and mogul speed management', () {
    final List<SnowboardSlalomScenario> levels =
        List<SnowboardSlalomScenario>.generate(
          SnowboardSlalomScenario.campaignLevels,
          (int index) => SnowboardSlalomScenario.forLevel(index + 1),
        );
    expect(
      levels.map((SnowboardSlalomScenario level) => level.gates.length),
      orderedEquals(List<int>.generate(10, (int index) => index + 6)),
    );
    expect(
      levels.first.gates.every(
        (SnowGate gate) =>
            gate.surface == SnowSurface.packed ||
            gate.surface == SnowSurface.powder,
      ),
      isTrue,
    );
    expect(
      levels[6].gates.any((SnowGate gate) => gate.surface == SnowSurface.ice),
      isTrue,
    );
    expect(
      levels.last.gates.any(
        (SnowGate gate) => gate.surface == SnowSurface.moguls,
      ),
      isTrue,
    );
    expect(
      levels.last.gates.first.width,
      lessThan(levels.first.gates.first.width),
    );
    expect(levels.last.missLimit, 1);
    for (final SnowboardSlalomScenario level in levels) {
      for (final SnowGate gate in level.gates) {
        expect(gate.centerX - gate.width / 2, greaterThan(.12));
        expect(gate.centerX + gate.width / 2, lessThan(.88));
      }
    }
  });

  test('first 300 practice courses differ from campaign and each other', () {
    final Set<String> signatures = <String>{
      for (
        int level = 1;
        level <= SnowboardSlalomScenario.campaignLevels;
        level++
      )
        SnowboardSlalomScenario.forLevel(level).signature,
    };
    for (
      int index = 1;
      index <= SnowboardSlalomScenario.practiceCourses;
      index++
    ) {
      final SnowboardSlalomScenario course =
          SnowboardSlalomScenario.forPracticeCourse(index);
      expect(
        signatures.add(course.signature),
        isTrue,
        reason: 'practice course $index repeats',
      );
      expect(course.gates, isNotEmpty);
    }
    expect(signatures, hasLength(310));
  });

  test('invalid level and practice indexes are rejected', () {
    expect(() => SnowboardSlalomScenario.forLevel(0), throwsRangeError);
    expect(() => SnowboardSlalomScenario.forLevel(11), throwsRangeError);
    expect(
      () => SnowboardSlalomScenario.forPracticeCourse(0),
      throwsRangeError,
    );
    expect(
      () => SnowboardSlalomScenario.forPracticeCourse(301),
      throwsRangeError,
    );
  });
}
