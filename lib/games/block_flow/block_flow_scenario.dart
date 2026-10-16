import 'dart:math' as math;

import '../shared/content_seed.dart';

class FlowHazard {
  const FlowHazard({
    required this.lane,
    required this.deck,
    required this.shape,
  });

  final int lane;
  final int deck;
  final int shape;

  int get cell => deck * 3 + lane;
  String get signature => '$lane:$deck:$shape';
}

class FlowShard {
  const FlowShard({required this.lane, required this.deck, this.energy = 1});

  final int lane;
  final int deck;
  final int energy;

  int get cell => deck * 3 + lane;
  String get signature => '$lane:$deck:$energy';

  @override
  bool operator ==(Object other) =>
      other is FlowRouteState &&
      other.lane == lane &&
      other.deck == deck &&
      other.energy == energy;

  @override
  int get hashCode => Object.hash(lane, deck, energy);
}

class BlockFlowRow {
  const BlockFlowRow({
    required this.index,
    required this.hazards,
    required this.shards,
    required this.riftLaneMask,
    required this.counterflow,
  });

  final int index;
  final List<FlowHazard> hazards;
  final List<FlowShard> shards;
  final int riftLaneMask;
  final bool counterflow;

  bool blocks(int lane, int deck) => hazards.any(
    (FlowHazard hazard) => hazard.lane == lane && hazard.deck == deck,
  );

  bool hasShard(int lane, int deck) =>
      shards.any((FlowShard shard) => shard.lane == lane && shard.deck == deck);

  bool hasRiftAt(int lane) => riftLaneMask & (1 << lane) != 0;

  String get signature =>
      '$index:${hazards.map((FlowHazard hazard) => hazard.signature).join(',')}/'
      '${shards.map((FlowShard shard) => shard.signature).join(',')}/'
      '$riftLaneMask:$counterflow';
}

class FlowRouteState {
  const FlowRouteState({
    required this.lane,
    required this.deck,
    required this.energy,
  });

  final int lane;
  final int deck;
  final int energy;

  String get signature => '$lane:$deck:$energy';

  @override
  bool operator ==(Object other) =>
      other is FlowRouteState &&
      other.lane == lane &&
      other.deck == deck &&
      other.energy == energy;

  @override
  int get hashCode => Object.hash(lane, deck, energy);
}

/// Campaign rows are deterministic and verified with a lane/deck/energy solver.
class BlockFlowScenario {
  const BlockFlowScenario._({
    required this.level,
    required this.seed,
    required this.rows,
    required this.startEnergy,
    required this.maximumEnergy,
    required this.missLimit,
    required this.targetShards,
    required this.rowSpeed,
    required this.goldTimeSeconds,
    required this.dualDeck,
  });

  static const int maximumLevels = 10;
  static const int maximumPracticeRounds = 300;
  static final Map<int, BlockFlowScenario> _campaign =
      <int, BlockFlowScenario>{};
  static final Map<int, BlockFlowScenario> _practice =
      <int, BlockFlowScenario>{};

  final int level;
  final int seed;
  final List<BlockFlowRow> rows;
  final int startEnergy;
  final int maximumEnergy;
  final int missLimit;
  final int targetShards;
  final double rowSpeed;
  final double goldTimeSeconds;
  final bool dualDeck;

  int get rowCount => rows.length;

  String get signature =>
      '$level|$startEnergy:$maximumEnergy:$missLimit:$targetShards:'
      '${rowSpeed.toStringAsFixed(3)}:$dualDeck|'
      '${rows.map((BlockFlowRow row) => row.signature).join(';')}';

  bool get hasVerifiedRoute {
    Set<FlowRouteState> reachable = <FlowRouteState>{
      FlowRouteState(lane: 1, deck: 0, energy: startEnergy),
    };
    for (final BlockFlowRow row in rows) {
      final Set<FlowRouteState> next = <FlowRouteState>{};
      for (final FlowRouteState state in reachable) {
        for (final int lane in <int>[
          state.lane,
          if (state.lane > 0) state.lane - 1,
          if (state.lane < 2) state.lane + 1,
        ]) {
          final bool canShiftDeck =
              dualDeck &&
              state.energy > 0 &&
              (row.hasRiftAt(state.lane) || row.hasRiftAt(lane));
          for (final int deck in <int>[
            state.deck,
            if (canShiftDeck) 1 - state.deck,
          ]) {
            if (row.blocks(lane, deck)) continue;
            final bool shiftedDeck = deck != state.deck;
            final int energy =
                (state.energy -
                        (shiftedDeck ? 1 : 0) +
                        (row.hasShard(lane, deck) ? 1 : 0))
                    .clamp(0, maximumEnergy)
                    .toInt();
            next.add(FlowRouteState(lane: lane, deck: deck, energy: energy));
          }
        }
      }
      if (next.isEmpty) return false;
      reachable = next;
    }
    return reachable.isNotEmpty;
  }

