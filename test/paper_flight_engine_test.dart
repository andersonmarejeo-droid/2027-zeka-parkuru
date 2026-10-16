import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/paper_flight/paper_flight_engine.dart';
import 'package:zeka_parkuru/games/paper_flight/paper_flight_scenario.dart';

void main() {
  test('bank and pitch steer a real crossing through the first hoop', () {
    final PaperFlightScenario course = PaperFlightScenario.forLevel(1);
    final PaperFlightEngine engine = PaperFlightEngine(scenario: course);
    final FlightGate gate = course.gates.first;
    engine.plane
      ..distance = gate.distance - .0008
      ..x = gate.centerX
      ..altitude = gate.altitude;
    engine.setControl(bank: 0, pitch: 0);
    final FlightStepResult result = engine.step(.024);
    expect(result.gatePassed, isTrue);
    expect(engine.nextGate, 1);
    expect(engine.misses, 0);
  });

  test('a missed hoop is recorded once and advances to the next gate', () {
    final PaperFlightScenario course = PaperFlightScenario.forLevel(2);
    final PaperFlightEngine engine = PaperFlightEngine(scenario: course);
    final FlightGate gate = course.gates.first;
    engine.plane
      ..distance = gate.distance - .0008
      ..x = .92
      ..altitude = gate.altitude;
    final FlightStepResult result = engine.step(.024);
    expect(result.gateMissed, isTrue);
    expect(engine.nextGate, 1);
    expect(engine.misses, 1);
    for (int frame = 0; frame < 20; frame++) {
      engine.step(.024);
    }
    expect(engine.misses, 1);
  });

  test('a thermal restores climb and a controlled flare lands the plane', () {
    final PaperFlightScenario course = PaperFlightScenario.forLevel(6);
    final PaperFlightEngine engine = PaperFlightEngine(scenario: course);
    final FlightThermal thermal = course.thermals.first;
    engine.plane
      ..distance = thermal.distance - .0004
      ..x = thermal.centerX
      ..climbRate = -.04;
    final FlightStepResult lift = engine.step(.024);
    expect(lift.enteredThermal, isTrue);
    expect(engine.thermalsUsed, 1);

    engine
      ..nextGate = course.gates.length
      ..plane.distance = .999
      ..plane.x = course.landing.centerX
      ..plane.altitude = course.landing.altitude
      ..plane.climbRate = 0;
    final FlightStepResult landing = engine.step(.024);
    expect(landing.landed, isTrue);
    expect(engine.isLanded, isTrue);
  });

  test('low altitude is an explicit crash state', () {
    final PaperFlightEngine engine = PaperFlightEngine(
      scenario: PaperFlightScenario.forLevel(3),
    );
    engine.plane.altitude = .14;
    final FlightStepResult result = engine.step(.024);
    expect(result.crashed, isTrue);
    expect(engine.isCrashed, isTrue);
  });
}
