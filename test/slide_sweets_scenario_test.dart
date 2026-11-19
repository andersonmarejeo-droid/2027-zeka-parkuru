import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_scenario.dart';

void main() {
  test('campaign has twenty waves with single gate first 10 and dual gates after', () {
    final List<SlideSweetsScenario> levels = List<SlideSweetsScenario>.generate(
      SlideSweetsScenario.maximumLevels,
      (int index) => SlideSweetsScenario.forLevel(index + 1),
    );

    expect(
      levels.take(10).every((SlideSweetsScenario wave) => wave.gateCount == 1),
      isTrue,
    );
    expect(
      levels.skip(10).every((SlideSweetsScenario wave) => wave.gateCount == 2),
      isTrue,
    );
    expect(
      levels.map((SlideSweetsScenario wave) => wave.orderCount),
      orderedEquals(List<int>.generate(20, (int index) => index + 8)),
    );
    expect(
      levels.every(
        (SlideSweetsScenario wave) => wave.orders.take(3).toSet().length == 3,
      ),
      isTrue,
    );
    expect(levels[19].missLimit, 1);
    expect(levels[19].orderCount, 27);
  });

  test('first 300 practice waves do not repeat each other or campaign', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= SlideSweetsScenario.maximumLevels; level++)
        SlideSweetsScenario.forLevel(level).signature,
    };
    for (
      int index = 1;
      index <= SlideSweetsScenario.maximumPracticeRounds;
      index++
    ) {
      final SlideSweetsScenario wave = SlideSweetsScenario.forPracticeRound(
        index,
      );
      expect(
        signatures.add(wave.signature),
        isTrue,
        reason: 'round $index repeats',
      );
      expect(wave.orders.every((int lane) => lane >= 0 && lane <= 2), isTrue);
    }
    expect(signatures, hasLength(320));
  });

  test('level and practice boundaries are checked', () {
    expect(() => SlideSweetsScenario.forLevel(0), throwsRangeError);
    expect(() => SlideSweetsScenario.forLevel(21), throwsRangeError);
    expect(() => SlideSweetsScenario.forPracticeRound(0), throwsRangeError);
    expect(() => SlideSweetsScenario.forPracticeRound(301), throwsRangeError);
  });
}
