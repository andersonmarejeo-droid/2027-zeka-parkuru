import 'dart:math' as math;

import 'relic_run_scenario.dart';

class RelicRunFoeState {
  RelicRunFoeState(RelicRunFoeSpec spec)
    : spec = spec,
      cell = spec.cell,
      health = spec.health;

  final RelicRunFoeSpec spec;
  RelicCell cell;
  int health;
  Set<RelicCell> telegraph = <RelicCell>{};

  bool get alive => health > 0;
}

class RelicRunActionResult {
  const RelicRunActionResult({
    this.accepted = false,
    this.hit = false,
    this.kill = false,
    this.dodged = false,
    this.damageReceived = 0,
    this.trapTriggered = false,
    this.relicActivated = false,
    this.roomCleared = false,
    this.completed = false,
    this.failed = false,
  });

  final bool accepted;
  final bool hit;
  final bool kill;
  final bool dodged;
  final int damageReceived;
  final bool trapTriggered;
  final bool relicActivated;
  final bool roomCleared;
  final bool completed;
  final bool failed;
}

/// Turn-resolved room combat: enemy intent is shown one move before impact.
class RelicRunEngine {
  RelicRunEngine({required this.scenario}) {
    _loadRoom();
  }

  final RelicRunScenario scenario;
  static const RelicCell startCell = (x: 1, y: 4);
  static const RelicCell exitCell = (x: 7, y: 4);

  int roomIndex = 0;
  int health = 100;
  int maxHealth = 100;
  int relicCharge = 1;
  int kills = 0;
  int actions = 0;
  int damageTaken = 0;
  int relicsCollected = 0;
  int attackPower = 1;
  int skillPower = 2;
  int _dodgeCooldown = 0;
  bool _dodgeGuard = false;
  bool awaitingRelicChoice = false;
  bool completed = false;
  bool failed = false;
  RelicRunRelic? selectedRelic;
  RelicCell player = startCell;
  (int dx, int dy) facing = (1, 0);
  late RelicRunRoom room;
  final Set<RelicCell> _spentTraps = <RelicCell>{};
  final Set<RelicRunRelic> collectedRelics = <RelicRunRelic>{};
  late List<RelicRunFoeState> foes;

  List<RelicCell> get walls => room.walls;
  List<RelicCell> get traps => room.traps;
  List<RelicRunFoeState> get livingFoes => List<RelicRunFoeState>.unmodifiable(
    foes.where((RelicRunFoeState foe) => foe.alive),
  );
  List<RelicCell> get telegraphedCells => foes
      .where((RelicRunFoeState foe) => foe.alive)
      .expand((RelicRunFoeState foe) => foe.telegraph)
      .toSet()
      .toList(growable: false);
  bool get dodgeReady => _dodgeCooldown == 0 && !awaitingRelicChoice;
  bool get roomHasGuardian => room.isGuardianRoom;
  bool get exitOpen => livingFoes.isEmpty && !awaitingRelicChoice;
  List<RelicRunRelic> get currentRelicOffer =>
      roomIndex < scenario.relicOffers.length
      ? scenario.relicOffers[roomIndex]
      : const <RelicRunRelic>[];

  bool aimAt(RelicCell target) {
    if (!_canAct() || target == player) return false;
    final int dx = target.x - player.x;
    final int dy = target.y - player.y;
    if (dx.abs() > dy.abs()) {
      facing = (dx.sign.toInt(), 0);
    } else {
      facing = (0, dy.sign.toInt());
    }
    return true;
  }

  RelicRunActionResult move(int dx, int dy) {
    if (!_canAct() || !_isCardinal(dx, dy)) return const RelicRunActionResult();
    final RelicCell destination = (x: player.x + dx, y: player.y + dy);
    if (!_isOpen(destination)) return const RelicRunActionResult();
    player = destination;
    facing = (dx, dy);
    final bool trap =
        room.traps.contains(destination) && _spentTraps.add(destination);
    if (trap) {
      health = math.max(0, health - (8 + scenario.level ~/ 4));
      damageTaken += 8 + scenario.level ~/ 4;
    }
    return _finishAction(
      trapTriggered: trap,
      immediateDamage: trap ? 8 + scenario.level ~/ 4 : 0,
    );
  }

  RelicRunActionResult dodge() {
    if (!_canAct() || !dodgeReady || !_isCardinal(facing.$1, facing.$2)) {
      return const RelicRunActionResult();
    }
    RelicCell destination = player;
    for (int step = 0; step < 2; step++) {
      final RelicCell candidate = (
        x: destination.x + facing.$1,
        y: destination.y + facing.$2,
      );
      if (!_isOpen(candidate)) break;
      destination = candidate;
    }
    if (destination == player) return const RelicRunActionResult();
    player = destination;
    _dodgeCooldown = 3;
    _dodgeGuard = true;
    return _finishAction(dodged: true);
  }

