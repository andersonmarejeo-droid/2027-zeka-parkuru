import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/jetpack_courier/jetpack_courier_scenario.dart';

void main() {
  test('ten delivery routes add rings, wind and fragile final docks', () {
    final List<JetpackCourierScenario> levels =
        List<JetpackCourierScenario>.generate(
          JetpackCourierScenario.campaignLevels,
          (int index) => JetpackCourierScenario.forLevel(index + 1),
        );
    expect(
      levels.map((JetpackCourierScenario level) => level.checkpoints.length),
      orderedEquals(List<int>.generate(10, (int index) => index + 5)),
    );
    expect(levels.first.fuelCapacity, greaterThan(levels.last.fuelCapacity));
    expect(
      levels.first.packageTolerance,
      greaterThan(levels.last.packageTolerance),
    );
    expect(levels.last.missLimit, 1);
    expect(
      levels[5].checkpoints.any((CourierCheckpoint point) => point.coolantVent),
      isTrue,
    );
    expect(levels.last.checkpoints.last.deliveryDock, isTrue);
    for (final JetpackCourierScenario level in levels) {
      expect(level.checkpoints.last.centerAltitude, .24);
      for (final CourierCheckpoint point in level.checkpoints) {
        expect(point.centerX - point.halfWidth, greaterThan(.19));
        expect(point.centerX + point.halfWidth, lessThan(.81));
        expect(point.centerAltitude - point.halfHeight, greaterThan(.18));
        expect(point.centerAltitude + point.halfHeight, lessThan(.85));
      }
    }
  });

  test('first 300 practice flights differ from campaign and each other', () {
    final Set<String> signatures = <String>{
      for (
        int level = 1;
        level <= JetpackCourierScenario.campaignLevels;
        level++
      )
        JetpackCourierScenario.forLevel(level).signature,
    };
    for (
      int index = 1;
      index <= JetpackCourierScenario.practiceFlights;
      index++
    ) {
      final JetpackCourierScenario flight =
          JetpackCourierScenario.forPracticeFlight(index);
      expect(
        signatures.add(flight.signature),
        isTrue,
        reason: 'practice flight $index repeats',
      );
      expect(flight.checkpoints, isNotEmpty);
    }
    expect(signatures, hasLength(310));
  });

  test('level and practice indexes reject out-of-range values', () {
    expect(() => JetpackCourierScenario.forLevel(0), throwsRangeError);
    expect(() => JetpackCourierScenario.forLevel(11), throwsRangeError);
    expect(() => JetpackCourierScenario.forPracticeFlight(0), throwsRangeError);
    expect(
      () => JetpackCourierScenario.forPracticeFlight(301),
      throwsRangeError,
    );
  });
}
