import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/tower_balance/tower_balance_engine.dart';
import 'package:zeka_parkuru/games/tower_balance/tower_balance_scenario.dart';

void main() {
  group('Tower Balance content certificate', () {
    test('10 layouts climb in height, sway and balance precision', () {
      final Set<String> signatures = <String>{};
      TowerBalanceScenario? previous;
      for (
        int level = 1;
        level <= TowerBalanceScenario.maximumLevels;
        level++
      ) {
        final TowerBalanceScenario scenario = TowerBalanceScenario.forLevel(
          level,
        );
        expect(
          signatures.add(scenario.signature),
          isTrue,
          reason: 'level $level',
        );
        expect(scenario.pieces, hasLength(5 + level));
        expect(scenario.minimumOverlap, greaterThanOrEqualTo(.42));
        expect(scenario.balanceMargin, greaterThan(.1));
        if (previous != null) {
          expect(scenario.tiltAmplitude, greaterThan(previous.tiltAmplitude));
          expect(scenario.minimumOverlap, greaterThan(previous.minimumOverlap));
          expect(scenario.balanceMargin, lessThan(previous.balanceMargin));
        }
        if (level == 10) {
          expect(scenario.supportPins, 1);
          expect(scenario.mistakeLimit, 2);
        } else {
          expect(scenario.supportPins, 0);
        }
        previous = scenario;
      }
    });

    test('all campaign stacks have a stable calm-window placement route', () {
      for (
        int level = 1;
        level <= TowerBalanceScenario.maximumLevels;
        level++
      ) {
        final TowerBalanceScenario scenario = TowerBalanceScenario.forLevel(
          level,
        );
        final double calmTime =
            ((math.pi * 2 - scenario.phaseOffset) % (math.pi * 2)) /
            scenario.windFrequency;
        final List<TowerPlacedPiece> placed = <TowerPlacedPiece>[];
        for (final TowerPieceSpec piece in scenario.pieces) {
          final TowerPlacementAssessment assessment = TowerBalanceEngine.assess(
            scenario: scenario,
            placed: placed,
            incoming: piece,
            centerX: TowerBalanceEngine.pivotX,
            elapsedSeconds: calmTime,
          );
          expect(
            assessment.stable,
            isTrue,
            reason: 'level $level, step ${placed.length + 1}',
          );
          placed.add(
            TowerPlacedPiece(spec: piece, centerX: TowerBalanceEngine.pivotX),
          );
        }
      }
    });

    test('first 300 practice layouts never repeat campaign or each other', () {
      final Set<String> signatures = <String>{
        for (
          int level = 1;
          level <= TowerBalanceScenario.maximumLevels;
          level++
        )
          TowerBalanceScenario.forLevel(level).signature,
      };
      for (
        int index = 1;
        index <= TowerBalanceScenario.maximumPracticeRounds;
        index++
      ) {
        expect(
          signatures.add(
            TowerBalanceScenario.forPracticeRound(index).signature,
          ),
          isTrue,
          reason: 'tower layout $index',
        );
      }
    });

    test('invalid campaign and practice indices are rejected', () {
      expect(() => TowerBalanceScenario.forLevel(11), throwsRangeError);
      expect(() => TowerBalanceScenario.forPracticeRound(0), throwsRangeError);
    });
  });
}
