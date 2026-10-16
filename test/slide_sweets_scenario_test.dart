import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_scenario.dart';

void main() {
  test('campaign has ten waves and a deliberate expert finale', () {
    final List<SlideSweetsScenario> levels = List<SlideSweetsScenario>.generate(
      SlideSweetsScenario.maximumLevels,
      (int index) => SlideSweetsScenario.forLevel(index + 1),
    );

    expect(
      levels.map((SlideSweetsScenario wave) => wave.orderCount),
      orderedEquals(List<int>.generate(10, (int index) => index + 8)),
    );
    expect(
      levels.every(
        (SlideSweetsScenario wave) => wave.orders.take(3).toSet().length == 3,
      ),
      isTrue,
    );
    expect(levels[6].beltSpeed, greaterThan(levels[5].beltSpeed));
    expect(levels[7].spawnInterval, lessThan(levels[6].spawnInterval));
    expect(levels[9].bufferCapacity, lessThan(levels[8].bufferCapacity));
    expect(levels[9].missLimit, 1);
    expect(levels[9].orderCount, 17);
    expect(
      levels.skip(6).every((SlideSweetsScenario wave) => wave.surgeEvery > 0),
      isTrue,
    );
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
    expect(signatures, hasLength(310));
  });

  test('level and practice boundaries are checked', () {
    expect(() => SlideSweetsScenario.forLevel(0), throwsRangeError);
    expect(() => SlideSweetsScenario.forLevel(11), throwsRangeError);
    expect(() => SlideSweetsScenario.forPracticeRound(0), throwsRangeError);
    expect(() => SlideSweetsScenario.forPracticeRound(301), throwsRangeError);
  });
}
