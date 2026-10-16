import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'table_tennis_scenario.dart';

enum TableTennisShot { topspin, slice, block }

enum RallyPointWinner { player, opponent }

class RallyStepResult {
  const RallyStepResult({
    this.playerHit = false,
    this.opponentHit = false,
    this.pointWinner,
    this.playerMiss = false,
    this.opponentMiss = false,
    this.matchOver = false,
    this.playerWon = false,
  });

  final bool playerHit;
  final bool opponentHit;
  final RallyPointWinner? pointWinner;
  final bool playerMiss;
  final bool opponentMiss;
  final bool matchOver;
  final bool playerWon;
}

/// Deterministic, frame-rate independent tabletop physics and opponent model.
class TableTennisEngine {
  TableTennisEngine({required this.scenario}) {
    _random = math.Random(scenario.seed ^ 0x52A7);
    _serve();
  }

  final TableTennisScenario scenario;
  late final math.Random _random;

  static const double opponentLine = .18;
  static const double playerLine = .82;
  static const double edgeLeft = .075;
  static const double edgeRight = .925;

  Offset ball = Offset.zero;
  Offset velocity = Offset.zero;
  final List<Offset> trail = <Offset>[];
  double playerX = .5;
  double opponentX = .5;
  double elapsedSeconds = 0;
  double _spin = 0;
  double _reactionLeft = 0;
  double _pointDelay = 0;
  int playerPoints = 0;
  int opponentPoints = 0;
  int playerHits = 0;
  int opponentHits = 0;
  int currentRallyHits = 0;
  int longestRally = 0;
  int unforcedErrors = 0;
  bool matchOver = false;
  bool playerWon = false;
  TableTennisShot lastShot = TableTennisShot.block;

  int get rallyNumber => playerHits + opponentHits + 1;
  bool get waitingForServe => _pointDelay > 0;

  RallyStepResult step({
    required double deltaSeconds,
    required double playerPaddleX,
    TableTennisShot? shot,
  }) {
    if (matchOver || deltaSeconds <= 0) {
      return RallyStepResult(matchOver: matchOver, playerWon: playerWon);
    }
    final double delta = deltaSeconds.clamp(0, .025).toDouble();
    elapsedSeconds += delta;
    playerX = playerPaddleX.clamp(edgeLeft, edgeRight).toDouble();

    if (_pointDelay > 0) {
      _pointDelay = math.max(0, _pointDelay - delta);
      if (_pointDelay == 0) _serve();
      return const RallyStepResult();
    }

    _moveOpponent(delta);
    final double previousY = ball.dy;
    _spin *= math.exp(-1.9 * delta);
    velocity = Offset(velocity.dx + _spin * delta, velocity.dy);
    ball += velocity * delta;
    trail.insert(0, ball);
    if (trail.length > 12) trail.removeRange(12, trail.length);

    if (ball.dx < edgeLeft) {
      ball = Offset(edgeLeft, ball.dy);
      velocity = Offset(velocity.dx.abs() * .88, velocity.dy);
    } else if (ball.dx > edgeRight) {
      ball = Offset(edgeRight, ball.dy);
      velocity = Offset(-velocity.dx.abs() * .88, velocity.dy);
    }

    if (velocity.dy < 0 &&
        previousY >= opponentLine &&
        ball.dy <= opponentLine) {
      return _opponentContact();
    }

    if (velocity.dy > 0 && previousY <= playerLine && ball.dy >= playerLine) {
      final double paddleOffset = ball.dx - playerX;
      if (shot != null && ball.dy <= .895 && paddleOffset.abs() <= .155) {
        _playerContact(shot, paddleOffset);
        return const RallyStepResult(playerHit: true);
      }
      if (ball.dy >= .965) {
        unforcedErrors++;
        return _awardPoint(RallyPointWinner.opponent, playerMiss: true);
      }
    }

    if (ball.dy < .04 || ball.dy > .98) {
      final RallyPointWinner winner = ball.dy < .04
          ? RallyPointWinner.player
          : RallyPointWinner.opponent;
      return _awardPoint(
        winner,
        playerMiss: winner == RallyPointWinner.opponent,
        opponentMiss: winner == RallyPointWinner.player,
      );
    }
    return const RallyStepResult();
  }

