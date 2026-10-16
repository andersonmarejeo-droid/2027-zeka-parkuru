import 'dart:math' as math;

import '../shared/content_seed.dart';

class TunnelSwap {
  const TunnelSwap(this.firstLane, this.secondLane);

  final int firstLane;
  final int secondLane;

  String get signature => '$firstLane>$secondLane';
}

class TunnelMovement {
  TunnelMovement({required this.swaps, required this.occluded});

  final List<TunnelSwap> swaps;
  final bool occluded;

  String get signature =>
      '${occluded ? 'x' : 'o'}:${swaps.map((TunnelSwap swap) => swap.signature).join('+')}';
}

/// A shell-game style card tracking puzzle with progressively larger decks.
/// The target card has no persistent marker after launch; its final slot is
/// derived from the same permutation that the animated presentation plays.
class AttentionTunnelScenario {
  AttentionTunnelScenario({
    required this.stage,
    required this.laneCount,
    required this.startTargetLane,
    required this.movements,
    required this.targetLanePath,
    required this.finalTargetLane,
    required this.isPractice,
    required this.round,
    required this.variant,
    required this.movementIntervalMs,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static final List<AttentionTunnelScenario> _practiceDeck =
      _buildPracticeDeck();

  final int stage;
  final int laneCount;
  final int startTargetLane;
  final List<TunnelMovement> movements;
  final List<int> targetLanePath;
  final int finalTargetLane;
  final bool isPractice;
  final int round;
  final int variant;
  final int movementIntervalMs;

  int get cardCount => laneCount;
  int get targetCardId => startTargetLane;
  int get finalTargetCardSlot => finalTargetLane;

  int get movementCount => movements.length;
  int get shutterCount =>
      movements.where((TunnelMovement item) => item.occluded).length;
  int get mistakeLimit => stage <= 6
      ? 3
      : stage <= 16
      ? 2
      : 1;

  String get signature => <String>[
    '$stage:$laneCount:$startTargetLane:$movementIntervalMs',
    for (final TunnelMovement movement in movements) movement.signature,
  ].join('|');

  int get actualTargetLaneMoves {
    int moves = 0;
    for (int index = 1; index < targetLanePath.length; index++) {
      if (targetLanePath[index] != targetLanePath[index - 1]) moves++;
    }
    return moves;
  }

  static AttentionTunnelScenario forCampaignLevel(int level) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, campaignLevels);
    }
    return _build(
      stage: level,
      isPractice: false,
      round: level,
      variant: 0,
      seed: ContentSeed.forLevel(
        gameId: 'attention_tunnel:campaign',
        level: level,
      ),
    );
  }

  static AttentionTunnelScenario forPracticeRound(int round) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    return _practiceDeck[round - 1];
  }

  static List<AttentionTunnelScenario> _buildPracticeDeck() {
    final Set<String> occupied = <String>{
      for (int level = 1; level <= campaignLevels; level++)
        forCampaignLevel(level).signature,
    };
    final List<AttentionTunnelScenario> deck = <AttentionTunnelScenario>[];
    for (int round = 1; round <= uniquePracticeRounds; round++) {
      final int stage = ((round - 1) % campaignLevels) + 1;
      AttentionTunnelScenario? selected;
      for (int attempt = 0; attempt < 20000; attempt++) {
        final AttentionTunnelScenario candidate = _build(
          stage: stage,
          isPractice: true,
          round: round,
          variant: attempt,
          seed: ContentSeed.forLevel(
            gameId: 'attention_tunnel:practice:$attempt',
            level: round,
          ),
        );
        if (occupied.add(candidate.signature)) {
          selected = candidate;
          break;
        }
      }
      if (selected == null) {
        throw StateError('Could not generate unique tunnel round $round.');
      }
      deck.add(selected);
    }
    return List<AttentionTunnelScenario>.unmodifiable(deck);
  }

  static AttentionTunnelScenario _build({
    required int stage,
    required bool isPractice,
    required int round,
    required int variant,
    required int seed,
  }) {
    final math.Random random = math.Random(seed);
    final int lanes = switch (stage) {
      <= 2 => 3,
      <= 6 => 4,
      <= 10 => 5,
      <= 13 => 6,
      <= 16 => 7,
      <= 19 => 8,
      _ => 9,
    };
    final int count = switch (stage) {
      <= 2 => 5,
      <= 6 => 7,
      <= 10 => 10,
      <= 13 => 12,
      <= 16 => 15,
      <= 18 => 17,
      19 => 19,
      _ => 22,
    };
    final int shutterCount = stage <= 6
        ? 0
        : stage <= 10
        ? 1
        : stage <= 16
        ? 2
        : stage < 20
        ? 3
        : 4;
    final List<int> shutterIndices = <int>[
      for (int index = 0; index < shutterCount; index++)
        ((index + 1) * (count + 1) ~/ (shutterCount + 1)) - 1,
    ];
    final int interval = stage <= 2
        ? 1280
        : stage <= 6
        ? 1050
        : stage <= 10
        ? 850
        : stage <= 13
        ? 700
        : stage <= 16
        ? 600
        : stage <= 19
        ? 500
        : 420;

    final List<int> occupants = List<int>.generate(lanes, (int index) => index);
    final int target = random.nextInt(lanes);
    final List<int> path = <int>[target];
    final List<TunnelMovement> movements = <TunnelMovement>[];
    int currentTargetLane = target;

    for (int moveIndex = 0; moveIndex < count; moveIndex++) {
      final List<TunnelSwap> swaps = <TunnelSwap>[];
      final int swapCount = stage >= 16 && random.nextDouble() < .28 ? 2 : 1;
      for (int swapIndex = 0; swapIndex < swapCount; swapIndex++) {
        final List<TunnelSwap> edges = _ringEdges(lanes)
            .where((TunnelSwap edge) {
              if (swaps.any(
                (TunnelSwap used) =>
                    used.firstLane == edge.firstLane ||
                    used.firstLane == edge.secondLane ||
                    used.secondLane == edge.firstLane ||
                    used.secondLane == edge.secondLane,
              )) {
                return false;
              }
              return true;
            })
            .toList();
        final bool forceTargetCross = swapIndex == 0 && moveIndex % 4 == 3;
        final bool targetCross =
            forceTargetCross || (swapIndex == 0 && random.nextDouble() < .48);
        final List<TunnelSwap> candidates = edges.where((TunnelSwap edge) {
          final bool touchesTarget =
              edge.firstLane == currentTargetLane ||
              edge.secondLane == currentTargetLane;
          return targetCross ? touchesTarget : !touchesTarget;
        }).toList();
        final List<TunnelSwap> fallback = candidates.isEmpty
            ? edges
            : candidates;
        final TunnelSwap selected = fallback[random.nextInt(fallback.length)];
        swaps.add(selected);
        final int held = occupants[selected.firstLane];
        occupants[selected.firstLane] = occupants[selected.secondLane];
        occupants[selected.secondLane] = held;
        currentTargetLane = occupants.indexOf(target);
      }
      movements.add(
        TunnelMovement(
          swaps: List<TunnelSwap>.unmodifiable(swaps),
          occluded: shutterIndices.contains(moveIndex),
        ),
      );
      path.add(currentTargetLane);
    }

    return AttentionTunnelScenario(
      stage: stage,
      laneCount: lanes,
      startTargetLane: target,
      movements: List<TunnelMovement>.unmodifiable(movements),
      targetLanePath: List<int>.unmodifiable(path),
      finalTargetLane: currentTargetLane,
      isPractice: isPractice,
      round: round,
      variant: variant,
      movementIntervalMs: interval,
    );
  }

  static List<TunnelSwap> _ringEdges(int lanes) => <TunnelSwap>[
    for (int lane = 0; lane < lanes; lane++)
      TunnelSwap(lane, (lane + 1) % lanes),
  ];
}
