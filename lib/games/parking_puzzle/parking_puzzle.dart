import 'dart:collection';
import 'dart:math' as math;

import '../shared/content_seed.dart';
import '../shared/studio_game_contracts.dart';

enum ParkingAxis { horizontal, vertical }

class ParkingVehicle {
  const ParkingVehicle({
    required this.id,
    required this.axis,
    required this.lane,
    required this.length,
    required this.colorIndex,
  });

  final int id;
  final ParkingAxis axis;
  final int lane;
  final int length;
  final int colorIndex;

  int maximumOffset(int boardSize) => boardSize - length;

  String get axisCode => axis == ParkingAxis.horizontal ? 'H' : 'V';
}

class ParkingMove {
  const ParkingMove({
    required this.vehicleIndex,
    required this.fromOffset,
    required this.toOffset,
  });

  final int vehicleIndex;
  final int fromOffset;
  final int toOffset;

  int get distance => (toOffset - fromOffset).abs();
}

class ParkingPuzzle {
  const ParkingPuzzle({
    required this.level,
    required this.vehicles,
    required this.initialOffsets,
    required this.solution,
  });

  static const int boardSize = 6;
  static const int maximumUniqueCases = GameContentPolicy.minimumUniqueRounds;
  static final Map<int, ParkingPuzzle> _cache = <int, ParkingPuzzle>{};
  static final Set<String> _signatures = <String>{};
  static int _generatedThrough = 0;

  final int level;
  final List<ParkingVehicle> vehicles;
  final List<int> initialOffsets;
  final List<ParkingMove> solution;

  int get blockerCount => vehicles.length - 1;
  int get optimalMoves => solution.length;
  int get chapter => (level - 1) ~/ 10 + 1;
  int get stageInChapter => (level - 1) % 10 + 1;
  int get difficultyBand => level < 61
      ? 1
      : level < 131
      ? 2
      : level < 221
      ? 3
      : 4;

  String get boardSignature => <String>[
    for (int index = 0; index < vehicles.length; index++)
      '${vehicles[index].axisCode}${vehicles[index].lane}${vehicles[index].length}@${initialOffsets[index]}',
  ].join('|');

  bool isSolved(List<int> offsets) =>
      offsets.length == vehicles.length &&
      offsets[0] == vehicles[0].maximumOffset(boardSize);

  bool canMove(List<int> offsets, int vehicleIndex, int targetOffset) {
    if (offsets.length != vehicles.length ||
        vehicleIndex < 0 ||
        vehicleIndex >= vehicles.length ||
        targetOffset < 0 ||
        targetOffset > vehicles[vehicleIndex].maximumOffset(boardSize)) {
      return false;
    }
    return _neighbors(vehicles, offsets).any(
      (_ParkingTransition transition) =>
          transition.move.vehicleIndex == vehicleIndex &&
          transition.move.toOffset == targetOffset,
    );
  }

  List<int> move(List<int> offsets, int vehicleIndex, int targetOffset) {
    if (!canMove(offsets, vehicleIndex, targetOffset)) {
      throw ArgumentError('That vehicle cannot slide to the requested lane.');
    }
    final List<int> updated = List<int>.from(offsets);
    updated[vehicleIndex] = targetOffset;
    return List<int>.unmodifiable(updated);
  }

  List<int> hintOffsets(List<int> offsets) {
    if (isSolved(offsets)) return List<int>.unmodifiable(offsets);
    final List<ParkingMove> path = _findSolution(vehicles, offsets);
    if (path.isEmpty) return List<int>.unmodifiable(offsets);
    final ParkingMove first = path.first;
    final List<int> hinted = List<int>.from(offsets);
    hinted[first.vehicleIndex] = first.toOffset;
    return List<int>.unmodifiable(hinted);
  }

  static int blockersForLevel(int level) => switch (level) {
    < 61 => 6,
    < 131 => 7,
    < 221 => 8,
    _ => 9,
  };

