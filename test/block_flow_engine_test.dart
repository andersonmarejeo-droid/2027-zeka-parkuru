import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/block_flow/block_flow_engine.dart';
import 'package:zeka_parkuru/games/block_flow/block_flow_scenario.dart';

void main() {
  test('lane control is discrete and stays inside the three-lane rail', () {
    final BlockFlowEngine engine = BlockFlowEngine(
      scenario: BlockFlowScenario.forLevel(1),
    );
    expect(engine.shiftLane(-1), isTrue);
    expect(engine.lane, 0);
    expect(engine.shiftLane(-1), isFalse);
    expect(engine.shiftLane(1), isTrue);
    expect(engine.lane, 1);
  });

  test('an obstacle collision is counted once and the corridor continues', () {
    final BlockFlowScenario course = BlockFlowScenario.forLevel(5);
    final BlockFlowEngine engine = BlockFlowEngine(scenario: course);
    final BlockFlowRow row = course.rows.first;
    final FlowHazard hazard = row.hazards.first;
    engine
      ..lane = hazard.lane
      ..deck = hazard.deck
      ..progress = .999;
    final BlockFlowStepResult result = engine.step(.024);
    expect(result.hitObstacle, isTrue);
    expect(result.passedRow, isTrue);
    expect(engine.misses, 1);
    expect(engine.nextRow, 1);
    expect(engine.isComplete, isFalse);
  });

  test(
    'a collected cube restores energy and a rift spends it on a deck shift',
    () {
      final BlockFlowScenario course = BlockFlowScenario.forLevel(4);
      final BlockFlowEngine engine = BlockFlowEngine(scenario: course);
      final BlockFlowRow pickupRow = course.rows.firstWhere(
        (BlockFlowRow row) => row.shards.isNotEmpty,
      );
      final FlowShard shard = pickupRow.shards.first;
      engine
        ..nextRow = pickupRow.index
        ..progress = pickupRow.index + .99
        ..lane = shard.lane
        ..deck = shard.deck;
      final BlockFlowStepResult pickupResult = engine.step(.024);
      expect(pickupResult.collectedShard, isTrue);
      expect(engine.shards, 1);

      final int riftIndex = course.rows.indexWhere(
        (BlockFlowRow row) => row.riftLaneMask != 0,
      );
      final BlockFlowRow riftRow = course.rows[riftIndex];
      final int riftLane = List<int>.generate(
        3,
        (int lane) => lane,
      ).firstWhere(riftRow.hasRiftAt);
      engine
        ..nextRow = riftIndex
        ..progress = riftIndex.toDouble()
        ..lane = riftLane
        ..deck = 0
        ..energy = 2;
      expect(engine.canSwitchDeck, isTrue);
      expect(engine.switchDeck(), isTrue);
      expect(engine.deck, 1);
      expect(engine.energy, 1);
    },
  );

  test(
    'automatic flow finishes exactly after the final row and resets cleanly',
    () {
      final BlockFlowScenario course = BlockFlowScenario.forLevel(1);
      final BlockFlowEngine engine = BlockFlowEngine(scenario: course);
      BlockFlowStepResult result = const BlockFlowStepResult();
      for (int frame = 0; frame < 8000 && !result.finished; frame++) {
        result = engine.step(.024);
      }
      expect(result.finished, isTrue);
      expect(engine.nextRow, course.rowCount);
      expect(engine.isComplete, isTrue);
      engine.reset();
      expect(engine.progress, 0);
      expect(engine.nextRow, 0);
      expect(engine.lane, 1);
      expect(engine.isComplete, isFalse);
    },
  );
}
