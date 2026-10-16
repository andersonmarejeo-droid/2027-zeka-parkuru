import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'air_hockey_scenario.dart';

enum AirHockeySide { player, opponent }

class AirHockeyStepResult {
  const AirHockeyStepResult({
    this.playerHit = false,
    this.opponentHit = false,
    this.pointWinner,
    this.smashUsed = false,
    this.matchOver = false,
    this.playerWon = false,
  });

  final bool playerHit;
  final bool opponentHit;
  final AirHockeySide? pointWinner;
  final bool smashUsed;
  final bool matchOver;
  final bool playerWon;
}

/// Fixed-step puck, rail, bumper, mallet and opponent behavior for the arena.
class AirHockeyEngine {
  AirHockeyEngine({required this.scenario}) {
    _random = math.Random(scenario.seed ^ 0xA17C);
    _serve();
  }

  final AirHockeyScenario scenario;
  late final math.Random _random;

  static const double puckRadius = .024;
  static const double paddleRadius = .083;
  static const double bumperRadius = .052;

  Offset puck = Offset.zero;
  Offset velocity = Offset.zero;
  Offset playerMallet = const Offset(.5, .79);
  Offset opponentMallet = const Offset(.5, .21);
  Offset _playerTarget = const Offset(.5, .79);
  Offset _previousPlayerMallet = const Offset(.5, .79);
  final List<Offset> trail = <Offset>[];
  double elapsedSeconds = 0;
  double _pointDelay = 0;
  double _smashQueue = 0;
  int playerGoals = 0;
  int opponentGoals = 0;
  int playerHits = 0;
  int opponentHits = 0;
  int longestRally = 0;
  int currentRallyHits = 0;
  int smashesUsed = 0;
  int _serveNumber = 0;
  bool matchOver = false;
  bool playerWon = false;
  bool _smashAvailable = true;

  bool get waitingForServe => _pointDelay > 0;
  double get goalHalfWidth => scenario.goalWidth / 2;
  bool get smashAvailable => _smashAvailable;

  void queueSmash() {
    if (!matchOver && !waitingForServe && _smashAvailable) _smashQueue = .28;
  }

  AirHockeyStepResult step({
    required double deltaSeconds,
    required Offset playerTarget,
    bool smash = false,
  }) {
    if (matchOver || deltaSeconds <= 0) {
      return AirHockeyStepResult(matchOver: matchOver, playerWon: playerWon);
    }
    final double delta = deltaSeconds.clamp(0, .025).toDouble();
    elapsedSeconds += delta;
    if (_smashQueue > 0) _smashQueue = math.max(0, _smashQueue - delta);
    if (_pointDelay > 0) {
      _pointDelay = math.max(0, _pointDelay - delta);
      if (_pointDelay == 0) _serve();
      return const AirHockeyStepResult();
    }

    _playerTarget = Offset(
      playerTarget.dx.clamp(.09, .91).toDouble(),
      playerTarget.dy.clamp(.55, .91).toDouble(),
    );
    _movePlayer(delta);
    _moveOpponent(delta);
    final double surfaceFactor = switch (scenario.surface) {
      AirHockeySurface.slick => 1.04,
      AirHockeySurface.grippy => .93,
      _ => 1,
    };
    puck += velocity * delta;
    trail.insert(0, puck);
    if (trail.length > 10) trail.removeRange(10, trail.length);
    velocity *= math.exp(-scenario.friction * surfaceFactor * delta);
    if (velocity.distance < .19) {
      final double direction = velocity.distance < .001
          ? math.pi / 2
          : math.atan2(velocity.dy, velocity.dx);
      velocity = Offset(math.cos(direction), math.sin(direction)) * .19;
    }

    if (_collideBumper()) {
      // The bumper impulses are deliberately low enough to preserve a readable rally.
    }
    if (puck.dx < .035) {
      puck = Offset(.035, puck.dy);
      velocity = Offset(velocity.dx.abs() * .9, velocity.dy);
    } else if (puck.dx > .965) {
      puck = Offset(.965, puck.dy);
      velocity = Offset(-velocity.dx.abs() * .9, velocity.dy);
    }

    if (velocity.dy > 0 &&
        (puck - playerMallet).distance <= paddleRadius + puckRadius) {
      final bool useSmash = (smash || _smashQueue > 0) && _smashAvailable;
      _playerContact(delta, useSmash: useSmash);
      _smashQueue = 0;
      playerHits++;
      currentRallyHits++;
      longestRally = math.max(longestRally, currentRallyHits);
      if (useSmash) {
        smashesUsed++;
        _smashAvailable = false;
      }
      return AirHockeyStepResult(playerHit: true, smashUsed: useSmash);
    }
    if (velocity.dy < 0 &&
        (puck - opponentMallet).distance <= paddleRadius + puckRadius) {
      final bool miss = _random.nextDouble() < scenario.opponentErrorChance;
      if (miss) {
        return _awardPoint(AirHockeySide.player);
      }
      _opponentContact();
      opponentHits++;
      currentRallyHits++;
      longestRally = math.max(longestRally, currentRallyHits);
      return const AirHockeyStepResult(opponentHit: true);
    }

    if (puck.dy < .025) {
      if ((puck.dx - .5).abs() <= goalHalfWidth) {
        return _awardPoint(AirHockeySide.player);
      }
      puck = Offset(puck.dx, .025);
      velocity = Offset(velocity.dx, velocity.dy.abs() * .88);
    } else if (puck.dy > .975) {
      if ((puck.dx - .5).abs() <= goalHalfWidth) {
        return _awardPoint(AirHockeySide.opponent);
      }
      puck = Offset(puck.dx, .975);
      velocity = Offset(velocity.dx, -velocity.dy.abs() * .88);
    }
    return const AirHockeyStepResult();
  }

