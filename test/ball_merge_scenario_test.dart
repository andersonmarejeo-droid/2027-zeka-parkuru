import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/ball_merge/ball_merge_scenario.dart';

void main() {
  group('Ball Merge content certificate', () {
    test('10 campaign chambers increase pressure and remain playable', () {
      final Set<String> signatures = <String>{};
      BallMergeScenario? previous;
      for (int level = 1; level <= BallMergeScenario.maximumLevels; level++) {
        final BallMergeScenario scenario = BallMergeScenario.forLevel(level);
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(scenario.queue, hasLength(scenario.dropLimit));
        expect(scenario.mergeGoal, 2 + level);
        expect(scenario.maxTier, 2 + level ~/ 2);
        expect(scenario.queue.toSet().length, greaterThanOrEqualTo(3));
        expect(
          scenario.queue.every(
            (int tier) => tier >= 0 && tier <= scenario.maxTier,
          ),
          isTrue,
        );
        if (previous != null) {
          expect(scenario.gravity, greaterThan(previous.gravity));
          expect(scenario.flux, greaterThanOrEqualTo(previous.flux));
          expect(scenario.dropLimit, greaterThan(previous.dropLimit));
        }
        if (level >= 7) {
          expect(scenario.flux, greaterThan(.4));
          expect(scenario.queue.toSet(), contains(scenario.maxTier));
          expect(
            scenario.queue.where((int tier) => tier == scenario.maxTier).length,
            greaterThanOrEqualTo(2),
          );
        }
        if (level >= 9) expect(scenario.mergeGoal, greaterThanOrEqualTo(11));
        previous = scenario;
      }
    });

    test('first 300 practice queues never repeat campaign or one another', () {
      final Set<String> signatures = <String>{
        for (int level = 1; level <= BallMergeScenario.maximumLevels; level++)
          BallMergeScenario.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= BallMergeScenario.maximumPracticeRounds;
        index++
      ) {
        expect(
          signatures.add(BallMergeScenario.forPracticeRound(index).signature),
          isTrue,
          reason: 'merge queue $index',
        );
      }
    });

    test('generation is deterministic and rejects out-of-range requests', () {
      expect(
        BallMergeScenario.forLevel(10).signature,
        BallMergeScenario.forLevel(10).signature,
      );
      expect(() => BallMergeScenario.forLevel(0), throwsRangeError);
      expect(
        () => BallMergeScenario.forPracticeRound(
          BallMergeScenario.maximumPracticeRounds + 1,
        ),
        throwsRangeError,
      );
    });
  });
}
