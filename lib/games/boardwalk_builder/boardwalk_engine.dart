import 'dart:collection';

import 'boardwalk_scenario.dart';

class BoardwalkPlacement {
  const BoardwalkPlacement({required this.build, required this.cell});

  final BoardwalkBuild build;
  final BoardwalkCell cell;
  String get signature => '${build.name}@${cell.signature}';
}

class BoardwalkEvaluation {
  const BoardwalkEvaluation({
    required this.score,
    required this.requiredPlaced,
    required this.requiredCount,
    required this.connectedBuildings,
    required this.buildingCount,
    required this.rideCapacity,
    required this.foodCapacity,
    required this.binCount,
    required this.benchCount,
    required this.shelterReady,
    required this.budgetUsed,
    required this.budget,
    required this.canOpen,
  });

  final int score;
  final int requiredPlaced;
  final int requiredCount;
  final int connectedBuildings;
  final int buildingCount;
  final int rideCapacity;
  final int foodCapacity;
  final int binCount;
  final int benchCount;
  final bool shelterReady;
  final int budgetUsed;
  final int budget;
  final bool canOpen;
}

class BoardwalkActionResult {
  const BoardwalkActionResult(this.accepted, this.reason);

  final bool accepted;
  final String reason;
}

class BoardwalkEngine {
  BoardwalkEngine({required this.scenario});

  final BoardwalkScenario scenario;
  final List<BoardwalkPlacement> _placements = <BoardwalkPlacement>[];
  final List<List<BoardwalkPlacement>> _undo = <List<BoardwalkPlacement>>[];
  final List<List<BoardwalkPlacement>> _redo = <List<BoardwalkPlacement>>[];

  List<BoardwalkPlacement> get placements =>
      List<BoardwalkPlacement>.unmodifiable(_placements);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get budgetUsed => _placements.fold<int>(
    0,
    (int sum, BoardwalkPlacement item) => sum + item.build.cost,
  );

