import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/neon_pinball/neon_pinball_scenario.dart';

void main() {
  test('ten pinball tables grow target count and expert timing pressure', () {
    final List<NeonPinballScenario> tables = List<NeonPinballScenario>.generate(
      NeonPinballScenario.campaignLevels,
      (int index) => NeonPinballScenario.forLevel(index + 1),
    );
    expect(
      tables.map((NeonPinballScenario table) => table.targets.length),
      orderedEquals(List<int>.generate(10, (int index) => index + 3)),
    );
    expect(tables[0].hasLock, isFalse);
    expect(tables[8].hasLock, isTrue);
    expect(tables[8].totalBalls, 2);
    expect(tables[9].totalBalls, 2);
    expect(
      tables[9].comboWindowSeconds,
      lessThan(tables[0].comboWindowSeconds),
    );
    expect(
      tables[9].targets.last.radius,
      lessThan(tables[0].targets.last.radius),
    );
    expect(
      tables[6].targets.any((target) => target.driftX.abs() > .01),
      isTrue,
    );
  });

  test('first 300 practice tables differ from campaign and each other', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= NeonPinballScenario.campaignLevels; level++)
        NeonPinballScenario.forLevel(level).signature,
    };
    for (int round = 1; round <= NeonPinballScenario.practiceLayouts; round++) {
      final NeonPinballScenario table = NeonPinballScenario.forPracticeLayout(
        round,
      );
      expect(
        signatures.add(table.signature),
        isTrue,
        reason: 'round $round repeats',
      );
      expect(table.targets.length, greaterThanOrEqualTo(3));
      expect(table.targets.length, lessThanOrEqualTo(12));
      expect(table.bumpers.length, greaterThanOrEqualTo(2));
    }
    expect(signatures, hasLength(310));
  });

  test('campaign and practice bounds are validated', () {
    expect(() => NeonPinballScenario.forLevel(0), throwsRangeError);
    expect(() => NeonPinballScenario.forLevel(11), throwsRangeError);
    expect(() => NeonPinballScenario.forPracticeLayout(0), throwsRangeError);
    expect(() => NeonPinballScenario.forPracticeLayout(301), throwsRangeError);
  });
}
