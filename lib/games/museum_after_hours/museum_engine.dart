import 'dart:math' as math;

import 'museum_scenario.dart';

class MuseumGuardState {
  MuseumGuardState(this.spec)
    : patrolIndex = spec.startOffset % spec.patrol.length,
      cell = spec.patrol[spec.startOffset % spec.patrol.length];

  final MuseumGuardSpec spec;
  int patrolIndex;
  MuseumCell cell;
  int distractedTurns = 0;

  MuseumCell get facing {
    final MuseumCell next = spec.patrol[(patrolIndex + 1) % spec.patrol.length];
    return (x: next.x - cell.x, y: next.y - cell.y);
  }
}

class MuseumActionResult {
  const MuseumActionResult({
    this.accepted = false,
    this.moved = false,
    this.collected = false,
    this.hidden = false,
    this.lureUsed = false,
    this.escaped = false,
    this.caught = false,
    this.laserHit = false,
  });

  final bool accepted;
  final bool moved;
  final bool collected;
  final bool hidden;
  final bool lureUsed;
  final bool escaped;
  final bool caught;
  final bool laserHit;
}

/// Turn-based stealth rules. A turn is spent only by a legal deliberate action.
class MuseumAfterHoursEngine {
  MuseumAfterHoursEngine({required this.scenario})
    : player = MuseumScenario.start,
      guards = <MuseumGuardState>[
        for (int i = 0; i < scenario.guards.length; i++)
          MuseumGuardState(scenario.guards[i]),
      ];

  final MuseumScenario scenario;
  final List<MuseumGuardState> guards;
  final Set<MuseumCell> collectedArtifacts = <MuseumCell>{};
  MuseumCell player;
  int turn = 0;
  int lureCharges = 1;
  int actions = 0;
  bool hidden = false;
  bool caught = false;
  bool escaped = false;

  bool get isInShadow => scenario.shadows.contains(player);
  bool get allArtifactsCollected =>
      collectedArtifacts.length == scenario.artifacts.length;
  int get remainingArtifacts =>
      scenario.artifacts.length - collectedArtifacts.length;

  List<MuseumCell> get visibleCells => <MuseumCell>[
    for (final MuseumGuardState guard in guards) ..._visionCells(guard),
  ];

  bool laserActive(MuseumLaserSpec laser, [int? atTurn]) =>
      laser.isActiveAt(atTurn ?? turn);

  MuseumActionResult move(int dx, int dy) {
    if (_ended || (dx.abs() + dy.abs() != 1)) {
      return const MuseumActionResult();
    }
    final MuseumCell target = (x: player.x + dx, y: player.y + dy);
    if (!_inside(target) || scenario.walls.contains(target)) {
      return const MuseumActionResult();
    }
    final int nextTurn = turn + 1;
    final MuseumLaserSpec? laser = scenario.laserAt(target);
    if (laser != null && laser.isActiveAt(nextTurn)) {
      player = target;
      turn = nextTurn;
      actions++;
      caught = true;
      return MuseumActionResult(
        accepted: true,
        moved: true,
        caught: true,
        laserHit: true,
      );
    }
    if (guards.any((MuseumGuardState guard) => guard.cell == target)) {
      return const MuseumActionResult();
    }
    player = target;
    hidden = false;
    _advanceTurn();
    return MuseumActionResult(accepted: true, moved: true, caught: caught);
  }

  MuseumActionResult hide() {
    if (_ended || !isInShadow) return const MuseumActionResult();
    hidden = true;
    _advanceTurn(suppressDetection: true);
    return MuseumActionResult(accepted: true, hidden: true, caught: caught);
  }

  MuseumActionResult useLure() {
    if (_ended || lureCharges == 0) return const MuseumActionResult();
    lureCharges--;
    for (final MuseumGuardState guard in guards) {
      guard.distractedTurns = math.max(guard.distractedTurns, 3);
    }
    _advanceTurn();
    return MuseumActionResult(accepted: true, lureUsed: true, caught: caught);
  }

