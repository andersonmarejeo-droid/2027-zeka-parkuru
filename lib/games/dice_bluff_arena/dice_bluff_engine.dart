import 'dice_bluff_scenario.dart';

enum DiceBluffMode { versusComputer, localDuel }

enum DiceBluffPhase { rollHandoff, privateRoll, bidding, result }

enum DiceBluffAction { raised, challenged, invalid }

class DiceBluffBid {
  const DiceBluffBid({
    required this.player,
    required this.count,
    required this.face,
  });

  final int player;
  final int count;
  final int face;
}

class DiceBluffRoundResult {
  const DiceBluffRoundResult({
    required this.bid,
    required this.challenger,
    required this.actualCount,
    required this.challengeWasCorrect,
    required this.losingPlayer,
    required this.winningPlayer,
  });

  final DiceBluffBid bid;
  final int challenger;
  final int actualCount;
  final bool challengeWasCorrect;
  final int losingPlayer;
  final int winningPlayer;
}

class DiceBluffEngine {
  DiceBluffEngine({
    required this.scenario,
    required this.mode,
    required this.firstBidder,
  }) : activePlayer = 0;

  final DiceBluffScenario scenario;
  final DiceBluffMode mode;
  final int firstBidder;

  DiceBluffPhase phase = DiceBluffPhase.rollHandoff;
  int _rollViewer = 0;
  int activePlayer;
  DiceBluffBid? currentBid;
  DiceBluffRoundResult? result;

  bool get isComputerTurn =>
      mode == DiceBluffMode.versusComputer &&
      phase == DiceBluffPhase.bidding &&
      activePlayer == 1;

  bool get canOpenRoll => phase == DiceBluffPhase.rollHandoff;
  bool get canHideRoll => phase == DiceBluffPhase.privateRoll;
  bool get canBid => phase == DiceBluffPhase.bidding && !isComputerTurn;
  bool get isFinished => phase == DiceBluffPhase.result;
  int get rollViewer => _rollViewer;

  /// Dice are unavailable outside their one-player reveal or the final result.
  List<int> get visibleDice {
    if (phase == DiceBluffPhase.privateRoll) {
      return List<int>.unmodifiable(_diceFor(_rollViewer));
    }
    return const <int>[];
  }

  List<int> get revealedHumanDice =>
      isFinished ? List<int>.unmodifiable(scenario.humanDice) : const <int>[];
  List<int> get revealedOpponentDice => isFinished
      ? List<int>.unmodifiable(scenario.opponentDice)
      : const <int>[];

  List<int> _diceFor(int player) =>
      player == 0 ? scenario.humanDice : scenario.opponentDice;

  bool openPrivateRoll() {
    if (!canOpenRoll) return false;
    phase = DiceBluffPhase.privateRoll;
    return true;
  }

  bool hideRollAndPass() {
    if (!canHideRoll) return false;
    if (mode == DiceBluffMode.versusComputer || _rollViewer == 1) {
      activePlayer = firstBidder;
      phase = DiceBluffPhase.bidding;
    } else {
      _rollViewer = 1;
      phase = DiceBluffPhase.rollHandoff;
    }
    return true;
  }

  DiceBluffAction raiseBid({
    required int player,
    required int count,
    required int face,
  }) {
    if (phase != DiceBluffPhase.bidding ||
        player != activePlayer ||
        isFinished) {
      return DiceBluffAction.invalid;
    }
    if (count < 1 ||
        count > scenario.totalDice ||
        face < 1 ||
        face > scenario.faceCount) {
      return DiceBluffAction.invalid;
    }
    final DiceBluffBid? previous = currentBid;
    if (previous != null &&
        !(count > previous.count ||
            (count == previous.count && face > previous.face))) {
      return DiceBluffAction.invalid;
    }
    currentBid = DiceBluffBid(player: player, count: count, face: face);
    activePlayer = 1 - player;
    return DiceBluffAction.raised;
  }

  DiceBluffAction challenge({required int player}) {
    final DiceBluffBid? bid = currentBid;
    if (phase != DiceBluffPhase.bidding ||
        bid == null ||
        player != activePlayer ||
        isFinished) {
      return DiceBluffAction.invalid;
    }
    final int actual = _actualCount(bid.face);
    final bool trueBid = actual >= bid.count;
    final int loser = trueBid ? player : bid.player;
    result = DiceBluffRoundResult(
      bid: bid,
      challenger: player,
      actualCount: actual,
      challengeWasCorrect: !trueBid,
      losingPlayer: loser,
      winningPlayer: 1 - loser,
    );
    phase = DiceBluffPhase.result;
    return DiceBluffAction.challenged;
  }

  DiceBluffAction playComputerTurn() {
    if (!isComputerTurn) return DiceBluffAction.invalid;
    final List<int> ownDice = scenario.opponentDice;
    final DiceBluffBid? previous = currentBid;
    if (previous != null) {
      final int ownSupport = ownDice
          .where(
            (int die) =>
                die == previous.face ||
                (scenario.wildFace != null &&
                    scenario.wildFace != previous.face &&
                    die == scenario.wildFace),
          )
          .length;
      final int hiddenDice = scenario.diceCount;
      final double estimate = ownSupport + hiddenDice / scenario.faceCount;
      final double tolerance = switch (scenario.opponentStyle) {
        DiceOpponentStyle.measured => .25,
        DiceOpponentStyle.reader => .85,
        DiceOpponentStyle.daring => 1.45,
      };
      if (previous.count > estimate + tolerance ||
          previous.count > scenario.totalDice) {
        return challenge(player: 1);
      }
      if (previous.face < scenario.faceCount) {
        return raiseBid(
          player: 1,
          count: previous.count,
          face: previous.face + 1,
        );
      }
      if (previous.count < scenario.totalDice) {
        return raiseBid(player: 1, count: previous.count + 1, face: 1);
      }
      return challenge(player: 1);
    }
    final Map<int, int> ownCounts = <int, int>{
      for (int face = 1; face <= scenario.faceCount; face++)
        face: ownDice.where((int die) => die == face).length,
    };
    final int bestFace = ownCounts.keys.reduce(
      (int a, int b) => ownCounts[a]! >= ownCounts[b]! ? a : b,
    );
    final int openingCount =
        (ownCounts[bestFace]! +
                (scenario.diceCount / scenario.faceCount).floor())
            .clamp(1, scenario.totalDice);
    return raiseBid(player: 1, count: openingCount, face: bestFace);
  }

  int _actualCount(int face) {
    int total = 0;
    for (final List<int> dice in <List<int>>[
      scenario.humanDice,
      scenario.opponentDice,
    ]) {
      for (final int die in dice) {
        if (die == face ||
            (scenario.wildFace != null &&
                scenario.wildFace != face &&
                die == scenario.wildFace)) {
          total++;
        }
      }
    }
    return total;
  }
}