  void _moveOpponent(double delta) {
    if (_reactionLeft > 0) {
      _reactionLeft = math.max(0, _reactionLeft - delta);
      return;
    }
    final double secondsToLine =
        ((ball.dy - opponentLine) / math.max(.20, velocity.dy.abs()))
            .clamp(0, 1.8)
            .toDouble();
    final double predicted = (ball.dx + velocity.dx * secondsToLine).clamp(
      edgeLeft,
      edgeRight,
    );
    final double error = predicted - opponentX;
    final double movement = error
        .clamp(
          -scenario.opponentMoveSpeed * delta,
          scenario.opponentMoveSpeed * delta,
        )
        .toDouble();
    opponentX = (opponentX + movement).clamp(edgeLeft, edgeRight).toDouble();
  }

  void _playerContact(TableTennisShot shot, double paddleOffset) {
    playerHits++;
    currentRallyHits++;
    longestRally = math.max(longestRally, currentRallyHits);
    lastShot = shot;
    final double curve = switch (shot) {
      TableTennisShot.topspin => paddleOffset.sign * .045,
      TableTennisShot.slice => paddleOffset.sign * .105,
      TableTennisShot.block => 0,
    };
    final double targetX = (ball.dx + paddleOffset * .72 + curve)
        .clamp(.12, .88)
        .toDouble();
    final double speedFactor = switch (shot) {
      TableTennisShot.topspin => 1.17,
      TableTennisShot.slice => .88,
      TableTennisShot.block => .97,
    };
    final double surfaceFactor = switch (scenario.surface) {
      TableSurface.fast => 1.12,
      TableSurface.soft => .90,
      _ => 1.0,
    };
    ball = Offset(ball.dx, playerLine - .006);
    velocity = Offset(
      ((targetX - ball.dx) * 1.32).clamp(-.48, .48).toDouble(),
      -scenario.ballSpeed * speedFactor * surfaceFactor,
    );
    _spin = switch (shot) {
      TableTennisShot.topspin => paddleOffset.sign * .18,
      TableTennisShot.slice => paddleOffset.sign * .30,
      TableTennisShot.block => 0,
    };
    _reactionLeft = scenario.reactionSeconds;
    trail.clear();
  }

  RallyStepResult _opponentContact() {
    final double missChance =
        scenario.opponentErrorChance +
        (lastShot == TableTennisShot.slice ? .065 : 0) +
        (lastShot == TableTennisShot.topspin ? .018 : 0);
    final double reach = .105 + (1 - scenario.opponentErrorChance) * .035;
    if ((ball.dx - opponentX).abs() > reach ||
        _random.nextDouble() < missChance) {
      return _awardPoint(RallyPointWinner.player, opponentMiss: true);
    }

    opponentHits++;
    currentRallyHits++;
    longestRally = math.max(longestRally, currentRallyHits);
    final int pattern =
        scenario.spinSequence[(opponentHits + playerHits) %
            scenario.spinSequence.length];
    final double targetX = switch (pattern) {
      0 => (playerX + (playerX > .5 ? -.25 : .25)).clamp(.14, .86).toDouble(),
      1 => (playerX * .58 + .5 * .42).clamp(.18, .82).toDouble(),
      _ => (edgeLeft + edgeRight - playerX).clamp(.14, .86).toDouble(),
    };
    final double speedFactor = scenario.surface == TableSurface.fast ? 1.06 : 1;
    ball = Offset(ball.dx, opponentLine + .006);
    velocity = Offset(
      ((targetX - ball.dx) * 1.18).clamp(-.44, .44).toDouble(),
      scenario.ballSpeed * speedFactor,
    );
    _spin = (pattern - 1) * .16;
    _reactionLeft = 0;
    trail.clear();
    return const RallyStepResult(opponentHit: true);
  }

  RallyStepResult _awardPoint(
    RallyPointWinner winner, {
    bool playerMiss = false,
    bool opponentMiss = false,
  }) {
    currentRallyHits = 0;
    if (winner == RallyPointWinner.player) {
      playerPoints++;
    } else {
      opponentPoints++;
    }
    final int target = scenario.pointsToWin;
    if (playerPoints >= target || opponentPoints >= target) {
      matchOver = true;
      playerWon = playerPoints > opponentPoints;
    } else {
      _pointDelay = .72;
      ball = const Offset(.5, .5);
      velocity = Offset.zero;
      trail.clear();
    }
    return RallyStepResult(
      pointWinner: winner,
      playerMiss: playerMiss,
      opponentMiss: opponentMiss,
      matchOver: matchOver,
      playerWon: playerWon,
    );
  }

  void _serve() {
    final double startX = (.5 + scenario.serveOffset)
        .clamp(.18, .82)
        .toDouble();
    ball = Offset(startX, opponentLine + .012);
    velocity = Offset(scenario.serveOffset * .24, scenario.ballSpeed * .92);
    opponentX = .5;
    _spin = 0;
    _reactionLeft = 0;
    trail.clear();
  }
}
