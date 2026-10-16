import 'dart:math' as math;

import 'tower_balance_scenario.dart';

class TowerPlacedPiece {
  const TowerPlacedPiece({required this.spec, required this.centerX});

  final TowerPieceSpec spec;
  final double centerX;
}

class TowerPlacementAssessment {
  const TowerPlacementAssessment({
    required this.centerOfMass,
    required this.projectedCenter,
    required this.overlapFraction,
    required this.allowedMargin,
    required this.stable,
  });

  final double centerOfMass;
  final double projectedCenter;
  final double overlapFraction;
  final double allowedMargin;
  final bool stable;
}

abstract final class TowerBalanceEngine {
  static const double baseWidth = .72;
  static const double pivotX = .5;

  static double waveAt(TowerBalanceScenario scenario, double elapsedSeconds) =>
      math.sin(elapsedSeconds * scenario.windFrequency + scenario.phaseOffset);

  static TowerPlacementAssessment assess({
    required TowerBalanceScenario scenario,
    required List<TowerPlacedPiece> placed,
    required TowerPieceSpec incoming,
    required double centerX,
    required double elapsedSeconds,
    bool supportPin = false,
  }) {
    final double supportWidth = placed.isEmpty
        ? baseWidth
        : placed.last.spec.width;
    final double lower = placed.isEmpty
        ? pivotX - baseWidth / 2
        : placed.last.centerX - supportWidth / 2;
    final double upper = lower + supportWidth;
    final double pieceLeft = centerX - incoming.width / 2;
    final double pieceRight = centerX + incoming.width / 2;
    final double overlap = math.max(
      0,
      math.min(upper, pieceRight) - math.max(lower, pieceLeft),
    );
    final double overlapFraction =
        overlap / math.min(supportWidth, incoming.width);

    double totalMass = incoming.mass;
    double moment =
        incoming.mass * (centerX + incoming.massBias * incoming.width);
    double towerHeight = incoming.height;
    for (final TowerPlacedPiece piece in placed) {
      totalMass += piece.spec.mass;
      moment +=
          piece.spec.mass *
          (piece.centerX + piece.spec.massBias * piece.spec.width);
      towerHeight += piece.spec.height;
    }
    final double centerOfMass = moment / totalMass;
    final double wave = waveAt(scenario, elapsedSeconds);
    final double projectedCenter =
        centerOfMass +
        wave * scenario.tiltAmplitude * towerHeight * .72 +
        wave * scenario.windStrength * towerHeight * .19;
    final double allowedMargin =
        scenario.balanceMargin + (supportPin ? .085 : 0);
    final bool stable =
        overlapFraction >= scenario.minimumOverlap &&
        (projectedCenter - pivotX).abs() <= allowedMargin;
    return TowerPlacementAssessment(
      centerOfMass: centerOfMass,
      projectedCenter: projectedCenter,
      overlapFraction: overlapFraction,
      allowedMargin: allowedMargin,
      stable: stable,
    );
  }
}