  void _movePlayer(double delta) {
    _previousPlayerMallet = playerMallet;
    playerMallet = _moveToward(
      playerMallet,
      _playerTarget,
      scenario.paddleSpeed * delta,
    );
  }

  void _moveOpponent(double delta) {
    Offset target = const Offset(.5, .21);
    if (velocity.dy < 0) {
      final double timeToLine =
          ((puck.dy - .20) / math.max(.2, velocity.dy.abs()))
              .clamp(0, 1.2)
              .toDouble();
      target = Offset(
        (puck.dx + velocity.dx * timeToLine).clamp(.09, .91).toDouble(),
        .21,
      );
    }
    opponentMallet = _moveToward(
      opponentMallet,
      target,
      scenario.opponentSpeed * delta,
    );
  }

  Offset _moveToward(Offset current, Offset target, double maxDistance) {
    final Offset difference = target - current;
    if (difference.distance <= maxDistance) return target;
    return current + difference / difference.distance * maxDistance;
  }

  void _playerContact(double delta, {required bool useSmash}) {
    Offset normal = puck - playerMallet;
    if (normal.distance < .001) normal = const Offset(0, -1);
    normal = normal / normal.distance;
    final Offset paddleVelocity =
        (playerMallet - _previousPlayerMallet) / math.max(.001, delta);
    final double power = useSmash ? 1.48 : 1.04;
    puck = playerMallet + normal * (paddleRadius + puckRadius + .003);
    velocity = Offset(
      (normal.dx * scenario.puckSpeed * 1.42 + paddleVelocity.dx * .43)
          .clamp(-.88, .88)
          .toDouble(),
      -math.max(
        .38,
        scenario.puckSpeed * power + paddleVelocity.dy.abs() * .07,
      ),
    );
  }

  void _opponentContact() {
    Offset normal = puck - opponentMallet;
    if (normal.distance < .001) normal = const Offset(0, 1);
    normal = normal / normal.distance;
    final double error =
        (_random.nextDouble() - .5) *
        (.55 + scenario.opponentErrorChance * 1.5);
    puck = opponentMallet + normal * (paddleRadius + puckRadius + .003);
    velocity = Offset(
      (normal.dx * scenario.puckSpeed * 1.25 + error)
          .clamp(-.82, .82)
          .toDouble(),
      math.max(.36, scenario.puckSpeed * .98),
    );
  }

  bool _collideBumper() {
    bool collided = false;
    for (final Offset bumper in scenario.bumpers) {
      final Offset difference = puck - bumper;
      final double distance = difference.distance;
      final double minimum = bumperRadius + puckRadius;
      if (distance >= minimum || distance < .0001) continue;
      final Offset normal = difference / distance;
      puck = bumper + normal * minimum;
      final double approach = velocity.dx * normal.dx + velocity.dy * normal.dy;
      if (approach < 0) {
        velocity = velocity - normal * (2 * approach);
        velocity *= scenario.surface == AirHockeySurface.rebound ? 1.13 : 1.04;
      }
      collided = true;
    }
    return collided;
  }

  AirHockeyStepResult _awardPoint(AirHockeySide winner) {
    currentRallyHits = 0;
    if (winner == AirHockeySide.player) {
      playerGoals++;
    } else {
      opponentGoals++;
    }
    if (playerGoals >= scenario.goalsToWin ||
        opponentGoals >= scenario.goalsToWin) {
      matchOver = true;
      playerWon = playerGoals > opponentGoals;
    } else {
      _pointDelay = .68;
      puck = const Offset(.5, .5);
      velocity = Offset.zero;
      trail.clear();
    }
    return AirHockeyStepResult(
      pointWinner: winner,
      matchOver: matchOver,
      playerWon: playerWon,
    );
  }

  void _serve() {
    final double offset =
        scenario.serveOffsets[_serveNumber % scenario.serveOffsets.length];
    _serveNumber++;
    puck = Offset((.5 + offset).clamp(.16, .84).toDouble(), .48);
    velocity = Offset(offset * .2, scenario.puckSpeed * .75);
    trail.clear();
    playerMallet = Offset(.5, .79);
    opponentMallet = Offset(.5, .21);
    _previousPlayerMallet = playerMallet;
    _playerTarget = playerMallet;
    _smashAvailable = true;
  }
}