  BoardwalkActionResult place(BoardwalkBuild build, BoardwalkCell cell) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= scenario.width ||
        cell.y >= scenario.height) {
      return const BoardwalkActionResult(false, 'outside_park');
    }
    if (cell == scenario.entry) {
      return const BoardwalkActionResult(false, 'entry_reserved');
    }
    if (scenario.blockedCells.contains(cell)) {
      return const BoardwalkActionResult(false, 'blocked');
    }
    if (_placements.any((BoardwalkPlacement item) => item.cell == cell)) {
      return const BoardwalkActionResult(false, 'occupied');
    }
    if (budgetUsed + build.cost > scenario.budget) {
      return const BoardwalkActionResult(false, 'over_budget');
    }
    _commit(
      () => _placements.add(BoardwalkPlacement(build: build, cell: cell)),
    );
    return const BoardwalkActionResult(true, 'placed');
  }

  BoardwalkActionResult removeAt(BoardwalkCell cell) {
    final int index = _placements.indexWhere(
      (BoardwalkPlacement item) => item.cell == cell,
    );
    if (index < 0) return const BoardwalkActionResult(false, 'empty');
    _commit(() => _placements.removeAt(index));
    return const BoardwalkActionResult(true, 'removed');
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(List<BoardwalkPlacement>.of(_placements));
    _placements
      ..clear()
      ..addAll(_undo.removeLast());
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(List<BoardwalkPlacement>.of(_placements));
    _placements
      ..clear()
      ..addAll(_redo.removeLast());
    return true;
  }

  BoardwalkEvaluation evaluate() {
    final Map<BoardwalkBuild, int> placedCounts = <BoardwalkBuild, int>{};
    for (final BoardwalkPlacement item in _placements) {
      placedCounts.update(
        item.build,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final Map<BoardwalkBuild, int> requiredCounts = <BoardwalkBuild, int>{};
    for (final BoardwalkBuild build in scenario.requiredBuilds) {
      requiredCounts.update(build, (int count) => count + 1, ifAbsent: () => 1);
    }
    final int requiredPlaced = requiredCounts.entries.fold<int>(
      0,
      (int sum, MapEntry<BoardwalkBuild, int> entry) =>
          sum + (placedCounts[entry.key] ?? 0).clamp(0, entry.value),
    );
    final Set<BoardwalkCell> connectedPath = _connectedPathCells();
    final List<BoardwalkPlacement> buildings = _placements
        .where((BoardwalkPlacement item) => item.build != BoardwalkBuild.path)
        .toList(growable: false);
    final int connectedBuildings = buildings
        .where(
          (BoardwalkPlacement item) => _touchesPath(item.cell, connectedPath),
        )
        .length;
    final int rideCapacity = _placements.fold<int>(
      0,
      (int sum, BoardwalkPlacement item) => sum + item.build.rideCapacity,
    );
    final int foodCapacity = _placements.fold<int>(
      0,
      (int sum, BoardwalkPlacement item) => sum + item.build.foodCapacity,
    );
    final int binCount = placedCounts[BoardwalkBuild.litterBin] ?? 0;
    final int benchCount = placedCounts[BoardwalkBuild.bench] ?? 0;
    final bool shelterReady =
        scenario.weather != BoardwalkWeather.shower ||
        (placedCounts[BoardwalkBuild.shadeCanopy] ?? 0) > 0;
    final bool budgetOk = budgetUsed <= scenario.budget;
    final bool requirementsOk =
        requiredPlaced == scenario.requiredBuilds.length;
    final bool networkOk =
        connectedPath.isNotEmpty && connectedBuildings == buildings.length;
    final bool visitorFlowOk =
        rideCapacity >= scenario.visitorCount &&
        foodCapacity >= (scenario.visitorCount / 2).ceil();
    final bool amenitiesOk =
        binCount >= scenario.minimumBins &&
        benchCount >= scenario.minimumBenches &&
        shelterReady;

    final double requirementsFit = scenario.requiredBuilds.isEmpty
        ? 1
        : requiredPlaced / scenario.requiredBuilds.length;
    final double networkFit = buildings.isEmpty
        ? 1
        : connectedBuildings / buildings.length;
    final double rideFit = (rideCapacity / scenario.visitorCount)
        .clamp(0.0, 1.0)
        .toDouble();
    final double foodFit = (foodCapacity / (scenario.visitorCount / 2).ceil())
        .clamp(0.0, 1.0)
        .toDouble();
    final double amenityFit =
        (binCount >= scenario.minimumBins ? .4 : .2) +
        (benchCount >= scenario.minimumBenches ? .4 : .2) +
        (shelterReady ? .2 : 0);
    final int score =
        ((requirementsFit * 35) +
                (budgetOk ? 15 : 0) +
                (networkFit * 20) +
                (rideFit * 12) +
                (foodFit * 8) +
                (amenityFit * 10))
            .round()
            .clamp(0, 100)
            .toInt();

    return BoardwalkEvaluation(
      score: score,
      requiredPlaced: requiredPlaced,
      requiredCount: scenario.requiredBuilds.length,
      connectedBuildings: connectedBuildings,
      buildingCount: buildings.length,
      rideCapacity: rideCapacity,
      foodCapacity: foodCapacity,
      binCount: binCount,
      benchCount: benchCount,
      shelterReady: shelterReady,
      budgetUsed: budgetUsed,
      budget: scenario.budget,
      canOpen:
          requirementsOk &&
          budgetOk &&
          networkOk &&
          visitorFlowOk &&
          amenitiesOk,
    );
  }

  Set<BoardwalkCell> _connectedPathCells() {
    final Set<BoardwalkCell> paths = <BoardwalkCell>{
      scenario.entry,
      for (final BoardwalkPlacement item in _placements)
        if (item.build == BoardwalkBuild.path) item.cell,
    };
    final Set<BoardwalkCell> visited = <BoardwalkCell>{scenario.entry};
    final Queue<BoardwalkCell> queue = Queue<BoardwalkCell>()
      ..add(scenario.entry);
    while (queue.isNotEmpty) {
      final BoardwalkCell current = queue.removeFirst();
      for (final BoardwalkCell next in _neighbors(current)) {
        if (paths.contains(next) && visited.add(next)) queue.add(next);
      }
    }
    return visited;
  }

  bool _touchesPath(BoardwalkCell cell, Set<BoardwalkCell> path) =>
      _neighbors(cell).any(path.contains);

  Iterable<BoardwalkCell> _neighbors(BoardwalkCell cell) sync* {
    if (cell.x > 0) yield BoardwalkCell(cell.x - 1, cell.y);
    if (cell.x + 1 < scenario.width) yield BoardwalkCell(cell.x + 1, cell.y);
    if (cell.y > 0) yield BoardwalkCell(cell.x, cell.y - 1);
    if (cell.y + 1 < scenario.height) yield BoardwalkCell(cell.x, cell.y + 1);
  }

  void _commit(void Function() mutation) {
    _undo.add(List<BoardwalkPlacement>.of(_placements));
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    mutation();
  }
}
