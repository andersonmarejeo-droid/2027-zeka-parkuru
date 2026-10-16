import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/marble_route/marble_route_engine.dart';
import 'package:zeka_parkuru/games/marble_route/marble_route_scenario.dart';

void main() {
  test('measured tilt carries the marble through a real open gate', () {
    final MarbleRouteEngine engine = MarbleRouteEngine(
      scenario: MarbleRouteScenario.forLevel(1),
    );
    engine.setTilt(0, -.52);
    MarbleStepResult event = const MarbleStepResult();
    for (int frame = 0; frame < 1500 && engine.nextGate == 0; frame++) {
      event = engine.step(.016);
    }
    expect(event.gatePassed, isTrue);
    expect(engine.nextGate, 1);
    expect(engine.misses, 0);
    expect(
      engine.marble.y,
      lessThan(MarbleRouteScenario.forLevel(1).gates.single.y),
    );
  });

  test('a missed aperture bounces the ball and preserves gate order', () {
    final MarbleRouteScenario course = MarbleRouteScenario.forLevel(1);
    final MarbleRouteEngine engine = MarbleRouteEngine(scenario: course);
    engine.marble
      ..x = .89
      ..y = course.start.y;
    engine.setTilt(0, -1);
    MarbleStepResult event = const MarbleStepResult();
    for (int frame = 0; frame < 900 && !event.gateBounced; frame++) {
      event = engine.step(.016);
    }
    expect(event.gateBounced, isTrue);
    expect(engine.nextGate, 0);
    expect(engine.misses, 0);
  });

  test('a side-pocket fall returns to the saved checkpoint', () {
    final MarbleRouteScenario course = MarbleRouteScenario.forLevel(7);
    final MarbleRouteEngine engine = MarbleRouteEngine(scenario: course);
    final MarblePit pit = course.pits.first;
    engine.marble
      ..x = pit.center.x
      ..y = pit.center.y;
    final MarbleStepResult event = engine.step(.016);
    expect(event.fell, isTrue);
    expect(engine.misses, 1);
    expect(engine.marble.x, course.start.x);
    expect(engine.marble.y, course.start.y);
  });

  test('bumpers produce a physical bank without changing route order', () {
    final MarbleRouteScenario course = MarbleRouteScenario.forLevel(10);
    final MarbleRouteEngine engine = MarbleRouteEngine(scenario: course);
    final MarbleBumper bumper = course.bumpers.first;
    engine.marble
      ..x = bumper.center.x
      ..y = bumper.center.y;
    final MarbleStepResult event = engine.step(.016);
    expect(event.bumperHit, isTrue);
    expect(engine.bumpHits, 1);
    expect(engine.nextGate, 0);
  });
}
