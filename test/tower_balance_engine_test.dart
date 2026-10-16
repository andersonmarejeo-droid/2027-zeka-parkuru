import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/tower_balance/tower_balance_engine.dart';
import 'package:zeka_parkuru/games/tower_balance/tower_balance_scenario.dart';

void main() {
  group('Tower balance moments', () {
    test('a centered piece fits its support in the calm phase', () {
      final TowerBalanceScenario scenario = TowerBalanceScenario.forLevel(4);
      final double calmTime =
          ((6.283185307179586 - scenario.phaseOffset) % 6.283185307179586) /
          scenario.windFrequency;
      final TowerPlacementAssessment result = TowerBalanceEngine.assess(
        scenario: scenario,
        placed: const <TowerPlacedPiece>[],
        incoming: scenario.pieces.first,
        centerX: TowerBalanceEngine.pivotX,
        elapsedSeconds: calmTime,
      );
      expect(result.stable, isTrue);
      expect(result.overlapFraction, closeTo(1, .001));
      expect(result.projectedCenter, closeTo(.5, .02));
    });

    test(
      'a heavy overhang is unstable, while the final brace widens the margin',
      () {
        final TowerBalanceScenario scenario = TowerBalanceScenario.forLevel(10);
        final TowerPieceSpec heavy = TowerPieceSpec(
          width: .24,
          height: .09,
          mass: 3.8,
          massBias: .12,
          material: 3,
        );
        final List<TowerPlacedPiece> placed = <TowerPlacedPiece>[
          for (int index = 0; index < 8; index++)
            TowerPlacedPiece(spec: scenario.pieces[index], centerX: .65),
        ];
        final double calmTime =
            ((6.283185307179586 - scenario.phaseOffset) % 6.283185307179586) /
            scenario.windFrequency;
        final TowerPlacementAssessment unsupported = TowerBalanceEngine.assess(
          scenario: scenario,
          placed: placed,
          incoming: heavy,
          centerX: .74,
          elapsedSeconds: calmTime,
        );
        final TowerPlacementAssessment braced = TowerBalanceEngine.assess(
          scenario: scenario,
          placed: placed,
          incoming: heavy,
          centerX: .74,
          elapsedSeconds: calmTime,
          supportPin: true,
        );
        expect(unsupported.allowedMargin, lessThan(braced.allowedMargin));
        expect(unsupported.stable, isFalse);
      },
    );
  });
}