  RelicRunActionResult attack() {
    if (!_canAct()) return const RelicRunActionResult();
    RelicRunFoeState? target;
    for (int range = 1; range <= 4; range++) {
      final RelicCell candidate = (
        x: player.x + facing.$1 * range,
        y: player.y + facing.$2 * range,
      );
      if (candidate.x < 0 ||
          candidate.x >= RelicRunScenario.columns ||
          candidate.y < 0 ||
          candidate.y >= RelicRunScenario.rows ||
          walls.contains(candidate)) {
        break;
      }
      for (final RelicRunFoeState foe in livingFoes) {
        if (foe.cell == candidate) {
          target = foe;
          break;
        }
      }
      if (target != null) break;
    }
    bool hit = false;
    bool kill = false;
    if (target != null) {
      target.health -= attackPower;
      hit = true;
      if (!target.alive) {
        kill = true;
        kills++;
        relicCharge = math.min(2, relicCharge + 1);
      } else {
        relicCharge = math.min(2, relicCharge + 1);
      }
    }
    return _finishAction(hit: hit, kill: kill);
  }

  RelicRunActionResult activateRelic() {
    if (!_canAct() || relicCharge < 2) return const RelicRunActionResult();
    final List<RelicRunFoeState> targets = livingFoes
        .where((RelicRunFoeState foe) => _distance(foe.cell, player) <= 2)
        .toList(growable: false);
    if (targets.isEmpty) return const RelicRunActionResult();
    relicCharge -= 2;
    bool hit = false;
    bool kill = false;
    for (final RelicRunFoeState foe in targets) {
      foe.health -= skillPower;
      foe.telegraph = <RelicCell>{};
      hit = true;
      if (!foe.alive) {
        kill = true;
        kills++;
        relicCharge = math.min(2, relicCharge + 1);
      }
    }
    return _finishAction(hit: hit, kill: kill, relicActivated: true);
  }

  RelicRunActionResult chooseRelic(RelicRunRelic relic) {
    if (!awaitingRelicChoice || !currentRelicOffer.contains(relic)) {
      return const RelicRunActionResult();
    }
    awaitingRelicChoice = false;
    selectedRelic = relic;
    relicsCollected++;
    collectedRelics.add(relic);
    switch (relic) {
      case RelicRunRelic.ember:
        attackPower++;
        break;
      case RelicRunRelic.aegis:
        maxHealth += 12;
        health = math.min(maxHealth, health + 24);
        break;
      case RelicRunRelic.echo:
        relicCharge = math.min(2, relicCharge + 1);
        _dodgeCooldown = 0;
        break;
      case RelicRunRelic.prism:
        skillPower += 2;
        break;
    }
    roomIndex++;
    _loadRoom();
    return RelicRunActionResult(accepted: true);
  }

  RelicRunActionResult _finishAction({
    bool hit = false,
    bool kill = false,
    bool dodged = false,
    int immediateDamage = 0,
    bool trapTriggered = false,
    bool relicActivated = false,
  }) {
    actions++;
    final int enemyDamage = _resolveEnemyTurn();
    final int damage = immediateDamage + enemyDamage;
    if (_dodgeCooldown > 0 && !dodged) _dodgeCooldown--;
    if (health <= 0) failed = true;
    final bool cleared = !failed && livingFoes.isEmpty && player == exitCell;
    if (cleared && !failed) {
      if (roomIndex + 1 < RelicRunScenario.roomCount) {
        awaitingRelicChoice = true;
      } else {
        completed = true;
      }
    }
    return RelicRunActionResult(
      accepted: true,
      hit: hit,
      kill: kill,
      dodged: dodged,
      damageReceived: damage,
      trapTriggered: trapTriggered,
      relicActivated: relicActivated,
      roomCleared: cleared,
      completed: completed,
      failed: failed,
    );
  }

  int _resolveEnemyTurn() {
    int damageDealt = 0;
    if (_dodgeGuard) {
      _dodgeGuard = false;
      for (final RelicRunFoeState foe in foes) {
        foe.telegraph = <RelicCell>{};
      }
    } else {
      for (final RelicRunFoeState foe in livingFoes) {
        if (foe.telegraph.contains(player)) {
          health = math.max(0, health - foe.spec.damage);
          damageDealt += foe.spec.damage;
          damageTaken += foe.spec.damage;
          if (health == 0) {
            failed = true;
            break;
          }
        }
        foe.telegraph = <RelicCell>{};
      }
    }
    if (!failed) {
      for (final RelicRunFoeState foe in livingFoes) {
        if (foe.spec.kind == RelicRunFoeKind.stalker ||
            foe.spec.kind == RelicRunFoeKind.guardian) {
          _moveFoeTowardPlayer(foe);
        }
      }
      _prepareTelegraphs();
    }
    return damageDealt;
  }

