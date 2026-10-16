import 'penalty_scenario.dart';

enum PenaltyPhase {
  playerShot,
  shotFlight,
  opponentRunUp,
  saveFlight,
  complete,
}

enum PenaltyOutcome { goal, saved, wide, conceded, keeperSave }

class PenaltyActionResult {
  const PenaltyActionResult({
    this.outcome,
    this.matchOver = false,
    this.playerWon = false,
    this.automatic = false,
  });

  final PenaltyOutcome? outcome;
  final bool matchOver;
  final bool playerWon;
  final bool automatic;
}

/// Small deterministic state machine for both sides of a penalty shootout.
class PenaltyMindgameEngine {
  PenaltyMindgameEngine({required this.scenario});

  final PenaltyScenario scenario;

  PenaltyPhase phase = PenaltyPhase.playerShot;
  PenaltyOutcome? lastOutcome;
  PenaltyLane? lastPlayerLane;
  PenaltyLane? lastKeeperLane;
  double phaseSeconds = 0;
  int roundIndex = 0;
  int playerGoals = 0;
  int opponentGoals = 0;
  int playerSaves = 0;
  int playerShotsOnTarget = 0;
  int playerWideShots = 0;
  int perfectReads = 0;
  int deceptionsRead = 0;
  bool matchOver = false;
  bool playerWon = false;

  int get regulationRounds => scenario.roundCount;
  int get currentRound => roundIndex + 1;
  bool get inSuddenDeath => roundIndex >= scenario.roundCount;
  double get runUpProgress =>
      (phaseSeconds / scenario.runUpSeconds).clamp(0, 1.5).toDouble();
  bool get canDive => phase == PenaltyPhase.opponentRunUp;
  PenaltyBodyCue get currentCue => scenario.cueAt(roundIndex);
  PenaltyLane get currentKickLane => scenario.kickAt(roundIndex);
  PenaltyLane get currentKeeperRead => scenario.keeperReadAt(roundIndex);
  double get currentShotPower => scenario.powerAt(roundIndex);

  PenaltyActionResult shoot({
    required PenaltyLane lane,
    required double power,
  }) {
    if (matchOver || phase != PenaltyPhase.playerShot) {
      return PenaltyActionResult(matchOver: matchOver, playerWon: playerWon);
    }
    lastPlayerLane = lane;
    final double quality =
        (1 - (power.clamp(.4, 1).toDouble() - currentShotPower).abs() / .43)
            .clamp(0, 1)
            .toDouble();
    final bool tooSoft = power < .46;
    final bool keeperBreak = quality >= scenario.keeperSkill + .09;
    final bool goal =
        !tooSoft &&
        (lane != currentKeeperRead || keeperBreak || quality >= .96);
    if (goal) {
      playerGoals++;
      playerShotsOnTarget++;
      lastOutcome = PenaltyOutcome.goal;
    } else if (tooSoft) {
      playerWideShots++;
      lastOutcome = PenaltyOutcome.wide;
    } else {
      playerShotsOnTarget++;
      lastOutcome = PenaltyOutcome.saved;
    }
    phase = PenaltyPhase.shotFlight;
    phaseSeconds = 0;
    return PenaltyActionResult(outcome: lastOutcome);
  }

  PenaltyActionResult dive({required PenaltyLane lane}) {
    if (matchOver || phase != PenaltyPhase.opponentRunUp) {
      return PenaltyActionResult(matchOver: matchOver, playerWon: playerWon);
    }
    lastKeeperLane = lane;
    final double timingError = (runUpProgress - .66).abs();
    final bool timingOk = timingError <= scenario.diveTimingWindow;
    final bool saved = lane == currentKickLane && timingOk;
    if (saved) {
      playerSaves++;
      lastOutcome = PenaltyOutcome.keeperSave;
      if (currentCue.majority == currentKickLane) perfectReads++;
      if (currentCue.shoulder != currentCue.hip &&
          currentCue.hip == currentKickLane) {
        deceptionsRead++;
      }
    } else {
      opponentGoals++;
      lastOutcome = PenaltyOutcome.conceded;
    }
    phase = PenaltyPhase.saveFlight;
    phaseSeconds = 0;
    return PenaltyActionResult(outcome: lastOutcome);
  }

  PenaltyActionResult? step(double deltaSeconds) {
    if (matchOver || deltaSeconds <= 0) return null;
    final double delta = deltaSeconds.clamp(0, .04).toDouble();
    phaseSeconds += delta;
    if (phase == PenaltyPhase.shotFlight && phaseSeconds >= .48) {
      phase = PenaltyPhase.opponentRunUp;
      phaseSeconds = 0;
      return null;
    }
    if (phase == PenaltyPhase.opponentRunUp &&
        phaseSeconds >= scenario.runUpSeconds + .28) {
      opponentGoals++;
      lastOutcome = PenaltyOutcome.conceded;
      phase = PenaltyPhase.saveFlight;
      phaseSeconds = 0;
      return const PenaltyActionResult(
        outcome: PenaltyOutcome.conceded,
        automatic: true,
      );
    }
    if (phase == PenaltyPhase.saveFlight && phaseSeconds >= .52) {
      _advanceRound();
    }
    return PenaltyActionResult(matchOver: matchOver, playerWon: playerWon);
  }

  void _advanceRound() {
    roundIndex++;
    phaseSeconds = 0;
    if (roundIndex >= scenario.roundCount && playerGoals != opponentGoals) {
      _finish();
      return;
    }
    if (roundIndex >= scenario.roundCount + scenario.maxOvertimeRounds) {
      _finish();
      return;
    }
    phase = PenaltyPhase.playerShot;
  }

  void _finish() {
    matchOver = true;
    playerWon = playerGoals > opponentGoals;
    phase = PenaltyPhase.complete;
  }
}
