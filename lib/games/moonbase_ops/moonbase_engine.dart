import 'dart:collection';

import 'moonbase_scenario.dart';

class MoonModulePlacement {
  const MoonModulePlacement({required this.module, required this.cell});
  final MoonModule module;
  final MoonCell cell;
  String get signature => '${module.name}@${cell.signature}';
}

class MoonbaseEvaluation {
  const MoonbaseEvaluation({
    required this.score,
    required this.requiredPlaced,
    required this.requiredCount,
    required this.connectedCount,
    required this.moduleCount,
    required this.powerAvailable,
    required this.powerDemand,
    required this.oxygenAvailable,
    required this.oxygenDemand,
    required this.heatLoad,
    required this.cooling,
    required this.budgetUsed,
    required this.budget,
    required this.shieldReady,
    required this.canLaunch,
  });
  final int score;
  final int requiredPlaced;
  final int requiredCount;
  final int connectedCount;
  final int moduleCount;
  final int powerAvailable;
  final int powerDemand;
  final int oxygenAvailable;
  final int oxygenDemand;
  final int heatLoad;
  final int cooling;
  final int budgetUsed;
  final int budget;
  final bool shieldReady;
  final bool canLaunch;
}

class MoonbaseActionResult {
  const MoonbaseActionResult(this.accepted, this.reason);
  final bool accepted;
  final String reason;
}

class MoonbaseEngine {
  MoonbaseEngine({required this.scenario});
  final MoonbaseScenario scenario;
  final List<MoonModulePlacement> _placements = <MoonModulePlacement>[];
  final List<List<MoonModulePlacement>> _undo = <List<MoonModulePlacement>>[];
  final List<List<MoonModulePlacement>> _redo = <List<MoonModulePlacement>>[];

  List<MoonModulePlacement> get placements =>
      List<MoonModulePlacement>.unmodifiable(_placements);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get budgetUsed => _placements.fold<int>(
    0,
    (int total, MoonModulePlacement item) => total + item.module.cost,
  );