  void _loadRoom() {
    room = scenario.rooms[roomIndex];
    foes = <RelicRunFoeState>[
      for (final RelicRunFoeSpec spec in room.foes) RelicRunFoeState(spec),
    ];
    player = startCell;
    if (roomIndex > 0) health = math.min(maxHealth, health + 8);
    _spentTraps.clear();
    _prepareTelegraphs();
  }

  void _moveFoeTowardPlayer(RelicRunFoeState foe) {
    if (_distance(foe.cell, player) <= 1) return;
    final List<RelicCell> choices = <RelicCell>[
      (x: foe.cell.x + (player.x - foe.cell.x).sign, y: foe.cell.y),
      (x: foe.cell.x, y: foe.cell.y + (player.y - foe.cell.y).sign),
      (x: foe.cell.x + 1, y: foe.cell.y),
      (x: foe.cell.x - 1, y: foe.cell.y),
      (x: foe.cell.x, y: foe.cell.y + 1),
      (x: foe.cell.x, y: foe.cell.y - 1),
    ];
    final List<RelicCell> legal =
        choices
            .where((RelicCell cell) => _isOpen(cell, ignore: foe))
            .toSet()
            .toList(growable: false)
          ..sort(
            (RelicCell a, RelicCell b) =>
                _distance(a, player).compareTo(_distance(b, player)),
          );
    if (legal.isNotEmpty &&
        _distance(legal.first, player) < _distance(foe.cell, player)) {
      foe.cell = legal.first;
    }
  }

  void _prepareTelegraphs() {
    final int limit = 1 + scenario.level ~/ 9;
    final List<RelicRunFoeState> candidates =
        livingFoes
            .where((RelicRunFoeState foe) {
              final int distance = _distance(foe.cell, player);
              return switch (foe.spec.kind) {
                RelicRunFoeKind.stalker => distance <= 4,
                RelicRunFoeKind.sentinel => distance <= 3,
                RelicRunFoeKind.guardian => distance <= 6,
                RelicRunFoeKind.ranger => _alignedAndClear(foe.cell, player),
              };
            })
            .toList(growable: false)
          ..sort(
            (RelicRunFoeState a, RelicRunFoeState b) =>
                _distance(a.cell, player).compareTo(_distance(b.cell, player)),
          );
    final Set<RelicRunFoeState> active = candidates.take(limit).toSet();
    for (final RelicRunFoeState foe in livingFoes) {
      if (!active.contains(foe)) {
        foe.telegraph = <RelicCell>{};
      } else if (foe.spec.kind == RelicRunFoeKind.guardian) {
        foe.telegraph = <RelicCell>{
          player,
          (x: player.x + 1, y: player.y),
          (x: player.x - 1, y: player.y),
          (x: player.x, y: player.y + 1),
          (x: player.x, y: player.y - 1),
        };
      } else if (foe.spec.kind == RelicRunFoeKind.ranger) {
        foe.telegraph = _rayCells(foe.cell, player);
      } else {
        foe.telegraph = <RelicCell>{player};
      }
    }
  }

  Set<RelicCell> _rayCells(RelicCell from, RelicCell to) {
    final int dx = (to.x - from.x).sign;
    final int dy = (to.y - from.y).sign;
    final Set<RelicCell> cells = <RelicCell>{};
    RelicCell cell = from;
    for (int i = 0; i < RelicRunScenario.columns + RelicRunScenario.rows; i++) {
      cell = (x: cell.x + dx, y: cell.y + dy);
      if (cell == to ||
          cell.x < 0 ||
          cell.x >= RelicRunScenario.columns ||
          cell.y < 0 ||
          cell.y >= RelicRunScenario.rows ||
          walls.contains(cell)) {
        break;
      }
      cells.add(cell);
    }
    cells.add(to);
    return cells;
  }

  bool _alignedAndClear(RelicCell a, RelicCell b) {
    if (a.x != b.x && a.y != b.y) return false;
    final int dx = (b.x - a.x).sign;
    final int dy = (b.y - a.y).sign;
    RelicCell cursor = a;
    while (cursor != b) {
      cursor = (x: cursor.x + dx, y: cursor.y + dy);
      if (cursor != b && walls.contains(cursor)) return false;
    }
    return true;
  }

  bool _isOpen(RelicCell cell, {RelicRunFoeState? ignore}) {
    if (cell.x < 0 ||
        cell.x >= RelicRunScenario.columns ||
        cell.y < 0 ||
        cell.y >= RelicRunScenario.rows ||
        walls.contains(cell)) {
      return false;
    }
    if (cell == player) return false;
    return !livingFoes.any(
      (RelicRunFoeState foe) => foe != ignore && foe.cell == cell,
    );
  }

  bool _canAct() => !completed && !failed && !awaitingRelicChoice;

  static int _distance(RelicCell a, RelicCell b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs();

  static bool _isCardinal(int dx, int dy) =>
      (dx.abs() == 1 && dy == 0) || (dy.abs() == 1 && dx == 0);
}
