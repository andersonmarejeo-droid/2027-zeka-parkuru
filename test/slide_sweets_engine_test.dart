import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_engine.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_scenario.dart';

void main() {
  test('two diverters route successive colour orders into the right lanes', () {
    final SlideSweetsScenario wave = SlideSweetsScenario.forLevel(1);
    final SlideSweetsEngine engine = SlideSweetsEngine(scenario: wave);
    expect(engine.setDiverter(0, 0), isTrue);
    expect(engine.setDiverter(1, -1), isTrue);

    for (int frame = 0; frame < 43; frame++) {
      engine.step(.05);
    }
    // The berry has cleared gate two; the following honey order must keep the
    // centre exit straight through that same switch.
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
      expect(engine.setDiverter(2, 0), isFalse);
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