  MoonbaseActionResult place(MoonModule module, MoonCell cell) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= scenario.size ||
        cell.y >= scenario.size) {
      return const MoonbaseActionResult(false, 'outside_grid');
    }
    if (cell == scenario.core) {
      return const MoonbaseActionResult(false, 'core_reserved');
    }
    if (scenario.rocks.contains(cell)) {
      return const MoonbaseActionResult(false, 'rock');
    }
    if (_placements.any((MoonModulePlacement item) => item.cell == cell)) {
      return const MoonbaseActionResult(false, 'occupied');
    }
    if (budgetUsed + module.cost > scenario.budget) {
      return const MoonbaseActionResult(false, 'over_budget');
    }
    _commit(
      () => _placements.add(MoonModulePlacement(module: module, cell: cell)),
    );
    return const MoonbaseActionResult(true, 'placed');
  }

  MoonbaseActionResult removeAt(MoonCell cell) {
    final int index = _placements.indexWhere(
      (MoonModulePlacement p) => p.cell == cell,
    );
    if (index < 0) return const MoonbaseActionResult(false, 'empty');
    _commit(() => _placements.removeAt(index));
    return const MoonbaseActionResult(true, 'removed');
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(List<MoonModulePlacement>.of(_placements));
    _placements
      ..clear()
      ..addAll(_undo.removeLast());
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(List<MoonModulePlacement>.of(_placements));
    _placements
      ..clear()
      ..addAll(_redo.removeLast());
    return true;
  }

  MoonbaseEvaluation evaluate() {
    final Map<MoonModule, int> counts = <MoonModule, int>{};
    for (final MoonModulePlacement item in _placements) {
      counts.update(item.module, (int n) => n + 1, ifAbsent: () => 1);
    }
    final Map<MoonModule, int> wanted = <MoonModule, int>{};
    for (final MoonModule module in scenario.requiredModules) {
      wanted.update(module, (int n) => n + 1, ifAbsent: () => 1);
    }
    final int requiredPlaced = wanted.entries.fold<int>(
      0,
      (int total, MapEntry<MoonModule, int> entry) =>
          total + (counts[entry.key] ?? 0).clamp(0, entry.value),
    );
    final Set<MoonCell> connected = _connectedModules();
    final int connectedCount = _placements
        .where((MoonModulePlacement item) => connected.contains(item.cell))
        .length;
    final int powerGross = _placements.fold<int>(
      0,
      (int total, MoonModulePlacement p) => total + p.module.power,
    );
    final int powerAvailable =
        powerGross - scenario.powerPenalty + scenario.batteryBonus;
    final int oxygenAvailable = _placements.fold<int>(
      0,
      (int total, MoonModulePlacement p) => total + p.module.oxygen,
    );
    final int heatLoad =
        _placements.fold<int>(
          0,
          (int total, MoonModulePlacement p) => total + p.module.heat,
        ) +
        (scenario.hazard == MoonHazard.coldFront ? 3 : 0);
    final int cooling = _placements.fold<int>(
      0,
      (int total, MoonModulePlacement p) => total + p.module.cooling,
    );
    final bool budgetOk = budgetUsed <= scenario.budget;
    final bool allRequirements =
        requiredPlaced == scenario.requiredModules.length;
    final bool connectedOk =
        connectedCount == _placements.length && _placements.isNotEmpty;
    final bool powerOk = powerAvailable >= scenario.powerDemand;
    final bool oxygenOk = oxygenAvailable >= scenario.oxygenDemand;
    final bool heatOk = heatLoad <= scenario.heatLimit + cooling;
    final bool shieldReady =
        !scenario.shieldRequired || (counts[MoonModule.shield] ?? 0) > 0;
    final double requirementFit = scenario.requiredModules.isEmpty
        ? 1
        : requiredPlaced / scenario.requiredModules.length;
    final double networkFit = _placements.isEmpty
        ? 0
        : connectedCount / _placements.length;
    final double powerFit = (powerAvailable / scenario.powerDemand)
        .clamp(0.0, 1.0)
        .toDouble();
    final double oxygenFit = (oxygenAvailable / scenario.oxygenDemand)
        .clamp(0.0, 1.0)
        .toDouble();
    final double heatFit = heatLoad <= scenario.heatLimit + cooling
        ? 1
        : (scenario.heatLimit + cooling) / heatLoad;
    final int score =
        ((requirementFit * 32) +
                (networkFit * 20) +
                (powerFit * 13) +
                (oxygenFit * 13) +
                (heatFit * 12) +
                (shieldReady ? 5 : 0) +
                (budgetOk ? 5 : 0))
            .round()
            .clamp(0, 100)
            .toInt();
    return MoonbaseEvaluation(
      score: score,
      requiredPlaced: requiredPlaced,
      requiredCount: scenario.requiredModules.length,
      connectedCount: connectedCount,
      moduleCount: _placements.length,
      powerAvailable: powerAvailable,
      powerDemand: scenario.powerDemand,
      oxygenAvailable: oxygenAvailable,
      oxygenDemand: scenario.oxygenDemand,
      heatLoad: heatLoad,
      cooling: cooling,
      budgetUsed: budgetUsed,
      budget: scenario.budget,
      shieldReady: shieldReady,
      canLaunch:
          allRequirements &&
          connectedOk &&
          powerOk &&
          oxygenOk &&
          heatOk &&
          shieldReady &&
          budgetOk,
    );
  }

  Set<MoonCell> _connectedModules() {
    final Set<MoonCell> moduleCells = <MoonCell>{
      for (final MoonModulePlacement item in _placements) item.cell,
    };
    final Set<MoonCell> visited = <MoonCell>{scenario.core};
    final Queue<MoonCell> pending = Queue<MoonCell>()..add(scenario.core);
    while (pending.isNotEmpty) {
      final MoonCell current = pending.removeFirst();
      for (final MoonCell next in _neighbors(current)) {
        if (moduleCells.contains(next) && visited.add(next)) pending.add(next);
      }
    }
    return visited;
  }

  Iterable<MoonCell> _neighbors(MoonCell cell) sync* {
    if (cell.x > 0) yield MoonCell(cell.x - 1, cell.y);
    if (cell.x + 1 < scenario.size) yield MoonCell(cell.x + 1, cell.y);
    if (cell.y > 0) yield MoonCell(cell.x, cell.y - 1);
    if (cell.y + 1 < scenario.size) yield MoonCell(cell.x, cell.y + 1);
  }

  void _commit(void Function() mutation) {
    _undo.add(List<MoonModulePlacement>.of(_placements));
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    mutation();
  }
}