  static int minimumOptimalMovesForLevel(int level) => switch (level) {
    < 61 => 5,
    < 131 => 6,
    < 221 => 7,
    < 271 => 8,
    _ => 9,
  };

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'initialOffsets': initialOffsets,
    'vehicles': vehicles
        .map((v) => [v.id, v.axis.index, v.lane, v.length, v.colorIndex])
        .toList(),
    'solution': solution
        .map((v) => [v.vehicleIndex, v.fromOffset, v.toOffset])
        .toList(),
  };

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) {
      throw FormatException('Invalid parking_puzzle bank');
    }
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      _cache[i + 1] = ParkingPuzzle(
        level: m['level'] as int,
        initialOffsets: List<int>.from(m['initialOffsets'] as List),
        vehicles: (m['vehicles'] as List)
            .map(
              (e) => ParkingVehicle(
                id: e[0] as int,
                axis: ParkingAxis.values[e[1] as int],
                lane: e[2] as int,
                length: e[3] as int,
                colorIndex: e[4] as int,
              ),
            )
            .toList(),
        solution: (m['solution'] as List)
            .map(
              (e) => ParkingMove(
                vehicleIndex: e[0] as int,
                fromOffset: e[1] as int,
                toOffset: e[2] as int,
              ),
            )
            .toList(),
      );
    }
    _generatedThrough = boards.length;
    _signatures.addAll(_cache.values.map((p) => p.boardSignature));
  }

  static ParkingPuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    while (_generatedThrough < level) {
      final int nextLevel = _generatedThrough + 1;
      final ParkingPuzzle puzzle = _generateUnique(nextLevel, _signatures);
      _cache[nextLevel] = puzzle;
      _signatures.add(puzzle.boardSignature);
      _generatedThrough = nextLevel;
    }
    return _cache[level]!;
  }

  static ParkingPuzzle _generateUnique(int level, Set<String> usedBoards) {
    final int blockerCount = blockersForLevel(level);
    final int minimumMoves = minimumOptimalMovesForLevel(level);
    const int maximumMoves = 30;
    int basePlacementFailures = 0;
    int unreachableRoutes = 0;
    int tooShortRoutes = 0;
    int tooLongRoutes = 0;
    int repeatedBoards = 0;
    final Map<int, int> shortRouteLengths = <int, int>{};

    for (int attempt = 0; attempt < 240; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'parking_puzzle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      final _ParkingBase? base = _createBaseVehicles(
        random,
        blockerCount,
        level,
      );
      if (base == null) {
        basePlacementFailures++;
        continue;
      }
      final List<ParkingVehicle> vehicles = base.vehicles;
      final List<int> layout = base.offsets;
      final List<ParkingMove>? route = _solve(vehicles, layout);
      if (route == null || route.isEmpty) {
        unreachableRoutes++;
        continue;
      }
      if (route.length < minimumMoves) {
        tooShortRoutes++;
        shortRouteLengths.update(
          route.length,
          (int count) => count + 1,
          ifAbsent: () => 1,
        );
        continue;
      }
      if (route.length > maximumMoves) {
        tooLongRoutes++;
        continue;
      }
      final String signature = _signature(vehicles, layout);
      if (usedBoards.contains(signature)) {
        repeatedBoards++;
        continue;
      }
      return ParkingPuzzle(
        level: level,
        vehicles: List<ParkingVehicle>.unmodifiable(vehicles),
        initialOffsets: List<int>.unmodifiable(layout),
        solution: List<ParkingMove>.unmodifiable(route),
      );
    }
    throw StateError(
      'Could not generate a unique parking board for $level '
      '(placement $basePlacementFailures, unreachable $unreachableRoutes, '
      'short $tooShortRoutes $shortRouteLengths, long $tooLongRoutes, '
      'repeated $repeatedBoards).',
    );
  }

  static _ParkingBase? _createBaseVehicles(
    math.Random random,
    int blockerCount,
    int level,
  ) {
    const int targetLane = 2;
    final int corridorColumn = level >= 221
        ? 2
        : random.nextBool()
        ? 2
        : 3;
    final int bottomBlockerStart = random.nextBool()
        ? corridorColumn - 1
        : corridorColumn;
    final int crossbarStart = random.nextBool()
        ? corridorColumn - 1
        : corridorColumn;
    final List<ParkingVehicle> vehicles = <ParkingVehicle>[
      const ParkingVehicle(
        id: 0,
        axis: ParkingAxis.horizontal,
        lane: targetLane,
        length: 2,
        colorIndex: 0,
      ),
      ParkingVehicle(
        id: 1,
        axis: ParkingAxis.vertical,
        lane: corridorColumn,
        length: 3,
        colorIndex: 1,
      ),
      ParkingVehicle(
        id: 2,
        axis: ParkingAxis.horizontal,
        lane: boardSize - 1,
        length: 2,
        colorIndex: 2,
      ),
      ParkingVehicle(
        id: 3,
        axis: ParkingAxis.vertical,
        lane: corridorColumn - 2,
        length: 2,
        colorIndex: 3,
      ),
      ParkingVehicle(
        id: 4,
        axis: ParkingAxis.vertical,
        lane: corridorColumn + 2,
        length: 2,
        colorIndex: 4,
      ),
      ParkingVehicle(
        id: 5,
        axis: ParkingAxis.horizontal,
        lane: targetLane + 2,
        length: 2,
        colorIndex: 5,
      ),
    ];
    final List<int> offsets = <int>[
      0,
      1,
      bottomBlockerStart,
      boardSize - 2,
      boardSize - 2,
      crossbarStart,
    ];
    final List<int> occupied = List<int>.filled(boardSize * boardSize, -1);
    for (int index = 0; index < vehicles.length; index++) {
      if (!_fits(vehicles[index], offsets[index], occupied)) return null;
      _stamp(vehicles[index], offsets[index], index, occupied);
    }

    if (level >= 221) {
      final ParkingVehicle chainGate = ParkingVehicle(
        id: vehicles.length,
        axis: ParkingAxis.horizontal,
        lane: targetLane + 1,
        length: 2,
        colorIndex: 6,
      );
      const int chainGateOffset = 4;
      if (!_fits(chainGate, chainGateOffset, occupied)) return null;
      vehicles.add(chainGate);
      offsets.add(chainGateOffset);
      _stamp(chainGate, chainGateOffset, vehicles.length - 1, occupied);
    }

    for (int id = vehicles.length; id <= blockerCount; id++) {
      bool placed = false;
      for (int choice = 0; choice < 140 && !placed; choice++) {
        final ParkingAxis axis = random.nextInt(2) == 0
            ? ParkingAxis.horizontal
            : ParkingAxis.vertical;
        final int length = level < 61 || random.nextInt(3) != 0 ? 2 : 3;
        final int lane = random.nextInt(boardSize);
        final int offset = random.nextInt(boardSize - length + 1);
        final ParkingVehicle candidate = ParkingVehicle(
          id: id,
          axis: axis,
          lane: lane,
          length: length,
          colorIndex: id % 7 + 1,
        );
        if (!_fits(candidate, offset, occupied)) continue;
        vehicles.add(candidate);
        offsets.add(offset);
        _stamp(candidate, offset, id, occupied);
        placed = true;
      }
      if (!placed) return null;
    }
    return _ParkingBase(vehicles, offsets);
  }

  static List<ParkingMove>? _solve(
    List<ParkingVehicle> vehicles,
    List<int> initial,
  ) {
    return _findSolution(vehicles, initial);
  }

  static List<ParkingMove> _findSolution(
    List<ParkingVehicle> vehicles,
    List<int> initial,
  ) {
    final String startKey = _stateKey(initial);
    final Queue<List<int>> queue = Queue<List<int>>()..add(initial);
    final Set<String> visited = <String>{startKey};
    final Map<String, _ParkingParent> parents = <String, _ParkingParent>{};
    String? goalKey;

    while (queue.isNotEmpty) {
      final List<int> state = queue.removeFirst();
      final String stateKey = _stateKey(state);
      if (state[0] == vehicles[0].maximumOffset(boardSize)) {
        goalKey = stateKey;
        break;
      }
      for (final _ParkingTransition transition in _neighbors(vehicles, state)) {
        final String nextKey = _stateKey(transition.offsets);
        if (!visited.add(nextKey)) continue;
        parents[nextKey] = _ParkingParent(stateKey, transition.move);
        queue.add(transition.offsets);
      }
    }
    if (goalKey == null) return const <ParkingMove>[];

    final List<ParkingMove> route = <ParkingMove>[];
    String cursor = goalKey;
    while (cursor != startKey) {
      final _ParkingParent? parent = parents[cursor];
      if (parent == null) return const <ParkingMove>[];
      route.add(parent.move);
      cursor = parent.previousKey;
    }
    return route.reversed.toList(growable: false);
  }

  static List<_ParkingTransition> _neighbors(
    List<ParkingVehicle> vehicles,
    List<int> offsets,
  ) {
    final List<int> occupied = _occupancy(vehicles, offsets);
    final List<_ParkingTransition> transitions = <_ParkingTransition>[];
    for (int vehicleIndex = 0; vehicleIndex < vehicles.length; vehicleIndex++) {
      final ParkingVehicle vehicle = vehicles[vehicleIndex];
      final int current = offsets[vehicleIndex];
      for (final int direction in const <int>[-1, 1]) {
        int destination = current + direction;
        while (destination >= 0 &&
            destination <= vehicle.maximumOffset(boardSize) &&
            _leadingCellIsOpen(vehicle, destination, direction, occupied)) {
          final List<int> moved = List<int>.from(offsets);
          moved[vehicleIndex] = destination;
          transitions.add(
            _ParkingTransition(
              moved,
              ParkingMove(
                vehicleIndex: vehicleIndex,
                fromOffset: current,
                toOffset: destination,
              ),
            ),
          );
          destination += direction;
        }
      }
    }
    return transitions;
  }

  static List<int> _occupancy(
    List<ParkingVehicle> vehicles,
    List<int> offsets,
  ) {
    final List<int> occupied = List<int>.filled(boardSize * boardSize, -1);
    for (int index = 0; index < vehicles.length; index++) {
      _stamp(vehicles[index], offsets[index], index, occupied);
    }
    return occupied;
  }

  static bool _leadingCellIsOpen(
    ParkingVehicle vehicle,
    int destination,
    int direction,
    List<int> occupied,
  ) {
    final int coordinate = direction < 0
        ? destination
        : destination + vehicle.length - 1;
    final int row = vehicle.axis == ParkingAxis.horizontal
        ? vehicle.lane
        : coordinate;
    final int column = vehicle.axis == ParkingAxis.horizontal
        ? coordinate
        : vehicle.lane;
    return occupied[row * boardSize + column] < 0;
  }

  static bool _fits(ParkingVehicle vehicle, int offset, List<int> occupied) {
    if (offset < 0 || offset > vehicle.maximumOffset(boardSize)) return false;
    for (int distance = 0; distance < vehicle.length; distance++) {
      final int row = vehicle.axis == ParkingAxis.horizontal
          ? vehicle.lane
          : offset + distance;
      final int column = vehicle.axis == ParkingAxis.horizontal
          ? offset + distance
          : vehicle.lane;
      if (occupied[row * boardSize + column] != -1) return false;
    }
    return true;
  }

  static void _stamp(
    ParkingVehicle vehicle,
    int offset,
    int value,
    List<int> occupied,
  ) {
    for (int distance = 0; distance < vehicle.length; distance++) {
      final int row = vehicle.axis == ParkingAxis.horizontal
          ? vehicle.lane
          : offset + distance;
      final int column = vehicle.axis == ParkingAxis.horizontal
          ? offset + distance
          : vehicle.lane;
      occupied[row * boardSize + column] = value;
    }
  }

  static String _signature(
    List<ParkingVehicle> vehicles,
    List<int> offsets,
  ) => <String>[
    for (int index = 0; index < vehicles.length; index++)
      '${vehicles[index].axisCode}${vehicles[index].lane}${vehicles[index].length}@${offsets[index]}',
  ].join('|');

  static String _stateKey(List<int> offsets) =>
      String.fromCharCodes(offsets.map((int offset) => 65 + offset));
}

class _ParkingTransition {
  const _ParkingTransition(this.offsets, this.move);

  final List<int> offsets;
  final ParkingMove move;
}

class _ParkingParent {
  const _ParkingParent(this.previousKey, this.move);

  final String previousKey;
  final ParkingMove move;
}

class _ParkingBase {
  const _ParkingBase(this.vehicles, this.offsets);

  final List<ParkingVehicle> vehicles;
  final List<int> offsets;
}