  MuseumActionResult collect() {
    if (_ended ||
        !scenario.artifacts.contains(player) ||
        collectedArtifacts.contains(player)) {
      return const MuseumActionResult();
    }
    collectedArtifacts.add(player);
    _advanceTurn();
    return MuseumActionResult(accepted: true, collected: true, caught: caught);
  }

  MuseumActionResult escape() {
    if (_ended || player != MuseumScenario.exit || !allArtifactsCollected) {
      return const MuseumActionResult();
    }
    escaped = true;
    return const MuseumActionResult(accepted: true, escaped: true);
  }

  List<MuseumCell> _visionCells(MuseumGuardState guard) {
    final MuseumCell direction = guard.facing;
    final List<MuseumCell> cells = <MuseumCell>[];
    for (int distance = 1; distance <= guard.spec.visionRange; distance++) {
      for (int side = -(distance ~/ 2); side <= distance ~/ 2; side++) {
        final MuseumCell cell = (
          x:
              guard.cell.x +
              direction.x * distance +
              (direction.y == 0 ? 0 : side),
          y:
              guard.cell.y +
              direction.y * distance +
              (direction.x == 0 ? 0 : side),
        );
        if (!_inside(cell) || !_lineClear(guard.cell, cell)) continue;
        cells.add(cell);
      }
    }
    return cells;
  }

  bool _lineClear(MuseumCell from, MuseumCell to) {
    final int steps = math.max((to.x - from.x).abs(), (to.y - from.y).abs());
    if (steps < 2) return true;
    for (int step = 1; step < steps; step++) {
      final MuseumCell between = (
        x: (from.x + (to.x - from.x) * step / steps).round(),
        y: (from.y + (to.y - from.y) * step / steps).round(),
      );
      if (scenario.walls.contains(between)) return false;
    }
    return true;
  }

  bool get _ended => caught || escaped;

  bool _inside(MuseumCell cell) =>
      cell.x >= 1 &&
      cell.x < MuseumScenario.columns - 1 &&
      cell.y >= 1 &&
      cell.y < MuseumScenario.rows - 1;

  void _advanceTurn({bool suppressDetection = false}) {
    turn++;
    actions++;
    for (final MuseumGuardState guard in guards) {
      if (actions % guard.spec.cadence != 0) continue;
      _advanceGuard(guard);
    }
    if (suppressDetection || hidden || isInShadow) return;
    if (guards.any(
      (MuseumGuardState guard) => _visionCells(guard).contains(player),
    )) {
      caught = true;
    }
  }

  void _advanceGuard(MuseumGuardState guard) {
    if (guard.distractedTurns > 0) {
      guard.distractedTurns--;
      final MuseumCell target = scenario.lureTarget;
      final List<MuseumCell> options =
          <MuseumCell>[
                (
                  x: guard.cell.x + (target.x - guard.cell.x).sign,
                  y: guard.cell.y,
                ),
                (
                  x: guard.cell.x,
                  y: guard.cell.y + (target.y - guard.cell.y).sign,
                ),
              ]
              .where(
                (MuseumCell cell) =>
                    cell != guard.cell && !_blockedForGuard(cell, guard),
              )
              .toList();
      if (options.isNotEmpty) {
        options.sort((MuseumCell a, MuseumCell b) {
          final int da = (a.x - target.x).abs() + (a.y - target.y).abs();
          final int db = (b.x - target.x).abs() + (b.y - target.y).abs();
          return da.compareTo(db);
        });
        guard.cell = options.first;
      }
      return;
    }
    for (int tries = 0; tries < guard.spec.patrol.length; tries++) {
      guard.patrolIndex = (guard.patrolIndex + 1) % guard.spec.patrol.length;
      final MuseumCell candidate = guard.spec.patrol[guard.patrolIndex];
      if (_blockedForGuard(candidate, guard)) continue;
      guard.cell = candidate;
      return;
    }
  }

  bool _blockedForGuard(MuseumCell cell, MuseumGuardState self) =>
      !_inside(cell) ||
      scenario.walls.contains(cell) ||
      guards.any(
        (MuseumGuardState guard) => guard != self && guard.cell == cell,
      );
}
