import 'dart:math' as math;

import 'block_flow_scenario.dart';

class BlockFlowStepResult {
  const BlockFlowStepResult({
    this.hitObstacle = false,
    this.collectedShard = false,
    this.passedRow = false,
    this.finished = false,
  });

  final bool hitObstacle;
  final bool collectedShard;
  final bool passedRow;
  final bool finished;
}

/// Lane choice, phase-gate energy and a controlled automatic forward stream.
class BlockFlowEngine {
  BlockFlowEngine({required this.scenario}) : energy = scenario.startEnergy;

  final BlockFlowScenario scenario;
  double elapsedSeconds = 0;
  double progress = 0;
  double _stunSeconds = 0;
  int lane = 1;
  int deck = 0;
  int energy;
  int nextRow = 0;
  int shards = 0;
  int misses = 0;
  int bumpCount = 0;
  bool isComplete = false;

  int get rowCount => scenario.rowCount;
  double get progressFraction => (progress / rowCount).clamp(0, 1).toDouble();
  BlockFlowRow? get upcomingRow =>
      nextRow < scenario.rows.length ? scenario.rows[nextRow] : null;
  bool get canSwitchDeck =>
      scenario.dualDeck && energy > 0 && upcomingRow?.hasRiftAt(lane) == true;
  double get currentFlow => upcomingRow?.counterflow == true ? -.7 : 1;

  bool shiftLane(int direction) {
    if (isComplete || direction == 0) return false;
    final int target = (lane + direction.sign).clamp(0, 2).toInt();
    if (target == lane) return false;
    lane = target;
    return true;
  }

  bool switchDeck() {
    if (!canSwitchDeck || isComplete) return false;
    energy--;
    deck = 1 - deck;
    return true;
  }

  BlockFlowStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .024).toDouble();
    if (delta == 0 || isComplete) return const BlockFlowStepResult();
    elapsedSeconds += delta;
    if (_stunSeconds > 0) {
      _stunSeconds = math.max(0, _stunSeconds - delta);
      return const BlockFlowStepResult();
    }
    final BlockFlowRow? row = upcomingRow;
    final double multiplier = row?.counterflow == true ? .62 : 1;
    progress += scenario.rowSpeed * multiplier * delta;
    if (row == null || progress < row.index + 1) {
      return const BlockFlowStepResult();
    }

    bool hitObstacle = false;
    bool collectedShard = false;
    if (row.blocks(lane, deck)) {
      misses++;
      bumpCount++;
      hitObstacle = true;
      _stunSeconds = .34;
    } else if (row.hasShard(lane, deck)) {
      final FlowShard shard = row.shards.firstWhere(
        (FlowShard item) => item.lane == lane && item.deck == deck,
      );
      shards++;
      energy = math.min(scenario.maximumEnergy, energy + shard.energy);
      collectedShard = true;
    }
    nextRow++;
    if (nextRow >= scenario.rows.length) {
      isComplete = true;
      return BlockFlowStepResult(
        hitObstacle: hitObstacle,
        collectedShard: collectedShard,
        passedRow: true,
        finished: true,
      );
    }
    return BlockFlowStepResult(
      hitObstacle: hitObstacle,
      collectedShard: collectedShard,
      passedRow: true,
    );
  }

  void reset() {
    elapsedSeconds = 0;
    progress = 0;
    _stunSeconds = 0;
    lane = 1;
    deck = 0;
    energy = scenario.startEnergy;
    nextRow = 0;
    shards = 0;
    misses = 0;
    bumpCount = 0;
    isComplete = false;
  }
}
