import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/bottle_target/bottle_target_scenario.dart';

bool _hasClearShot(BottleTargetScenario scenario, BottleSpec target) {
  for (int degrees = -155; degrees <= -25; degrees++) {
    final double angle = degrees * math.pi / 180;
    for (int powerStep = 0; powerStep <= 34; powerStep++) {
      final double power = .74 + powerStep * .02;
      for (int frame = 1; frame <= 240; frame++) {
        final double time = frame / 120;
        final double x = .5 + math.cos(angle) * power * time;
        final double y =
            .88 +
            math.sin(angle) * power * time +
            .5 * scenario.gravity * time * time;
        if (x < .075 || x > .925 || y > .96 || y < .035) break;

        final double dx = x - target.x;
        final double dy = y - target.y;
        if (dx * dx + dy * dy <= math.pow(target.radius + .018, 2)) {
          return true;
        }

        final bool hitNeutral = scenario.bottles.any((BottleSpec bottle) {
          if (bottle.kind != BottleKind.neutral) return false;
          final double nx = x - bottle.x;
          final double ny = y - bottle.y;
          return nx * nx + ny * ny <= math.pow(bottle.radius + .018, 2);
        });
        final bool blocked = scenario.obstacles.any((RangeObstacleSpec item) {
          return (x - item.x).abs() <= item.width / 2 + .015 &&
              (y - item.y).abs() <= item.height / 2 + .015;
        });
        if (hitNeutral || blocked) break;
      }
    }
  }
  return false;
}

void main() {
  group('Bottle Target content certificate', () {
    test('10 campaign ranges are distinct, feasible and scale their skill', () {
      final Set<String> signatures = <String>{};
      BottleTargetScenario? previous;
      for (
        int level = 1;
        level <= BottleTargetScenario.maximumLevels;
        level++
      ) {
        final BottleTargetScenario scenario = BottleTargetScenario.forLevel(
          level,
        );
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(scenario.targetCount, greaterThan(0));
        expect(scenario.shots, greaterThanOrEqualTo(scenario.targetCount));
        expect(
          scenario.bottles.every(
            (BottleSpec bottle) => bottle.x > .1 && bottle.x < .9,
          ),
          isTrue,
        );
        for (final BottleSpec target in scenario.bottles.where(
          (BottleSpec bottle) => bottle.kind == BottleKind.target,
        )) {
          expect(
            _hasClearShot(scenario, target),
            isTrue,
            reason: 'level $level target ${target.signature} must be reachable',
          );
        }
        if (previous != null) {
          expect(scenario.gravity, greaterThan(previous.gravity));
          expect(scenario.shots, greaterThanOrEqualTo(previous.shots));
        }
        if (level == 1) expect(scenario.obstacles, isEmpty);
        if (level == 7) expect(scenario.obstacles, hasLength(2));
        if (level == 10) {
          expect(scenario.targetCount, 4);
          expect(scenario.wallBanking, isTrue);
          expect(
            scenario.bottles
                .where((BottleSpec bottle) => bottle.kind == BottleKind.target)
                .where((BottleSpec bottle) => bottle.y < .55),
            hasLength(2),
          );
          expect(
            scenario.bottles
                .where((BottleSpec bottle) => bottle.kind == BottleKind.target)
                .where((BottleSpec bottle) => bottle.y > .60),
            hasLength(2),
          );
        }
        previous = scenario;
      }
    });

    test('first 300 practice ranges do not repeat campaign or one another', () {
      final Set<String> signatures = <String>{
        for (
          int level = 1;
          level <= BottleTargetScenario.maximumLevels;
          level++
        )
          BottleTargetScenario.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= BottleTargetScenario.maximumPracticeRounds;
        index++
      ) {
        expect(
          signatures.add(
            BottleTargetScenario.forPracticeRound(index).signature,
          ),
          isTrue,
          reason: 'practice range $index',
        );
      }
    });

    test('invalid campaign and practice indices are rejected', () {
      expect(() => BottleTargetScenario.forLevel(0), throwsRangeError);
      expect(
        () => BottleTargetScenario.forPracticeRound(
          BottleTargetScenario.maximumPracticeRounds + 1,
        ),
        throwsRangeError,
      );
    });
  });
}
