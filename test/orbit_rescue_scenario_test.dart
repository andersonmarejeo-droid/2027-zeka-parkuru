import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/orbit_rescue/orbit_rescue_scenario.dart';

void main() {
  test('campaign adds gravity bodies, gates and a guarded docking window', () {
    final List<OrbitRescueScenario> levels = <OrbitRescueScenario>[
      for (int level = 1; level <= OrbitRescueScenario.campaignLevels; level++)
        OrbitRescueScenario.forLevel(level),
    ];
    expect(levels.first.bodies, hasLength(3));
    expect(levels.last.gates, hasLength(9));
    expect(levels.first.gates.length, lessThan(levels.last.gates.length));
    expect(levels.first.fuelCapacity, greaterThan(levels.last.fuelCapacity));
    expect(levels.first.pulseLimit, greaterThan(levels.last.pulseLimit));
    expect(
      levels.first.gates.first.radius,
      greaterThan(levels.last.gates.first.radius),
    );
    expect(
      levels.first.gates.last.motionAmplitude,
      lessThan(levels.last.gates.last.motionAmplitude),
    );
    expect(levels.last.missLimit, 1);

    for (final OrbitRescueScenario level in levels) {
      expect(level.bodies, hasLength(3));
      expect(level.gates.last.docking, isTrue);
      expect(level.gates.last.x, .91);
      for (int index = 0; index < level.gates.length; index++) {
        final OrbitGate gate = level.gates[index];
        expect(gate.x, greaterThan(.1));
        expect(gate.x, lessThan(.96));
        expect(gate.y - gate.motionAmplitude - gate.radius, greaterThan(.15));
        expect(gate.y + gate.motionAmplitude + gate.radius, lessThan(.85));
        if (index > 0) expect(gate.x, greaterThan(level.gates[index - 1].x));
      }
      for (final OrbitBody body in level.bodies) {
        expect(body.x, inInclusiveRange(.27, .78));
        expect(body.y, inInclusiveRange(.19, .81));
        expect(body.gravity, greaterThan(0));
      }
    }
  });

  test('first 300 practice orbits differ from campaign and one another', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= OrbitRescueScenario.campaignLevels; level++)
        OrbitRescueScenario.forLevel(level).signature,
    };
    for (int index = 1; index <= OrbitRescueScenario.practiceCourses; index++) {
      final OrbitRescueScenario orbit = OrbitRescueScenario.forPracticeCourse(
        index,
      );
      expect(
        signatures.add(orbit.signature),
        isTrue,
        reason: 'orbit $index repeats',
      );
    }
    expect(signatures, hasLength(310));
  });

  test('level and practice indexes reject out-of-range values', () {
    expect(() => OrbitRescueScenario.forLevel(0), throwsRangeError);
    expect(() => OrbitRescueScenario.forLevel(11), throwsRangeError);
    expect(() => OrbitRescueScenario.forPracticeCourse(0), throwsRangeError);
    expect(() => OrbitRescueScenario.forPracticeCourse(301), throwsRangeError);
  });
}
