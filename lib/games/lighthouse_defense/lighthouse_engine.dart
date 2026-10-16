import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'lighthouse_scenario.dart';

class LighthouseEnemyState {
  LighthouseEnemyState(this.spec);

  final LighthouseEnemySpec spec;
  double progress = 0;
  double slowedFor = 0;
  int health = 0;

  bool get alive => health > 0;
}

class LighthouseTower {
  LighthouseTower({required this.padIndex, required this.type});

  final int padIndex;
  final LighthouseTowerType type;
  int tier = 1;
  LighthouseTargetRule targetRule = LighthouseTargetRule.first;
  double cooldown = .12;
}

class LighthouseStepResult {
  const LighthouseStepResult({
    this.spawned = 0,
    this.kills = 0,
    this.escapes = 0,
    this.shots = 0,
    this.pulseUsed = false,
    this.waveCleared = false,
    this.victory = false,
    this.failed = false,
  });

  final int spawned;
  final int kills;
  final int escapes;
  final int shots;
  final bool pulseUsed;
  final bool waveCleared;
  final bool victory;
  final bool failed;
}

/// Continuous lane-defense simulation with explicit pre-wave economy decisions.
class LighthouseDefenseEngine {
  LighthouseDefenseEngine({required this.scenario})
    : coins = scenario.startingCoins,
      lives = scenario.startingLives,
      pulseCharges = scenario.pulseCharges {
    towers = List<LighthouseTower?>.filled(scenario.pads.length, null);
  }

  final LighthouseScenario scenario;
  late final List<LighthouseTower?> towers;
  final List<LighthouseEnemyState> enemies = <LighthouseEnemyState>[];
  int coins;
  int lives;
  int pulseCharges;
  int waveIndex = 0;
  int spawnedInWave = 0;
  int totalKills = 0;
  int totalEscapes = 0;
  int totalShots = 0;
  bool waveRunning = false;
  bool victory = false;
  bool failed = false;
  double _spawnClock = 0;

  LighthouseWaveSpec? get currentWave =>
      waveIndex < scenario.waves.length ? scenario.waves[waveIndex] : null;
  bool get canStartWave =>
      !waveRunning && !victory && !failed && waveIndex < scenario.waves.length;
  int get wavesRemaining => math.max(0, scenario.waves.length - waveIndex);
  int get towerCount => towers.whereType<LighthouseTower>().length;

  static const Map<LighthouseTowerType, int> buildPrices =
      <LighthouseTowerType, int>{
        LighthouseTowerType.ballista: 95,
        LighthouseTowerType.frost: 75,
        LighthouseTowerType.mortar: 125,
      };

  int upgradePrice(LighthouseTower tower) => 55 + tower.tier * 45;

  bool buildTower(int padIndex, LighthouseTowerType type) {
    if (waveRunning ||
        victory ||
        failed ||
        padIndex < 0 ||
        padIndex >= towers.length ||
        towers[padIndex] != null) {
      return false;
    }
    final int price = buildPrices[type]!;
    if (coins < price) return false;
    coins -= price;
    towers[padIndex] = LighthouseTower(padIndex: padIndex, type: type);
    return true;
  }

  bool upgradeTower(int padIndex) {
    if (waveRunning ||
        victory ||
        failed ||
        padIndex < 0 ||
        padIndex >= towers.length) {
      return false;
    }
    final LighthouseTower? tower = towers[padIndex];
    if (tower == null || tower.tier >= 3) return false;
    final int price = upgradePrice(tower);
    if (coins < price) return false;
    coins -= price;
    tower.tier++;
    return true;
  }

  bool cycleTargetRule(int padIndex) {
    if (waveRunning ||
        victory ||
        failed ||
        padIndex < 0 ||
        padIndex >= towers.length) {
      return false;
    }
    final LighthouseTower? tower = towers[padIndex];
    if (tower == null) return false;
    tower.targetRule =
        LighthouseTargetRule.values[(tower.targetRule.index + 1) %
            LighthouseTargetRule.values.length];
    return true;
  }

