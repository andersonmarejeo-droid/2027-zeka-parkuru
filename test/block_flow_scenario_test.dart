import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/block_flow/block_flow_scenario.dart';

void main() {
  test(
    'ten campaigns teach lanes then add rifts, stacked rails and counterflow',
    () {
      final List<BlockFlowScenario> runs = List<BlockFlowScenario>.generate(
        BlockFlowScenario.maximumLevels,
        (int index) => BlockFlowScenario.forLevel(index + 1),
      );
      expect(runs.first.dualDeck, isFalse);
      expect(runs[2].dualDeck, isFalse);
      expect(runs[3].dualDeck, isTrue);
      expect(runs[6].rows.any((BlockFlowRow row) => row.counterflow), isTrue);
      expect(runs[9].rowCount, 31);
      expect(runs[9].missLimit, 1);
      expect(
        runs.every((BlockFlowScenario run) => run.hasVerifiedRoute),
        isTrue,
      );
      expect(
        runs.every((BlockFlowScenario run) => run.rows.length >= 13),
        isTrue,
      );
    },
  );

  test('first 300 practice corridors are distinct and solver-certified', () {
    final Set<String> signatures = <String>{
      for (int level = 1; level <= BlockFlowScenario.maximumLevels; level++)
        BlockFlowScenario.forLevel(level).signature,
    };
    for (
      int round = 1;
      round <= BlockFlowScenario.maximumPracticeRounds;
      round++
    ) {
      final BlockFlowScenario run = BlockFlowScenario.forPracticeRound(round);
      expect(
        signatures.add(run.signature),
        isTrue,
        reason: 'round $round repeats',
      );
      expect(
        run.hasVerifiedRoute,
        isTrue,
        reason: 'round $round is not solvable',
      );
    }
    expect(signatures, hasLength(310));
  });

  test('campaign and practice index bounds are explicit', () {
    expect(() => BlockFlowScenario.forLevel(0), throwsRangeError);
    expect(() => BlockFlowScenario.forLevel(11), throwsRangeError);
    expect(() => BlockFlowScenario.forPracticeRound(0), throwsRangeError);
    expect(() => BlockFlowScenario.forPracticeRound(301), throwsRangeError);
  });
}
