import 'dart:collection';

import 'interior_scenario.dart';

class InteriorPlacement {
  const InteriorPlacement({
    required this.furniture,
    required this.x,
    required this.y,
    required this.rotated,
    required this.palette,
  });

  final InteriorFurniture furniture;
  final int x;
  final int y;
  final bool rotated;
  final InteriorPalette palette;

  int get width => rotated ? furniture.footprint.$2 : furniture.footprint.$1;
  int get height => rotated ? furniture.footprint.$1 : furniture.footprint.$2;

  String get signature =>
      '${furniture.name}:$x:$y:${rotated ? 1 : 0}:${palette.name}';
}

class InteriorEvaluation {
  const InteriorEvaluation({
    required this.score,
    required this.requiredPlaced,
    required this.requiredCount,
    required this.budgetUsed,
    required this.budget,
    required this.accessibleRatio,
    required this.styleFit,
    required this.paletteFit,
    required this.windowUsed,
    required this.canSubmit,
  });

  final int score;
  final int requiredPlaced;
  final int requiredCount;
  final int budgetUsed;
  final int budget;
  final double accessibleRatio;
  final double styleFit;
  final double paletteFit;
  final bool windowUsed;
  final bool canSubmit;
}

class InteriorActionResult {
  const InteriorActionResult(this.accepted, this.reason);

  final bool accepted;
  final String reason;
}

class InteriorEngine {
  InteriorEngine({required this.scenario});

  final InteriorScenario scenario;
  final List<InteriorPlacement> _placements = <InteriorPlacement>[];
  final List<List<InteriorPlacement>> _undo = <List<InteriorPlacement>>[];
  final List<List<InteriorPlacement>> _redo = <List<InteriorPlacement>>[];

  List<InteriorPlacement> get placements =>
      List<InteriorPlacement>.unmodifiable(_placements);
  int get budgetUsed => _placements.fold<int>(
    0,
    (int sum, InteriorPlacement item) => sum + item.furniture.cost,
  );
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  InteriorActionResult place({
    required InteriorFurniture furniture,
    required int x,
    required int y,
    required bool rotated,
    required InteriorPalette palette,
  }) {
    if (_placements.any((InteriorPlacement p) => p.furniture == furniture)) {
      return const InteriorActionResult(false, 'already_placed');
    }
    final InteriorPlacement item = InteriorPlacement(
      furniture: furniture,
      x: x,
      y: y,
      rotated: rotated,
      palette: palette,
    );
    if (x < 0 ||
        y < 0 ||
        x + item.width > scenario.width ||
        y + item.height > scenario.height) {
      return const InteriorActionResult(false, 'outside_room');
    }
    if (_cells(item).contains((scenario.doorX, scenario.height - 1))) {
      return const InteriorActionResult(false, 'door_blocked');
    }
    if (_placements.any(
      (InteriorPlacement existing) => _overlaps(item, existing),
    )) {
      return const InteriorActionResult(false, 'overlap');
    }
    if (budgetUsed + furniture.cost > scenario.budget) {
      return const InteriorActionResult(false, 'over_budget');
    }
    _commit(() => _placements.add(item));
    return const InteriorActionResult(true, 'placed');
  }

  InteriorActionResult removeAt(int x, int y) {
    final int index = _placements.indexWhere(
      (InteriorPlacement item) => _cells(item).contains((x, y)),
    );
    if (index < 0) return const InteriorActionResult(false, 'empty');
    _commit(() => _placements.removeAt(index));
    return const InteriorActionResult(true, 'removed');
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    _redo.add(List<InteriorPlacement>.of(_placements));
    _placements
      ..clear()
      ..addAll(_undo.removeLast());
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _undo.add(List<InteriorPlacement>.of(_placements));
    _placements
      ..clear()
      ..addAll(_redo.removeLast());
    return true;
  }

  InteriorEvaluation evaluate() {
    final int requiredPlaced = scenario.requirements
        .where(
          (InteriorFurniture item) =>
              _placements.any((InteriorPlacement p) => p.furniture == item),
        )
        .length;
    final double requirementFit = requiredPlaced / scenario.requirements.length;
    final double styleFit = _placements.isEmpty
        ? 0
        : _placements
                  .where(
                    (InteriorPlacement p) =>
                        p.furniture.styles.contains(scenario.style),
                  )
                  .length /
              _placements.length;
    final double paletteFit = _placements.isEmpty
        ? 0
        : _placements
                  .where((InteriorPlacement p) => p.palette == scenario.palette)
                  .length /
              _placements.length;
    final int accessible = _accessibleCells().length;
    final double accessibleRatio =
        accessible / (scenario.width * scenario.height);
    final bool windowUsed = _placements.any(
      (InteriorPlacement p) => (p.x - scenario.windowX).abs() <= 2 && p.y <= 2,
    );
    final bool budgetOk = budgetUsed <= scenario.budget;
    final bool circulationOk = accessibleRatio >= .35;
    final int score =
        ((requirementFit * 40) +
                (budgetOk ? 15 : 0) +
                ((accessibleRatio.clamp(0, .65) / .65) * 20) +
                (styleFit * 15) +
                (paletteFit * 5) +
                (windowUsed ? 5 : 0))
            .round()
            .clamp(0, 100)
            .toInt();
    return InteriorEvaluation(
      score: score,
      requiredPlaced: requiredPlaced,
      requiredCount: scenario.requirements.length,
      budgetUsed: budgetUsed,
      budget: scenario.budget,
      accessibleRatio: accessibleRatio,
      styleFit: styleFit,
      paletteFit: paletteFit,
      windowUsed: windowUsed,
      canSubmit:
          requiredPlaced == scenario.requirements.length &&
          budgetOk &&
          circulationOk &&
          windowUsed &&
          styleFit >= .6 &&
          paletteFit >= .6,
    );
  }

  void _commit(void Function() mutation) {
    _undo.add(List<InteriorPlacement>.of(_placements));
    if (_undo.length > 50) _undo.removeAt(0);
    _redo.clear();
    mutation();
  }

  bool _overlaps(InteriorPlacement a, InteriorPlacement b) {
    for (final (int x, int y) in _cells(a)) {
      if (_cells(b).contains((x, y))) return true;
    }
    return false;
  }

  Set<(int, int)> _cells(InteriorPlacement item) => <(int, int)>{
    for (int y = item.y; y < item.y + item.height; y++)
      for (int x = item.x; x < item.x + item.width; x++) (x, y),
  };

  Set<(int, int)> _accessibleCells() {
    final Set<(int, int)> blocked = <(int, int)>{
      for (final InteriorPlacement item in _placements) ..._cells(item),
    };
    final (int, int) door = (scenario.doorX, scenario.height - 1);
    if (blocked.contains(door)) return <(int, int)>{};
    final Set<(int, int)> seen = <(int, int)>{door};
    final Queue<(int, int)> pending = Queue<(int, int)>()..add(door);
    while (pending.isNotEmpty) {
      final (int x, int y) = pending.removeFirst();
      for (final (int dx, int dy) in const <(int, int)>[
        (1, 0),
        (-1, 0),
        (0, 1),
        (0, -1),
      ]) {
        final (int nx, int ny) = (x + dx, y + dy);
        if (nx < 0 || ny < 0 || nx >= scenario.width || ny >= scenario.height) {
          continue;
        }
        final (int, int) next = (nx, ny);
        if (!blocked.contains(next) && seen.add(next)) pending.add(next);
      }
    }
    return seen;
  }
}