  bool startWave() {
    if (!canStartWave || towerCount == 0) return false;
    waveRunning = true;
    spawnedInWave = 0;
    _spawnClock = 0;
    return true;
  }

  LighthouseStepResult usePulse() {
    if (!waveRunning || pulseCharges <= 0 || enemies.isEmpty) {
      return const LighthouseStepResult();
    }
    pulseCharges--;
    final int power = 4 + scenario.level ~/ 5;
    int kills = 0;
    for (final LighthouseEnemyState enemy in enemies) {
      if (!enemy.alive) continue;
      _damage(enemy, power, armorPierce: 1);
      enemy.slowedFor = math.max(enemy.slowedFor, 1.4);
      if (!enemy.alive) {
        kills++;
        coins += enemy.spec.reward;
      }
    }
    totalKills += kills;
    enemies.removeWhere((LighthouseEnemyState enemy) => !enemy.alive);
    return LighthouseStepResult(
      kills: kills,
      shots: 1,
      pulseUsed: true,
      victory: victory,
      failed: failed,
    );
  }

  LighthouseStepResult step(double deltaSeconds) {
    if (!waveRunning || victory || failed || deltaSeconds <= 0) {
      return LighthouseStepResult(victory: victory, failed: failed);
    }
    final double elapsed = deltaSeconds.clamp(0, .05).toDouble();
    final int substeps = math.max(1, (elapsed / (1 / 60)).ceil());
    final double dt = elapsed / substeps;
    int spawned = 0;
    int kills = 0;
    int escapes = 0;
    int shots = 0;
    for (int tick = 0; tick < substeps; tick++) {
      final LighthouseWaveSpec wave = currentWave!;
      _spawnClock -= dt;
      if (spawnedInWave < wave.enemies.length && _spawnClock <= 0) {
        final LighthouseEnemyState enemy = LighthouseEnemyState(
          wave.enemies[spawnedInWave],
        )..health = wave.enemies[spawnedInWave].health;
        enemies.add(enemy);
        spawnedInWave++;
        spawned++;
        _spawnClock = wave.interval;
      }
      for (final LighthouseEnemyState enemy in enemies) {
        if (enemy.slowedFor > 0) {
          enemy.slowedFor = math.max(0, enemy.slowedFor - dt);
        }
        final double slow = enemy.slowedFor > 0 ? .54 : 1;
        enemy.progress +=
            enemy.spec.speed * slow * dt / _routeLength(enemy.spec.routeBranch);
        if (enemy.progress >= 1) {
          enemy.health = 0;
          lives -= enemy.spec.kind == LighthouseEnemyKind.boss ? 4 : 1;
          escapes++;
          totalEscapes++;
        }
      }
      enemies.removeWhere((LighthouseEnemyState enemy) => !enemy.alive);
      if (lives <= 0) {
        lives = 0;
        failed = true;
        waveRunning = false;
        break;
      }
      for (final LighthouseTower? tower in towers) {
        if (tower == null) continue;
        tower.cooldown = math.max(0, tower.cooldown - dt);
        if (tower.cooldown <= 0 && _fire(tower)) {
          shots++;
          totalShots++;
          final double cooldown = switch (tower.type) {
            LighthouseTowerType.ballista => .58 - tower.tier * .055,
            LighthouseTowerType.frost => .42 - tower.tier * .035,
            LighthouseTowerType.mortar => 1.16 - tower.tier * .10,
          };
          tower.cooldown = cooldown.clamp(.24, 1.2).toDouble();
        }
      }
      for (final LighthouseEnemyState enemy in enemies) {
        if (!enemy.alive) {
          kills++;
          totalKills++;
          coins += enemy.spec.reward;
        }
      }
      enemies.removeWhere((LighthouseEnemyState enemy) => !enemy.alive);
      if (spawnedInWave >= wave.enemies.length && enemies.isEmpty) {
        waveRunning = false;
        coins += 65 + scenario.level * 3 + wave.index * 8;
        waveIndex++;
        if (waveIndex >= scenario.waves.length) victory = true;
        break;
      }
    }
    return LighthouseStepResult(
      spawned: spawned,
      kills: kills,
      escapes: escapes,
      shots: shots,
      waveCleared: !waveRunning && !failed && !victory,
      victory: victory,
      failed: failed,
    );
  }