  static void _checkLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
  }

  static BlockFlowScenario forLevel(int level) {
    _checkLevel(level);
    for (int next = 1; next <= level; next++) {
      _campaign.putIfAbsent(next, () => _build(next, replayIndex: 0));
    }
    return _campaign[level]!;
  }

  static BlockFlowScenario forPracticeRound(int index) {
    if (index < 1 || index > maximumPracticeRounds) {
      throw RangeError.range(index, 1, maximumPracticeRounds, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      forLevel(level);
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      _practice[next] = _build(level, replayIndex: next);
    }
    return _practice[index]!;
  }

  static Set<String> get _usedSignatures => <String>{
    ..._campaign.values.map((BlockFlowScenario run) => run.signature),
    ..._practice.values.map((BlockFlowScenario run) => run.signature),
  };

  static BlockFlowScenario _build(int level, {required int replayIndex}) {
    _checkLevel(level);
    final Set<String> used = _usedSignatures;
    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'block_flow:$replayIndex',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final bool dualDeck = level >= 4;
      final int rowCount = 11 + level * 2;
      const int maximumEnergy = 3;
      final int startEnergy = level <= 3 ? 0 : 2;
      int lane = 1;
      int deck = 0;
      int plannedEnergy = startEnergy;
      final List<BlockFlowRow> rows = <BlockFlowRow>[];

      for (int index = 0; index < rowCount; index++) {
        if (random.nextDouble() < .48) {
          lane = (lane + (random.nextBool() ? 1 : -1)).clamp(0, 2).toInt();
        }
        final bool scheduledRift = dualDeck && index % 3 == 1;
        final bool collectEnergy = index % 4 == 2;
        final bool switchDeck =
            dualDeck && index >= 4 && index % 5 == 4 && plannedEnergy > 0;
        int riftLaneMask = scheduledRift ? 1 << lane : 0;
        if (switchDeck) {
          deck = 1 - deck;
          plannedEnergy--;
          riftLaneMask = 7;
        }
        final bool counterflow =
            level >= 7 && index % (level >= 9 ? 3 : 5) == 2;
        final FlowRouteState safe = FlowRouteState(
          lane: lane,
          deck: deck,
          energy: plannedEnergy,
        );
        final int cellCount = dualDeck ? 6 : 3;
        final double density = (.13 + level * .045).clamp(.16, .62).toDouble();
        final List<FlowHazard> hazards = <FlowHazard>[];
        for (int cell = 0; cell < cellCount; cell++) {
          final int cellDeck = dualDeck ? cell ~/ 3 : 0;
          final int cellLane = cell % 3;
          if (cellLane == safe.lane && cellDeck == safe.deck) continue;
          if (random.nextDouble() < density) {
            hazards.add(
              FlowHazard(
                lane: cellLane,
                deck: cellDeck,
                shape: random.nextInt(level >= 7 ? 4 : 3),
              ),
            );
          }
        }
        final List<FlowShard> shards = <FlowShard>[];
        if (collectEnergy) {
          shards.add(FlowShard(lane: lane, deck: deck));
          plannedEnergy = math.min(maximumEnergy, plannedEnergy + 1);
        } else if (dualDeck && random.nextDouble() < .18) {
          final List<FlowRouteState> open = <FlowRouteState>[
            for (int cell = 0; cell < cellCount; cell++)
              if (!hazards.any((FlowHazard hazard) => hazard.cell == cell))
                FlowRouteState(
                  lane: cell % 3,
                  deck: cell ~/ 3,
                  energy: plannedEnergy,
                ),
          ];
          if (open.isNotEmpty) {
            final FlowRouteState pickup = open[random.nextInt(open.length)];
            shards.add(FlowShard(lane: pickup.lane, deck: pickup.deck));
          }
        }
        rows.add(
          BlockFlowRow(
            index: index,
            hazards: List<FlowHazard>.unmodifiable(hazards),
            shards: List<FlowShard>.unmodifiable(shards),
            riftLaneMask: riftLaneMask,
            counterflow: counterflow,
          ),
        );
      }

      final BlockFlowScenario candidate = BlockFlowScenario._(
        level: level,
        seed: seed,
        rows: List<BlockFlowRow>.unmodifiable(rows),
        startEnergy: startEnergy,
        maximumEnergy: maximumEnergy,
        missLimit: level <= 3
            ? 4
            : level <= 6
            ? 3
            : level <= 8
            ? 2
            : 1,
        targetShards: math.max(
          2,
          (rows.where((BlockFlowRow row) => row.shards.isNotEmpty).length * .7)
              .ceil(),
        ),
        rowSpeed: 1.06 + level * .12,
        goldTimeSeconds: math.max(17, 46 - level * 2.3),
        dualDeck: dualDeck,
      );
      if (!used.contains(candidate.signature) &&
          _isFair(candidate) &&
          candidate.hasVerifiedRoute) {
        return candidate;
      }
    }
    throw StateError('Could not generate a unique solvable Blok Akışı run.');
  }

  static bool _isFair(BlockFlowScenario run) =>
      run.rows.length >= 13 &&
      run.rows.first.hazards.length < (run.dualDeck ? 6 : 3) &&
      run.startEnergy <= run.maximumEnergy &&
      run.missLimit >= 1 &&
      run.rows.every(
        (BlockFlowRow row) =>
            row.hazards.every(
              (FlowHazard hazard) =>
                  hazard.lane >= 0 &&
                  hazard.lane < 3 &&
                  hazard.deck >= 0 &&
                  hazard.deck <= (run.dualDeck ? 1 : 0),
            ) &&
            row.shards.every(
              (FlowShard shard) =>
                  shard.lane >= 0 &&
                  shard.lane < 3 &&
                  shard.deck >= 0 &&
                  shard.deck <= (run.dualDeck ? 1 : 0),
            ),
      );
}
