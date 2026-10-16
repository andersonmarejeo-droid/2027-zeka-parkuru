import 'secret_room_scenario.dart';

enum SecretRoomPhase {
  roleHandoff,
  roleVisible,
  discussion,
  voteHandoff,
  ballotOpen,
  result,
}

class SecretRoomOutcome {
  const SecretRoomOutcome({
    required this.suspect,
    required this.voteCount,
    required this.requiredVotes,
    required this.isTie,
    required this.crewWon,
    required this.correctVotes,
  });

  final int? suspect;
  final int voteCount;
  final int requiredVotes;
  final bool isTie;
  final bool crewWon;
  final int correctVotes;

  bool get reachedMajority => suspect != null && voteCount >= requiredVotes;
}

/// Local pass-and-play state machine. Votes and identities are concealed until
/// the last ballot, so one device can be handed around without leaking state.
class SecretRoomEngine {
  SecretRoomEngine({required this.scenario});

  final SecretRoomScenario scenario;
  SecretRoomPhase phase = SecretRoomPhase.roleHandoff;
  int activePlayer = 0;
  bool _roleCardVisible = false;
  final List<int> _votes = <int>[];

  bool get roleCardVisible => _roleCardVisible;
  int get votesSubmitted => _votes.length;
  bool get canRevealRole => phase == SecretRoomPhase.roleHandoff;
  bool get canHideRole => phase == SecretRoomPhase.roleVisible;
  bool get canStartVoting => phase == SecretRoomPhase.discussion;
  bool get canOpenBallot => phase == SecretRoomPhase.voteHandoff;
  bool get canVote => phase == SecretRoomPhase.ballotOpen;
  bool get isComplete => phase == SecretRoomPhase.result;

  List<int> get revealedVotes =>
      isComplete ? List<int>.unmodifiable(_votes) : const <int>[];

  bool revealRole() {
    if (!canRevealRole) return false;
    _roleCardVisible = true;
    phase = SecretRoomPhase.roleVisible;
    return true;
  }

  bool hideAndPass() {
    if (!canHideRole) return false;
    _roleCardVisible = false;
    if (activePlayer + 1 == scenario.playerCount) {
      phase = SecretRoomPhase.discussion;
    } else {
      activePlayer++;
      phase = SecretRoomPhase.roleHandoff;
    }
    return true;
  }

  bool startVoting() {
    if (!canStartVoting) return false;
    activePlayer = 0;
    phase = SecretRoomPhase.voteHandoff;
    return true;
  }

  bool openBallot() {
    if (!canOpenBallot) return false;
    phase = SecretRoomPhase.ballotOpen;
    return true;
  }

  bool submitVote(int suspect) {
    if (!canVote || suspect < 0 || suspect >= scenario.playerCount) {
      return false;
    }
    if (suspect == activePlayer || _votes.length != activePlayer) return false;
    _votes.add(suspect);
    if (_votes.length == scenario.playerCount) {
      phase = SecretRoomPhase.result;
    } else {
      activePlayer++;
      phase = SecretRoomPhase.voteHandoff;
    }
    return true;
  }

  SecretRoomOutcome? get outcome {
    if (!isComplete) return null;
    final List<int> counts = List<int>.filled(scenario.playerCount, 0);
    for (final int vote in _votes) {
      counts[vote]++;
    }
    final int high = counts.reduce((int a, int b) => a > b ? a : b);
    final List<int> leaders = <int>[
      for (int player = 0; player < counts.length; player++)
        if (counts[player] == high) player,
    ];
    final bool tie = leaders.length > 1;
    final int? suspect = tie || high < scenario.requiredVotes
        ? null
        : leaders.single;
    final int correctVotes = suspect == null
        ? 0
        : _votes.where((int votedFor) => votedFor == suspect).length;
    return SecretRoomOutcome(
      suspect: suspect,
      voteCount: suspect == null ? high : high,
      requiredVotes: scenario.requiredVotes,
      isTie: tie,
      crewWon: suspect != null && scenario.isSaboteur(suspect),
      correctVotes: correctVotes,
    );
  }
}