  bool _fire(LighthouseTower tower) {
    final Offset center = scenario.pads[tower.padIndex];
    final double range = switch (tower.type) {
      LighthouseTowerType.ballista => .34 + tower.tier * .018,
      LighthouseTowerType.frost => .29 + tower.tier * .015,
      LighthouseTowerType.mortar => .40 + tower.tier * .018,
    };
    final List<LighthouseEnemyState> targets = enemies
        .where((LighthouseEnemyState enemy) {
          if (!enemy.alive) return false;
          final Offset position = _positionAt(
            enemy.progress,
            enemy.spec.routeBranch,
          );
          return (position - center).distance <= range;
        })
        .toList(growable: false);
    if (targets.isEmpty) return false;
    targets.sort((LighthouseEnemyState a, LighthouseEnemyState b) {
      return switch (tower.targetRule) {
        LighthouseTargetRule.first => a.progress.compareTo(b.progress),
        LighthouseTargetRule.last => b.progress.compareTo(a.progress),
        LighthouseTargetRule.strongest => b.health.compareTo(a.health),
      };
    });
    final LighthouseEnemyState target = targets.first;
    final int baseDamage = switch (tower.type) {
      LighthouseTowerType.ballista => 3 + tower.tier,
      LighthouseTowerType.frost => 1 + (tower.tier >= 3 ? 1 : 0),
      LighthouseTowerType.mortar => 4 + tower.tier * 2,
    };
    if (tower.type == LighthouseTowerType.mortar) {
      final Offset targetPosition = _positionAt(
        target.progress,
        target.spec.routeBranch,
      );
      for (final LighthouseEnemyState enemy in enemies) {
        if ((_positionAt(enemy.progress, enemy.spec.routeBranch) -
                    targetPosition)
                .distance <=
            .09) {
          _damage(enemy, baseDamage, armorPierce: tower.tier);
        }
      }
    } else {
      _damage(
        target,
        baseDamage,
        armorPierce: tower.type == LighthouseTowerType.ballista
            ? 1 + tower.tier ~/ 2
            : 0,
      );
      if (tower.type == LighthouseTowerType.frost) {
        target.slowedFor = math.max(target.slowedFor, 1.5 + tower.tier * .35);
      }
    }
    return true;
  }

  void _damage(
    LighthouseEnemyState enemy,
    int amount, {
    required int armorPierce,
  }) {
    if (!enemy.alive) return;
    final int effective = math.max(
      1,
      amount - math.max(0, enemy.spec.armor - armorPierce),
    );
    enemy.health -= effective;
  }

  List<Offset> _pathFor(int branch) =>
      branch == 0 ? scenario.path : scenario.alternatePath;

  double _routeLength(int branch) {
    final List<Offset> path = _pathFor(branch);
    double length = 0;
    for (int index = 1; index < path.length; index++) {
      length += (path[index] - path[index - 1]).distance;
    }
    return length;
  }

  Offset _positionAt(double progress, int branch) {
    final List<Offset> path = _pathFor(branch);
    double length = _routeLength(branch) * progress.clamp(0, 1).toDouble();
    for (int index = 1; index < path.length; index++) {
      final Offset start = path[index - 1];
      final Offset end = path[index];
      final double segmentLength = (end - start).distance;
      if (length <= segmentLength || index == path.length - 1) {
        final double t = (length / segmentLength).clamp(0, 1).toDouble();
        return Offset.lerp(start, end, t)!;
      }
      length -= segmentLength;
    }
    return path.last;
  }
}
