import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_engine.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_scenario.dart';

void main() {
  test('single diverter in early levels routes successive colour orders into lanes', () {
    final SlideSweetsScenario wave = SlideSweetsScenario.forLevel(1);
    expect(wave.gateCount, 1);
    final SlideSweetsEngine engine = SlideSweetsEngine(scenario: wave);
    expect(engine.gateCount, 1);
    // Order 0 is lane 0 (Gül / top) -> set diverter 0 to -1 (ÜST)
    expect(engine.setDiverter(0, -1), isTrue);

    for (int frame = 0; frame < 38; frame++) {
      engine.step(.05);
    }
    // Following order is lane 1 (Bal / middle) -> set diverter 0 to 0 (ORTA)
    expect(engine.setDiverter(0, 0), isTrue);
    for (int frame = 0; frame < 200 && engine.deliveredCount < 2; frame++) {
      engine.step(.05);
    }

    expect(engine.deliveredCount, 2);
    expect(engine.missedCount, 0);
    expect(engine.isComplete, isFalse);
  });

  test('two diverters in level 11+ route successive colour orders into the right lanes', () {
    final SlideSweetsScenario wave = SlideSweetsScenario.forLevel(11);
    expect(wave.gateCount, 2);
    final SlideSweetsEngine engine = SlideSweetsEngine(scenario: wave);
    expect(engine.gateCount, 2);
    expect(engine.setDiverter(0, 0), isTrue);
    expect(engine.setDiverter(1, -1), isTrue);

    for (int frame = 0; frame < 43; frame++) {
      engine.step(.05);
    }
    expect(engine.setDiverter(1, 0), isTrue);
    for (int frame = 0; frame < 200 && engine.deliveredCount < 2; frame++) {
      engine.step(.05);
    }

    expect(engine.deliveredCount, 2);
    expect(engine.missedCount, 0);
    expect(engine.isComplete, isFalse);
  });

  test(
    'invalid diverter controls and order indices cannot corrupt the line',
    () {
      final SlideSweetsEngine engine = SlideSweetsEngine(
        scenario: SlideSweetsScenario.forLevel(4),
      );
      expect(engine.setDiverter(-1, 0), isFalse);
      expect(engine.setDiverter(1, 0), isFalse); // Only 1 gate in level 4
      expect(engine.setDiverter(0, 2), isFalse);
      expect(() => engine.laneForOrder(-1), throwsRangeError);
      expect(() => engine.laneForOrder(99), throwsRangeError);
      expect(engine.activeSweets, isEmpty);
      expect(engine.queuedCount, engine.scenario.orderCount);
    },
  );

  test('long frames are bounded and the same seed plays deterministically', () {
    SlideSweetsEngine create() =>
        SlideSweetsEngine(scenario: SlideSweetsScenario.forLevel(10));
    final SlideSweetsEngine first = create();
    final SlideSweetsEngine second = create();
    for (int frame = 0; frame < 20; frame++) {
      first.step(10);
      second.step(.05);
    }
    expect(first.elapsedSeconds, closeTo(1, .0001));
    expect(first.nextOrderIndex, second.nextOrderIndex);
    expect(
      first.activeSweets.single.progress,
      second.activeSweets.single.progress,
    );
  });
}
